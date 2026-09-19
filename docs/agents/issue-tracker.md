# Issue tracker: Local Markdown

本项目的任务与已发布规格使用本地 Markdown，存放在 `.scratch/` 下。不通过 GitHub、GitLab 或其他外部服务发布任务。

## Conventions

- 每个功能一个目录：`.scratch/<feature-slug>/`；当前桌宠功能使用 `desktop-pet`。
- 功能规格：`.scratch/<feature-slug>/spec.md`。
- 实施任务：`.scratch/<feature-slug>/issues/<NN>-<slug>.md`，从 `01` 开始编号，每个任务一个文件，不合并为单个任务列表。
- 在规格或任务文件顶部附近使用 `Status:` 行记录分流状态，标签定义见 `triage-labels.md`。
- 评论与讨论追加到文件底部的 `## Comments` 标题下。
- 发布前读取已有文件；若对应规格或任务已存在，则更新原文件，保留已有评论和用户修改，避免重复创建。

## When a skill says "publish to the issue tracker"

在上述目录创建或更新对应 Markdown 文件。`to-spec` 发布规格时使用 `Status: ready-for-agent`；其他任务按其实际分流状态设置。

当前讨论中的规格草稿位于 `docs/specs/2026-09-12-desktop-pet-spec.md`；本次配置不会自动将其标记为已发布。完成规格流程后，将内容发布到 `.scratch/desktop-pet/spec.md`，并明确草稿与已发布版本的关系，避免维护两份相互冲突的正文。

## When a skill says "fetch the relevant ticket"

读取用户给出的文件路径。若只有编号，先在相应功能目录查找；编号在多个功能中重复且无法从上下文确定时，再确认所属功能。

## Wayfinding operations

供 `/wayfinder` 使用；此流程的领取状态与普通分流状态分别按各自约定处理。

- Map：`.scratch/<effort>/map.md`，记录 Notes、Decisions-so-far 和 Fog。
- Child ticket：`.scratch/<effort>/issues/NN-<slug>.md`，每个问题一个文件；`Type:` 为 `research`、`prototype`、`grilling` 或 `task`。
- Blocking：顶部附近的 `Blocked by: NN, NN` 记录依赖；全部依赖为 `resolved` 后才可领取。
- Frontier：扫描未解决、未领取且依赖已解除的任务，按编号从小到大选择。
- Claim：开始工作前写入 `Status: claimed` 并保存。
- Resolve：在 `## Answer` 下追加结果，设置 `Status: resolved`，然后向 Map 的 Decisions-so-far 添加摘要和链接。
- `claimed`、`resolved` 仅为 wayfinder 的工作状态，不替代五个分流角色的映射。
