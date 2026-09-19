# Release: 版本化 zip 与 GitHub Release

发版这件事只有一个定式：版本号从 `export_presets.cfg` 读，产物名由脚本生成，说明按模板写。任何环节手工代劳都会重新引入「有时平铺、有时压缩包、描述随缘」的问题。

## 单一真相

- 版本号只写在 `export_presets.cfg` 的 `application/file_version` 与 `application/product_version`（形如 `0.1.18.0`）。
- 对外版本号 = 去掉末位构建号的 `0.1.18`；tag 为 `v0.1.18`，release 标题为 `v0.1.18 · 暴打小老板`。
- 唯一发布产物是 `dist/DesktopPet-Windows-x64-<版本>.zip`。不再产出无版本号的通用 zip，也不保留 `dist/DesktopPet-<版本>/` 这类平铺副本；`dist/` 整体不入库。

## 何时发版

一个或多个 PR 合入 main 之后，由用户要求发布时进行。发版必须发生在 main 上，且该提交已推送到 origin/main。

## 步骤

1. **先合版本号**：`git switch -c bump-<版本>` → 改 `export_presets.cfg` 的两个版本字段 → 提交 → 推送 → 开 PR 合并。
2. **回到主工作区取最新 main**：`git switch main && git pull`。
3. **写说明草稿**（模板见下），存到 `.scratch/desktop-pet/release-<版本>.md`。
4. **发布**：

   ```powershell
   pwsh tools/release.ps1 -NotesFile .scratch/desktop-pet/release-0.1.19.md
   ```

   脚本依次校验：当前在 main、与 origin/main 同步、工作区干净、tag 不存在、说明非空且结构合格；然后运行 `tools/build.ps1`（跑全部测试 → 导出 → 打包），算出 SHA-256，创建 GitHub Release 并上传 zip。
5. **发布后核对**：release 页面的标题、附件名（`DesktopPet-Windows-x64-<版本>.zip`）与脚本打印的 SHA-256 一致。

## 说明模板

正文默认三节；只有需要玩家做动作时才加「升级说明」。**「包含文件」与「SHA-256」由脚本自动附加，不要手写。**

```markdown
## 变更

- 每条一个玩家可见的改动，一条一句，不写实现细节；相关修复可带引用（如 #19）。

## 验证

- 一行结论：跑了什么（命令/套件）→ 结果。
- 详细证据放公开的 PR/issue，不指向 `docs/qa` 等未公开路径。

## 已知限制

- 只写本版新增、且影响玩家的限制；没有就写「无」。
- 平台覆盖等长期声明看 README；工程债记进 issue，不写在这里。

## 升级说明（按需添加，需要玩家做动作时才写）

- 覆盖 exe 即可，还是需要先删除什么；`preferences.json` 是否保留。
```

## 说明的检查

结构问题由脚本拦，语义问题逐条判。两者不要互相代劳。

| 规则 | 执行者 |
| --- | --- |
| 三节齐全且非空；不出现 `docs/qa` 等未公开路径；不手写「包含文件」「SHA-256」 | `tools/release.ps1` 发版时自动检查，不通过即中止 |
| 每条变更是否面向玩家；每条限制是否与 README 重复；验证结论是否有公开证据 | 发版人逐条自查；将来可由判断模型（System One）做成发版前软门：低于阈值提醒复核，不中止发布 |
| 终稿措辞与发布决定 | 人 |

语义检查要能落点，前提是条目原子化：一条变更 = 一个玩家可见的命题，一条限制 = 一个影响声明。一条里塞三件事，人审不清，模型也判不了。

## 不要做

- 手工 `Compress-Archive`、手工给产物改名、发布没有说明的 release。
- 在说明里指向 `docs/qa` 等未公开路径，或手写「包含文件」「SHA-256」（脚本会拒绝）。
- 在非 main 的提交上发版（脚本会拒绝）。
- 用 `--no-verify` 或 `-c core.hooksPath=...` 绕过 hook（agent guard 与本机 hook 都会拦）。
