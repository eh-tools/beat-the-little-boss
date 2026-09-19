# Triage Labels

本项目保留默认五个分流角色名称，并作为 GitHub 仓库标签使用（`gh label list --repo eh-tools/beat-the-little-boss`）。

| 技能中的角色 | 本项目标签 | 含义 |
| --- | --- | --- |
| `needs-triage` | `needs-triage` | 等待维护者评估 |
| `needs-info` | `needs-info` | 等待补充信息 |
| `ready-for-agent` | `ready-for-agent` | 规格充分，可交给代理执行 |
| `ready-for-human` | `ready-for-human` | 需要人工实施 |
| `wontfix` | `wontfix` | 不予实施 |

当技能要求应用某个分流角色时，用 `gh issue edit <编号> --add-label <标签>` 打上对应标签；切换状态时同时用 `--remove-label` 移除旧标签。

今后若要更名，先改仓库标签再改本表映射，避免引入重复标签。
