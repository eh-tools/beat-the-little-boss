# Beat the Little Boss

工作工程中，暴打小老板；有气就出气！这是一个离线运行的 Windows 桌面解压小工具：用夸张的卡通反馈消化工作里的火气，不针对现实中的任何人。

两位虚构领导，一点下班的快乐。像素角色、充气大锤与双拳套，离线运行的 Windows 桌面小玩具。

## 下载

从 [GitHub Releases](https://github.com/eh-tools/beat-the-little-boss/releases) 下载 Windows 便携版，解压后直接运行 `DesktopPet.exe`。

## 运行

解压 `DesktopPet-Windows-x64.zip`，双击 `DesktopPet.exe`。不需要安装 Godot。请将文件夹放在有写入权限的位置，例如桌面或个人文档目录。

- **点击领导**：击打；家具和空白处不会增加伤势。
- **拖动领导或桌椅**：移动桌宠，松手不会击打。
- **右键桌宠**：切换男女领导、武器、缩放、置顶、音效；打开语录设置、全部恢复、隐藏或退出。
- **数字键 1 / 2**：桌宠有键盘焦点时切换大锤 / 双拳套。
- **隐藏到任务栏**：点击任务栏中的桌宠图标恢复。
- **语录工坊**：选择角色与类别，新增、更新或删除条目，最后点击保存。关闭未保存的草稿不影响现有语录。

普通击打增加 1 点，暴击增加 2 点。连续四次没暴击，第五次必暴击；最多暂存两次攻击。两位领导各自拥有 36 点受击进度，到达终态后桌椅散架、下跪求饶，展示 5 秒后当前领导自动恢复。期间继续点击有轻微反馈；右键「全部恢复正常」可立即恢复两位领导。

## 本地数据

便携版将 `preferences.json` 写在可执行文件旁边，正常保存保留上一版 `.bak`。其中只有语录、角色/武器选择、位置、缩放、置顶与音效设置；伤势只保存在本次会话中，重启归零。

损坏配置不会自动覆盖。出现提示后，可在语录工坊选择「恢复默认语录」并保存，原文件会另存为 `.corrupt` 备份。目录无法写入时会明确提示，仍可退出。程序无账号、网络请求、遥测和语音朗读。

语录导入/导出采用 UTF-8 JSON 文本（`.json` 或 `.txt`），保留角色、类别与阶段。每条 1–24 个字符，不含换行；空类别回退到内置台词。示例：

```json
{
  "version": 1,
  "quotes": [
    {"character": "male", "category": "hit", "stage": -1, "text": "今天准点下班！"},
    {"character": "female", "category": "plead", "stage": 4, "text": "再也不改需求了"}
  ]
}
```

角色是 `male` / `female`，类别是 `idle` / `hit` / `plead`，阶段 `-1` 代表通用，`0` 至 `4` 对应正常、轻伤、明显受伤、重伤、求饶终态。

## 开发与验证

使用 **Godot 4.5.2 标准版**，Compatibility 渲染器和 GDScript；Windows 鼠标穿透使用项目自带的微型原生 DLL。打开 `project.godot` 后按 F6/F5 运行时请关闭编辑器的嵌入运行模式，桌宠需要原生透明窗口。源码运行的配置保存在忽略提交的 `local-data/` 中。

`native/windows_mouse_passthrough.dll` 随源码与便携包提供，不需要额外安装运行库。修改原生代码后，使用 Visual Studio 2022 C++ 工具链运行 `./tools/build_native.ps1` 重新生成。它只修改本进程窗口的鼠标穿透标记，不修改其他应用。

从 [Godot 官方下载页](https://godotengine.org/download/archive/4.5.2-stable/) 下载 Windows 标准版和同版本导出模板。将引擎解压到 `.tools/godot/`，将模板包内 `windows_release_x86_64.exe` 和 `windows_debug_x86_64.exe` 放到 `.tools/templates/`。`.tools/` 不提交到 Git，也不进入发布 ZIP。

```powershell
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --editor --import --quit
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_core.gd
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_desktop.gd
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --path . --script tests/test_app.gd -- --config-path=user://app-test.json
./tools/build.ps1
```

构建产物位于 `dist/DesktopPet/DesktopPet.exe` 和 `dist/DesktopPet-Windows-x64-<版本>.zip`；版本号取自 `export_presets.cfg` 的 `application/product_version`，不再产出无版本号的通用 zip。

首次克隆后运行 `pre-commit install` 启用提交检查（密钥扫描、行尾规范化、禁止直接提交 main）。发布流程见 `docs/agents/release.md`。

美术生成源文件位于 `tools/draw_art.py`，仅再生成素材时需要 Python 与 Pillow。

当前实现包含核心、桌面、视图、女性待机和攻击动作测试；Windows 10、所有显卡及多显示器组合需在对应设备上分别验收。不包含安装程序、开机自启和其他操作系统版本。

## 项目资料

- 实施规格：`.scratch/desktop-pet/spec.md`
- 任务与进度：`.scratch/desktop-pet/plan.md`
- 领域术语：`CONTEXT.md`
- 架构决策：`docs/adr/`
- 发布流程与说明模板：`docs/agents/release.md`
- 引擎与第三方许可：`THIRD_PARTY_NOTICES.md`

## 许可

项目代码与随附素材以 [MIT License](LICENSE) 发布。Godot Engine 及其他第三方组件的许可与声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
