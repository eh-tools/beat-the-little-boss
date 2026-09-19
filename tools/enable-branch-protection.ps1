# 为 main 建 GitHub ruleset：禁删除、禁 force-push、必须走 PR（单人项目 0 个必需评审，自己可合）。
# 幂等：同名 ruleset 已存在时直接跳过。
# 用法: pwsh tools/enable-branch-protection.ps1 [-Repo <owner>/<name>]
param([string]$Repo)

$ErrorActionPreference = 'Stop'
if (-not $Repo) { $Repo = (& gh repo view --json nameWithOwner --jq .nameWithOwner).Trim() }
if ($LASTEXITCODE -ne 0 -or -not $Repo) { throw '无法确定仓库，请显式传入 -Repo <owner>/<name>' }

$existing = & gh api "repos/$Repo/rulesets" --jq '.[].name'
if ($LASTEXITCODE -ne 0) { throw "读取 rulesets 失败：$Repo" }
if ($existing -contains 'protect-main') {
    Write-Output "ruleset protect-main 已存在，跳过"
    exit 0
}

$ruleset = @'
{
  "name": "protect-main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
'@

$ruleset | & gh api --method POST "repos/$Repo/rulesets" --input - | Out-Null
if ($LASTEXITCODE -ne 0) { throw '创建 ruleset 失败' }
Write-Output "已为 $Repo 的 main 开启保护：禁止删除、禁止 force-push、必须走 PR"
