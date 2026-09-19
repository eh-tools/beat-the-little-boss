param(
    [Parameter(Mandatory = $true)][string]$NotesFile,
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/version.ps1"

$projectRoot = (Resolve-Path "$PSScriptRoot/..").Path
$version = Get-ProjectVersion -ProjectRoot $projectRoot
$tag = "v$version"
$title = "v$version · 暴打小老板"
$zipPath = Join-Path $projectRoot "dist/DesktopPet-Windows-x64-$version.zip"

# 1. 只在 main 上发版，且提交已经推到远端
$branch = (& git -C $projectRoot symbolic-ref --quiet --short HEAD).Trim()
if ($branch -ne 'main') { throw "发版必须在 main 上进行，当前分支：$branch。先合并 PR 再发布。" }

$dirty = & git -C $projectRoot status --porcelain
if ($dirty) { throw "工作区有未提交改动，先提交或清理：`n$($dirty -join "`n")" }

& git -C $projectRoot fetch origin main
$head = (& git -C $projectRoot rev-parse HEAD).Trim()
$originHead = (& git -C $projectRoot rev-parse origin/main).Trim()
if ($head -ne $originHead) { throw '本地 main 与 origin/main 不一致，先 git pull 再发版。' }

# 2. 同一个版本不允许发布两次
$existingTag = & git -C $projectRoot ls-remote --tags origin "refs/tags/$tag"
if ($existingTag) { throw "$tag 已存在，先提升 export_presets.cfg 里的版本号。" }

# 3. 说明文件必须存在且非空（模板见 docs/agents/release.md）
if (-not (Test-Path -LiteralPath $NotesFile)) { throw "找不到发布说明：$NotesFile（模板见 docs/agents/release.md）" }
$notes = (Get-Content -LiteralPath $NotesFile -Raw).Trim()
if (-not $notes) { throw "发布说明为空：$NotesFile" }

# 4. 构建（跑全部测试 → 导出 → 打包）
if (-not $SkipBuild) { & "$PSScriptRoot/build.ps1" }
if (-not (Test-Path -LiteralPath $zipPath)) { throw "缺少发布产物：$zipPath" }

# 5. 组装说明：正文来自 notes，固定块由脚本附加，避免每次写法漂移
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
$bodyFile = Join-Path $env:TEMP "release-$tag.md"
$body = @"
$notes

---

**包含文件**：``DesktopPet.exe``、``windows_mouse_passthrough.dll``、``README.md``、``LICENSE``、``THIRD_PARTY_NOTICES.md``

**SHA-256**：``$hash``
"@
[System.IO.File]::WriteAllText($bodyFile, $body, [System.Text.UTF8Encoding]::new($false))

# 6. 发布：由 gh 在远端创建 tag（--target main），失败时不会留下半截 tag
& gh release create $tag --target main --title $title --notes-file $bodyFile $zipPath
if ($LASTEXITCODE -ne 0) { throw "gh release create 失败；说明文件保留在 $bodyFile" }
& git -C $projectRoot fetch origin --tags | Out-Null

Write-Output "已发布 $tag（$title）"
Write-Output "产物: $zipPath"
Write-Output "SHA-256: $hash"
