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

   脚本依次校验：当前在 main、与 origin/main 同步、工作区干净、tag 不存在、说明非空；然后运行 `tools/build.ps1`（跑全部测试 → 导出 → 打包），算出 SHA-256，创建 GitHub Release 并上传 zip。
5. **发布后核对**：release 页面的标题、附件名（`DesktopPet-Windows-x64-<版本>.zip`）与脚本打印的 SHA-256 一致。

## 说明模板

正文只写下面三节；「包含文件」与「SHA-256」由脚本自动附加，不要手写。

```markdown
## 变更

- 面向玩家的每条改动一句，不写实现细节

## 验证

- 跑过的测试与真实运行证据（指向 `docs/qa/<日期>-<主题>.md`）

## 已知限制

- 本次未覆盖的平台/硬件；没有就写「无」
```

## 不要做

- 手工 `Compress-Archive`、手工给产物改名、发布没有说明的 release。
- 在非 main 的提交上发版（脚本会拒绝）。
- 用 `--no-verify` 或 `-c core.hooksPath=...` 绕过 hook（agent guard 与本机 hook 都会拦）。
