param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [int]$DurationMilliseconds = 6000,
    [string]$ArtifactDirectory = ''
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Desktop') {
    $arguments = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath,
        '-Executable', $Executable,
        '-DurationMilliseconds', $DurationMilliseconds
    )
    if ($ArtifactDirectory) { $arguments += @('-ArtifactDirectory', $ArtifactDirectory) }
    & powershell.exe @arguments
    exit $LASTEXITCODE
}

$executablePath = (Resolve-Path -LiteralPath $Executable).Path

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
$referenceAssemblies = [AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { -not [string]::IsNullOrEmpty($_.Location) } |
    Select-Object -ExpandProperty Location -Unique
Add-Type @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;

public sealed class StartupWindowMetric
{
    public IntPtr Handle;
    public int Left;
    public int Top;
    public int Width;
    public int Height;
    public string ClassName;
    public string Title;
    public double ContentRatio;
    public double ScreenDiffRatio;
}

public static class StartupWindowProbe
{
    private delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lparam);

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lparam);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hwnd);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetClassName(IntPtr hwnd, StringBuilder value, int length);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr hwnd, StringBuilder value, int length);

    [DllImport("user32.dll")]
    private static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);

    private static Bitmap baseline;
    private static int virtualLeft;
    private static int virtualTop;

    public static void CaptureBaseline()
    {
        Rectangle bounds = System.Windows.Forms.SystemInformation.VirtualScreen;
        virtualLeft = bounds.Left;
        virtualTop = bounds.Top;
        baseline = CaptureScreen(bounds);
    }

    public static StartupWindowMetric[] Sample(uint targetProcessId)
    {
        List<StartupWindowMetric> metrics = new List<StartupWindowMetric>();
        EnumWindows(delegate(IntPtr hwnd, IntPtr unused) {
            uint processId;
            GetWindowThreadProcessId(hwnd, out processId);
            if (processId != targetProcessId || !IsWindowVisible(hwnd))
                return true;

            RECT rect;
            if (!GetWindowRect(hwnd, out rect))
                return true;
            int width = rect.Right - rect.Left;
            int height = rect.Bottom - rect.Top;
            if (width <= 1 || height <= 1)
                return true;

            StringBuilder className = new StringBuilder(256);
            StringBuilder title = new StringBuilder(512);
            GetClassName(hwnd, className, className.Capacity);
            GetWindowText(hwnd, title, title.Capacity);

            Bitmap content = CaptureWindow(hwnd, width, height);
            Bitmap screen = CaptureScreen(new Rectangle(rect.Left, rect.Top, width, height));
            StartupWindowMetric metric = new StartupWindowMetric();
            metric.Handle = hwnd;
            metric.Left = rect.Left;
            metric.Top = rect.Top;
            metric.Width = width;
            metric.Height = height;
            metric.ClassName = className.ToString();
            metric.Title = title.ToString();
            metric.ContentRatio = NonBlackRatio(content);
            metric.ScreenDiffRatio = DifferenceRatio(screen, baseline, rect.Left - virtualLeft, rect.Top - virtualTop);
            content.Dispose();
            screen.Dispose();
            metrics.Add(metric);
            return true;
        }, IntPtr.Zero);
        return metrics.ToArray();
    }

    public static void SaveWindow(IntPtr hwnd, int width, int height, string path)
    {
        using (Bitmap image = CaptureWindow(hwnd, width, height))
            image.Save(path, ImageFormat.Png);
    }

    public static void SaveScreen(int left, int top, int width, int height, string path)
    {
        using (Bitmap image = CaptureScreen(new Rectangle(left, top, width, height)))
            image.Save(path, ImageFormat.Png);
    }

    private static Bitmap CaptureWindow(IntPtr hwnd, int width, int height)
    {
        Bitmap image = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (Graphics graphics = Graphics.FromImage(image)) {
            graphics.Clear(Color.Transparent);
            IntPtr hdc = graphics.GetHdc();
            PrintWindow(hwnd, hdc, 2);
            graphics.ReleaseHdc(hdc);
        }
        return image;
    }

    private static Bitmap CaptureScreen(Rectangle bounds)
    {
        Bitmap image = new Bitmap(bounds.Width, bounds.Height, PixelFormat.Format32bppArgb);
        using (Graphics graphics = Graphics.FromImage(image))
            graphics.CopyFromScreen(bounds.Left, bounds.Top, 0, 0, bounds.Size, CopyPixelOperation.SourceCopy);
        return image;
    }

    private static double NonBlackRatio(Bitmap image)
    {
        int changed = 0;
        int total = image.Width * image.Height;
        for (int y = 0; y < image.Height; y++) {
            for (int x = 0; x < image.Width; x++) {
                Color pixel = image.GetPixel(x, y);
                if (pixel.R > 12 || pixel.G > 12 || pixel.B > 12)
                    changed++;
            }
        }
        return total == 0 ? 0.0 : (double)changed / total;
    }

    private static double DifferenceRatio(Bitmap current, Bitmap reference, int referenceX, int referenceY)
    {
        if (reference == null || referenceX < 0 || referenceY < 0 ||
            referenceX + current.Width > reference.Width || referenceY + current.Height > reference.Height)
            return 0.0;

        Rectangle currentBounds = new Rectangle(0, 0, current.Width, current.Height);
        Rectangle referenceBounds = new Rectangle(referenceX, referenceY, current.Width, current.Height);
        BitmapData currentData = current.LockBits(currentBounds, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        BitmapData referenceData = reference.LockBits(referenceBounds, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int currentStride = Math.Abs(currentData.Stride);
        int referenceStride = Math.Abs(referenceData.Stride);
        byte[] currentPixels = new byte[currentStride * current.Height];
        byte[] referencePixels = new byte[referenceStride * current.Height];
        Marshal.Copy(currentData.Scan0, currentPixels, 0, currentPixels.Length);
        Marshal.Copy(referenceData.Scan0, referencePixels, 0, referencePixels.Length);
        current.UnlockBits(currentData);
        reference.UnlockBits(referenceData);

        int changed = 0;
        int total = current.Width * current.Height;
        for (int y = 0; y < current.Height; y++) {
            for (int x = 0; x < current.Width; x++) {
                int left = y * currentStride + x * 4;
                int right = y * referenceStride + x * 4;
                if (Math.Abs(currentPixels[left] - referencePixels[right]) > 12 ||
                    Math.Abs(currentPixels[left + 1] - referencePixels[right + 1]) > 12 ||
                    Math.Abs(currentPixels[left + 2] - referencePixels[right + 2]) > 12)
                    changed++;
            }
        }
        return total == 0 ? 0.0 : (double)changed / total;
    }
}
'@ -ReferencedAssemblies $referenceAssemblies

if ($ArtifactDirectory) {
    New-Item -ItemType Directory -Force -Path $ArtifactDirectory | Out-Null
    $artifactPath = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
} else {
    $artifactPath = $null
}

[StartupWindowProbe]::CaptureBaseline()
$isolatedConfig = [IO.Path]::Combine([IO.Path]::GetTempPath(), 'desktop-pet-startup-{0}.json' -f [Guid]::NewGuid().ToString('N'))
$process = Start-Process -FilePath $executablePath -WorkingDirectory (Split-Path -Parent $executablePath) -ArgumentList '--', "--config-path=$isolatedConfig" -PassThru
$watch = [System.Diagnostics.Stopwatch]::StartNew()
$samples = [System.Collections.Generic.List[object]]::new()
$savedRects = @{}
$settledDeadline = [long]::MaxValue

try {
    while ($watch.ElapsedMilliseconds -lt $DurationMilliseconds -and -not $process.HasExited) {
        foreach ($metric in [StartupWindowProbe]::Sample([uint32]$process.Id)) {
            if ($metric.ClassName -ne 'Engine') { continue }
            if ($metric.Width -le 4 -or $metric.Height -le 4) { continue }
            $sample = [pscustomobject]@{
                Milliseconds = $watch.ElapsedMilliseconds
                Handle = $metric.Handle
                Rect = '{0},{1} {2}x{3}' -f $metric.Left, $metric.Top, $metric.Width, $metric.Height
                Width = $metric.Width
                Height = $metric.Height
                Area = $metric.Width * $metric.Height
                ContentRatio = $metric.ContentRatio
                ScreenDiffRatio = $metric.ScreenDiffRatio
            }
            $samples.Add($sample)
            if ($metric.Width -ge 160 -and $metric.Height -ge 160 -and $settledDeadline -eq [long]::MaxValue) {
                $settledDeadline = $watch.ElapsedMilliseconds + 1200
            }
            if ($artifactPath -and -not $savedRects.ContainsKey($sample.Rect)) {
                $savedRects[$sample.Rect] = $true
                $name = 'startup-{0:D4}-{1:X}.png' -f $watch.ElapsedMilliseconds, $metric.Handle.ToInt64()
                [StartupWindowProbe]::SaveWindow($metric.Handle, $metric.Width, $metric.Height, (Join-Path $artifactPath $name))
                $screenName = 'screen-{0:D4}-{1:X}.png' -f $watch.ElapsedMilliseconds, $metric.Handle.ToInt64()
                [StartupWindowProbe]::SaveScreen($metric.Left, $metric.Top, $metric.Width, $metric.Height, (Join-Path $artifactPath $screenName))
            }
        }
        if ($watch.ElapsedMilliseconds -ge $settledDeadline) { break }
        Start-Sleep -Milliseconds 10
    }
} finally {
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id
        $process.WaitForExit()
    }
}

