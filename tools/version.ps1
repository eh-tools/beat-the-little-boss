# 版本号的唯一真相: export_presets.cfg 的 application/product_version (形如 0.1.18.0)。
# 对外版本去掉末位构建号: 0.1.18.0 -> 0.1.18。
function Get-ProjectVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $presetPath = Join-Path $ProjectRoot 'export_presets.cfg'
    $match = Select-String -LiteralPath $presetPath -Pattern '^application/product_version="(\d+\.\d+\.\d+)(?:\.\d+)?"' | Select-Object -First 1
    if (-not $match) { throw 'export_presets.cfg 中缺少 application/product_version，无法确定版本号。' }
    return $match.Matches[0].Groups[1].Value
}
