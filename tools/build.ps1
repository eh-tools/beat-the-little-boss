param([string]$GodotPath = "$PSScriptRoot/../.tools/godot/Godot_v4.5.2-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/version.ps1"
$projectRoot = (Resolve-Path "$PSScriptRoot/..").Path
$releaseDir = Join-Path $projectRoot 'dist/DesktopPet'
$version = Get-ProjectVersion -ProjectRoot $projectRoot
$zipPath = Join-Path $projectRoot "dist/DesktopPet-Windows-x64-$version.zip"
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Godot 4.5.2 is required. See README.md for setup.' }
if (-not (Test-Path -LiteralPath "$projectRoot/.tools/templates/windows_release_x86_64.exe")) { throw 'Windows export template is missing. See README.md.' }
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
if (-not (Test-Path -LiteralPath "$projectRoot/native/windows_mouse_passthrough.dll")) {
    & "$PSScriptRoot/build_native.ps1"
}
$importLog = & $GodotPath --headless --path $projectRoot --editor --import --quit 2>&1
if ($LASTEXITCODE -ne 0 -or ($importLog -match 'SCRIPT ERROR|ERROR:')) { $importLog; throw 'Godot import failed.' }
$coreLog = & $GodotPath --headless --path $projectRoot --script tests/test_core.gd --quit-after 1200 2>&1
$coreLog
if ($LASTEXITCODE -ne 0 -or ($coreLog -match 'SCRIPT ERROR|ERROR:') -or -not ($coreLog -match 'core tests passed')) { throw 'Core tests failed.' }
$desktopLog = & $GodotPath --headless --path $projectRoot --script tests/test_desktop.gd --quit-after 1200 2>&1
$desktopLog
if ($LASTEXITCODE -ne 0 -or ($desktopLog -match 'SCRIPT ERROR|ERROR:') -or -not ($desktopLog -match 'desktop tests passed')) { throw 'Desktop tests failed.' }
$viewLog = & $GodotPath --headless --path $projectRoot --script tests/test_view.gd --quit-after 1200 2>&1
$viewLog
if ($LASTEXITCODE -ne 0 -or ($viewLog -match 'SCRIPT ERROR|ERROR:') -or -not ($viewLog -match 'view tests passed')) { throw 'View tests failed.' }
$coffeeLog = & $GodotPath --headless --path $projectRoot --script tests/test_female_idle.gd --quit-after 1200 2>&1
$coffeeLog
if ($LASTEXITCODE -ne 0 -or ($coffeeLog -match 'SCRIPT ERROR|ERROR:') -or -not ($coffeeLog -match 'female idle tests passed')) { throw 'Female idle tests failed.' }
$motionLog = & $GodotPath --headless --path $projectRoot --script tests/test_attack_motion.gd --quit-after 1200 2>&1
$motionLog
if ($LASTEXITCODE -ne 0 -or ($motionLog -match 'SCRIPT ERROR|ERROR:') -or -not ($motionLog -match 'attack motion tests passed')) { throw 'Attack motion tests failed.' }
$exportLog = & $GodotPath --headless --path $projectRoot --export-release 'Windows Desktop' "$releaseDir/DesktopPet.exe" 2>&1
if ($LASTEXITCODE -ne 0 -or ($exportLog -match 'SCRIPT ERROR|ERROR:')) { $exportLog; throw 'Windows export failed.' }
Copy-Item -LiteralPath "$projectRoot/README.md" -Destination "$releaseDir/README.md"
Copy-Item -LiteralPath "$projectRoot/LICENSE" -Destination "$releaseDir/LICENSE"
Copy-Item -LiteralPath "$projectRoot/THIRD_PARTY_NOTICES.md" -Destination "$releaseDir/THIRD_PARTY_NOTICES.md"
$nativeLibrary = "$releaseDir/windows_mouse_passthrough.dll"
if (-not (Test-Path -LiteralPath $nativeLibrary)) { throw 'Export did not include the native mouse passthrough library.' }
& "$projectRoot/tests/test_startup_windows.ps1" -Executable "$releaseDir/DesktopPet.exe"
if ($LASTEXITCODE -ne 0) { throw 'Startup window test failed.' }
$filesToPackage = @("$releaseDir/DesktopPet.exe", $nativeLibrary, "$releaseDir/README.md", "$releaseDir/LICENSE", "$releaseDir/THIRD_PARTY_NOTICES.md")
# Explicit file list keeps local preferences and tests out of the portable archive.
Compress-Archive -LiteralPath $filesToPackage -DestinationPath $zipPath -Force
# 只保留带版本号的 zip: 清掉旧的无版本副本, 避免"通用 zip 是哪个版本"的混淆。
$legacyZip = Join-Path $projectRoot 'dist/DesktopPet-Windows-x64.zip'
if (Test-Path -LiteralPath $legacyZip) { Remove-Item -LiteralPath $legacyZip; Write-Output "Removed legacy archive: $legacyZip" }
Write-Output "Version: $version"
Write-Output "Portable archive: $zipPath"
Write-Output "SHA-256: $((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash)"