if ($samples.Count -eq 0) { throw 'No visible Godot window was observed during startup.' }

$summary = $samples |
    Group-Object Rect |
    ForEach-Object {
        [pscustomobject]@{
            Rect = $_.Name
            FirstMs = ($_.Group | Measure-Object Milliseconds -Minimum).Minimum
            LastMs = ($_.Group | Measure-Object Milliseconds -Maximum).Maximum
            MaxContent = ($_.Group | Measure-Object ContentRatio -Maximum).Maximum
            MaxScreenDiff = ($_.Group | Measure-Object ScreenDiffRatio -Maximum).Maximum
        }
    }
$summary | Format-Table -AutoSize

$maxArea = ($samples | Measure-Object Area -Maximum).Maximum
$mainSamples = @($samples | Where-Object Area -eq $maxArea)
$finalRect = ($mainSamples | Select-Object -Last 1).Rect
$transientMain = @($mainSamples | Where-Object Rect -ne $finalRect)
$auxiliaryWindows = @($samples | Where-Object {
    $_.Area -lt $maxArea -and $_.ContentRatio -gt 0.05
})
$badMainFrames = @($mainSamples | Where-Object {
    $_.ContentRatio -gt 0.60 -or ($_.ContentRatio -lt 0.05 -and $_.ScreenDiffRatio -gt 0.65)
})

if ($transientMain.Count -gt 0 -or $auxiliaryWindows.Count -gt 0 -or $badMainFrames.Count -gt 0) {
    @($transientMain + $auxiliaryWindows + $badMainFrames) |
        Sort-Object Milliseconds -Unique |
        Select-Object -First 12 |
        Format-Table -AutoSize
    throw 'Startup displayed a Godot splash or an opaque empty rectangle before the desktop pet was ready.'
}

Write-Output 'startup window test passed'
