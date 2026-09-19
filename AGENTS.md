# Project instructions

## 仓库约定

- 开发流偏好（新分支，不使用 worktree）见 `PERSONAL.md`。
- 发布流程与 release 说明模板见 `docs/agents/release.md`；产物统一由 `tools/release.ps1` 生成。

## Agent skills

### Issue tracker

本项目使用本地 Markdown 管理规格与任务，存放于 `.scratch/<feature-slug>/`。具体规则见 `docs/agents/issue-tracker.md`。

### Triage labels

使用默认五个分流标签，并通过任务文件的 `Status:` 行记录。角色映射见 `docs/agents/triage-labels.md`。

### Domain docs

本项目采用 single-context 布局：根目录 `CONTEXT.md` 与 `docs/adr/`。读取与使用规则见 `docs/agents/domain.md`。
