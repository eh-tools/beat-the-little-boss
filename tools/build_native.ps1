$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path "$PSScriptRoot/..").Path
$vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio 2022 C++ build tools are required.' }
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $installation) { throw 'Install the Visual Studio Desktop development with C++ workload.' }
$buildDir = Join-Path $projectRoot '.tools/native'
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
# A batch file keeps vcvars64 environment changes and cl.exe in the same process.
$batch = @"
@echo off
call "$installation\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 exit /b 1
cl /nologo /std:c++17 /O2 /MT /EHsc /W4 /LD "$projectRoot\native\windows_mouse_passthrough.cpp" /Fo"$buildDir\windows_mouse_passthrough.obj" /link /OUT:"$projectRoot\native\windows_mouse_passthrough.dll" /IMPLIB:"$buildDir\windows_mouse_passthrough.lib" user32.lib
"@
$batchPath = Join-Path $buildDir 'build.cmd'
Set-Content -LiteralPath $batchPath -Value $batch -Encoding ascii
& $env:ComSpec /d /c $batchPath
if ($LASTEXITCODE -ne 0) { throw 'Native mouse passthrough build failed.' }
