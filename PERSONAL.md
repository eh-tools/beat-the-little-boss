# PERSONAL.md

个人偏好（使用者维护，不属于构建产物）。Agent 会话通过 `AGENTS.md` 里的指针读取本文件。

## 开发流

- 偏好：新分支 —— 在主工作区 `git switch -c <名字>` 开发，完成后推送分支并开 PR；本仓库不使用 worktree。
- main 已开启 GitHub ruleset 保护（禁删除、禁 force-push、必须走 PR，0 个必需评审可自合），所以 main 只能经 PR 合入，不再直接推送。
- 发版在 PR 合并之后进行：拉取最新 main，再跑 `tools/release.ps1`。流程与 release 说明模板见 `docs/agents/release.md`。
