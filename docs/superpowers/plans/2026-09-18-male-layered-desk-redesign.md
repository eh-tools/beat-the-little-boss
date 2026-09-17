# 男领导三层桌面重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 保留原 32 帧男领导形象，并以连贯的上身、桌面手部和前景柜体将他自然置于办公桌后。

**Architecture:** 常规男领导将 `_icon_body` 缩放为 `0.7625` 并裁到原帧上方 154 像素。新增两个桌子 region sprite 与两个从当前帧裁出的手部 sprite；终态恢复原始全尺寸领导和破损桌椅。

**Tech Stack:** Godot 4.5.2、GDScript、现有像素 PNG 素材和 headless View 测试。

**Spec:** `docs/superpowers/specs/2026-09-18-male-layered-desk-redesign.md`

## Global Constraints

- 男领导外观只能来自已有 `assets/art/male_frames/male_00.png` 至 `male_31.png`。
- 女领导、她的喝咖啡动作和武器动画不变。
- 男领导咖啡杯位置为 `(127, 118)`，杯底接触桌沿 `y=137`。
- 求饶终态必须显示完整下跪精灵与散架桌椅。

---

### Task 1: 锁定三层桌面关系

**Files:**
- Modify: `tests/test_view.gd:17-47`

**Interfaces:**
- Consumes: `PetView.capture_pose(id: String, stage: int)`.
- Produces: test assertions for `_male_desk_top`, `_male_desk_front`, `_male_left_hand`, `_male_right_hand`, `_icon_body`, and `_props.cup`.

- [x] **Step 1: Write the failing View checks**

After `pet.capture_pose("male", 0)`, add:

```gdscript
check(pet._icon_body.scale == Vector2(0.7625, 0.7625), "male layered body keeps the approved compact scale")
check(pet._icon_body.region_rect == Rect2(0, 0, 160, 154), "male layered body keeps the approved upper-body crop")
check(pet._male_desk_top.visible and pet._male_desk_front.visible, "male desk uses separate top and cabinet foreground layers")
check(pet._male_left_hand.visible and pet._male_right_hand.visible, "male idle keeps both hands on the desktop")
check(pet._props.cup.position == Vector2(127, 118), "male coffee cup rests at the approved desk position")
```

After `_time = 10.5`, add:

```gdscript
check(not pet._male_right_hand.visible, "male smoking exposes the original raised right hand instead of a duplicate desktop hand")
```

After `pet.capture_pose("male", 4)`, add:

```gdscript
check(not pet._male_desk_top.visible and not pet._male_desk_front.visible, "male terminal pose restores the broken full desk")
check(pet._icon_body.scale == Vector2.ONE, "male terminal pose restores the full-size kneeling frame")
```

- [x] **Step 2: Verify the current implementation fails**

Run:

```powershell
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_view.gd
```

Expected: the fields do not exist or assertions fail because the current view has one cropped leader and one desk sprite.

### Task 2: Implement body, hand, and desk layers

**Files:**
- Modify: `src/pet_view.gd:14-80, 108-115, 188-205, 275-305, 365-390`
- Test: `tests/test_view.gd`

**Interfaces:**
- Consumes: `_male_frames`, `_set_male_frame(index: int)`, `_apply_art(furniture_stage: int)`, and `_pose(_delta: float)`.
- Produces: `_set_male_layers(stage: int, active: bool)` which controls non-terminal male layers and updates hand textures.

- [x] **Step 1: Declare and create layer sprites**

Add the four `Sprite2D` fields. In `_ready()`, create the top before props and the cabinet after hands. Use these fixed positions and regions:

```gdscript
_male_desk_top.region_enabled = true
_male_desk_top.region_rect = Rect2(0, 0, 150, 18)
_male_desk_top.position = Vector2(5, 119)
_male_desk_front.region_enabled = true
_male_desk_front.region_rect = Rect2(0, 18, 150, 50)
_male_desk_front.position = Vector2(5, 136)
_male_left_hand.region_enabled = true
_male_left_hand.region_rect = Rect2(43, 149, 19, 18)
_male_left_hand.position = Vector2(49, 120)
_male_right_hand.region_enabled = true
_male_right_hand.region_rect = Rect2(98, 149, 19, 18)
_male_right_hand.position = Vector2(93, 120)
```

- [x] **Step 2: Add `_set_male_layers` and invoke it after frame selection**

```gdscript
func _set_male_layers(stage: int, active: bool) -> void:
	var layered := character == "male" and stage < 4
	var smoking := layered and not active and _male_frame >= 4 and _male_frame <= 10
	for sprite in [_male_desk_top, _male_desk_front]:
		sprite.visible = layered
		sprite.texture = _tex("desk_" + str(stage))
	_desk.visible = not layered
	for hand in [_male_left_hand, _male_right_hand]:
		hand.texture = _male_frames[_male_frame] if _male_frame >= 0 else null
		hand.visible = layered and not active
	_male_right_hand.visible = layered and not active and not smoking
```

For layered male states, set `_icon_body.region_rect = Rect2(0, 0, 160, 154)`, `_icon_body.scale = Vector2(0.7625, 0.7625)`, and `_icon_body.position = Vector2(-62, -87)`. Restore the existing full scale and position otherwise.

- [x] **Step 3: Set layered prop positions and foreground hit testing**

In `_pose`, when `character == "male" and stage < 4` and no attack is active, override:

```gdscript
_props.monitor.position = Vector2(7, 101)
_props.keyboard.position = Vector2(61, 120)
_props.papers.position = Vector2(112, 119)
_props.cup.position = Vector2(127, 118)
_props.ashtray.position = Vector2(103, 124)
```

Extend the foreground loop in `hit_test` to include `_male_desk_top` and `_male_desk_front` alongside `_desk` and the props.

- [x] **Step 4: Verify implementation**

Run:

```powershell
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_view.gd
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_core.gd
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_desktop.gd
```

Expected: the suites pass; regular male stages use the three layers and terminal frames use the original complete scene.

### Task 3: Build the redesigned delivery

**Files:**
- Modify: `export_presets.cfg:24-25`
- Modify: `.scratch/desktop-pet/issues/11-male-layered-desk-redesign.md`
- Modify: `.scratch/desktop-pet/progress.md`

**Interfaces:**
- Consumes: `tools/build.ps1` and `tests/test_startup_windows.ps1`.
- Produces: `dist/DesktopPet-Windows-x64-0.1.11.zip` with file/product version `0.1.11.0`.

- [x] **Step 1: Build and verify**

Set both Windows version fields to `0.1.11.0`, run `./tools/build.ps1`, copy the archive to `dist/DesktopPet-Windows-x64-0.1.11.zip`, and test a new extraction with `./tests/test_startup_windows.ps1 -Executable <fresh-extraction>/DesktopPet.exe`.

- [x] **Step 2: Record delivery**

Record the three-layer behavior, coffee location, test evidence, archive version, and SHA256 in issue 11 and `progress.md`.
