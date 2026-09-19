# Issue tracker: GitHub Issues

本项目的任务、规格与讨论统一走 GitHub Issues，仓库为 `eh-tools/beat-the-little-boss`。不再使用本地 Markdown 任务文件；本地 `.scratch/` 仅存放调试产物与实施报告，不承载任务与规格。

## Conventions

- 每条任务一个 issue：`gh issue create --repo eh-tools/beat-the-little-boss`。
- 分流状态用标签记录，不写正文；标签定义见 `triage-labels.md`。
- 评论与讨论追加为 issue 评论（`gh issue comment`），不另建 issue 承载讨论。
- 完成的任务关闭 issue（`gh issue close`）；正文保留原始规格与验收标准，不因完成而改写。
- 创建前先查重（`gh issue list --state all --search "<关键词>"`）；已有 issue 用 `gh issue edit` 更新，保留原有评论与用户修改。
- 规格等长文档放仓库 `docs/<feature>/`（当前桌宠为 `docs/desktop-pet/`），issue 正文放摘要并链接过去，避免把长文塞进正文。

## When a skill says "publish to the issue tracker"

```bash
gh issue create --repo eh-tools/beat-the-little-boss --title "<标题>" --body-file <正文文件> --label <分流标签>
```

`to-spec` 发布规格时使用 `ready-for-agent`；其他任务按其实际分流状态设置。正文超过约 100 行时，先把规格提交为 `docs/<feature>/spec.md`，issue 正文只留摘要与链接。

## When a skill says "fetch the relevant ticket"

```bash
gh issue view <编号> --repo eh-tools/beat-the-little-boss --comments
```

用户只给编号时直接读取；编号在多个仓库重复且无法从上下文确定时，先确认仓库。

## Wayfinding operations

供 `/wayfinder` 使用；此流程的领取状态与分流标签分别按各自约定处理。

- Map：一个 tracking issue，正文记录 Notes、Decisions-so-far 和 Fog。
- Child ticket：普通 issue，在正文首行标注 `Type: research`、`prototype`、`grilling` 或 `task`。
- Blocking：在正文顶部写 `Blocked by #NN, #NN` 记录依赖；全部依赖关闭后才可领取。
- Frontier：`gh issue list --state open --json number,title,body`，从未被指派、未被 `Blocked by` 阻塞的 issue 中按编号从小到大选择。
- Claim：`gh issue edit <编号> --add-assignee @me`。
- Resolve：在 issue 下评论结果，然后关闭，并把摘要与链接补进 Map 的 Decisions-so-far。
