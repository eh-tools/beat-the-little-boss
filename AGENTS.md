# Project instructions

## 仓库约定

- 开发流偏好（新分支，不使用 worktree）见 `PERSONAL.md`。
- 发布流程与 release 说明模板见 `docs/agents/release.md`；产物统一由 `tools/release.ps1` 生成。

## Agent skills

### Issue tracker

本项目使用 GitHub Issues 管理任务与规格，仓库为 `eh-tools/beat-the-little-boss`。具体规则见 `docs/agents/issue-tracker.md`。本地 `.scratch/` 只放调试产物与实施报告。

### Triage labels

使用默认五个分流标签，作为 GitHub 仓库标签记录。角色映射见 `docs/agents/triage-labels.md`。

### Domain docs

本项目采用 single-context 布局：根目录 `CONTEXT.md` 与 `docs/adr/`。读取与使用规则见 `docs/agents/domain.md`。
