# 男领导桌沿裁切 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让男领导在非求饶阶段保持在办公桌后方，桌下不再露出精灵身体。

**Architecture:** 保持 `PetView` 的 hip 骨骼、32 帧纹理和桌子前景顺序。仅在男领导的非终态为 `_icon_body` 启用 160×108 的 `Sprite2D.region`，并在求饶终态关闭该 region 以完整显示下跪帧。

**Tech Stack:** Godot 4.5.2、GDScript、现有 headless View 回归套件。

**Spec:** `docs/superpowers/specs/2026-09-18-male-desk-edge-clip-design.md`

## Global Constraints

- 不添加依赖、不重绘已确认的 32 帧素材。
- 仅修改男领导精灵的可见边界；女领导、桌子、椅子、武器和鼠标穿透不改变。
- 求饶终态必须完整显示，不应用桌沿裁切。
- 版本号随可交付 Windows 包递增。

---

### Task 1: 将男领导精灵限制到桌沿后方

**Files:**
- Modify: `tests/test_view.gd:17-47`
- Modify: `src/pet_view.gd:61-68, 177-201`
- Modify: `export_presets.cfg:24-25`
- Modify: `.scratch/desktop-pet/issues/10-icon-derived-male-sprite.md`
- Modify: `.scratch/desktop-pet/progress.md`

**Interfaces:**
- Consumes: `PetView.capture_pose(id: String, stage: int)` and `_icon_body: Sprite2D`.
- Produces: `_icon_body.region_enabled` is true for male stages 0–3, uses `Rect2(0, 0, 160, 108)`, and is false for stage 4.

- [x] **Step 1: Write the failing view regressions**

Add these checks after the initial male capture in `tests/test_view.gd`:

```gdscript
check(pet._icon_body.region_enabled, "male regular pose is clipped at the desk edge")
check(pet._icon_body.region_rect == Rect2(0, 0, 160, 108), "male desk clip ends at the desk edge")
check(not pet._pixel_hit(pet._icon_body, Vector2(82, 144)), "male body cannot appear below the desk")
```

After `pet.capture_pose("male", 4)`, add:

```gdscript
check(not pet._icon_body.region_enabled, "male terminal pose keeps the full kneeling sprite")
```

- [x] **Step 2: Run the view suite and verify the new checks fail**

Run:

```powershell
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_view.gd
```

Expected: the new regular-stage region checks fail because `_icon_body` currently draws the full 160×180 texture.

- [x] **Step 3: Apply the smallest rendering change**

In `_ready()`, set the immutable region dimensions after `_icon_body` is created:

```gdscript
_icon_body.region_rect = Rect2(0, 0, 160, 108)
```

In `_apply_art()`, enable it only for non-terminal male stages:

```gdscript
_icon_body.region_enabled = character == "male" and stage < 4
```

This relies on the existing child order: the desk is created after the leader rig and remains the complete foreground layer.

- [x] **Step 4: Run regressions and inspect renderer output**

Run:

```powershell
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_view.gd
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/capture_art.gd
```

Expected: view tests pass; `art-gallery.png` shows male normal-to-heavy-injury stages with no body beneath the desk, while the terminal frame still shows the full kneeling body.

- [x] **Step 5: Build the portable 0.1.10 release**

Set both Windows version fields to `0.1.10.0`, then run `./tools/build.ps1`. Copy the generated archive to `dist/DesktopPet-Windows-x64-0.1.10.zip`, verify it contains exactly `DesktopPet.exe`, `windows_mouse_passthrough.dll`, `README.md`, and `THIRD_PARTY_NOTICES.md`, and run `tests/test_startup_windows.ps1` from a fresh extraction.

- [x] **Step 6: Record and commit**

Append the cause, desk-edge region behavior, passing checks, archive version, and SHA256 to task 10 and `progress.md`, then run:

```powershell
git add tests/test_view.gd src/pet_view.gd export_presets.cfg .scratch/desktop-pet/issues/10-icon-derived-male-sprite.md .scratch/desktop-pet/progress.md
git commit -m "Clip male leader behind desk"
```
