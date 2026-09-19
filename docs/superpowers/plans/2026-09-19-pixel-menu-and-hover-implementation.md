# Pixel Menu and Hover Interaction Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a consistent Chinese pixel-font UI across menus and desktop dialogs, simplify the menu hierarchy, remove nested settings scrollbars, add middle-click recovery, and animate the hover weapon cursor.

**Architecture:** Add one shared UI theme script that owns the bundled `FontFile` and palette values. Keep root menu/input behavior in `src/main.gd`, quote-editor layout and row selection in `src/settings_window.gd`, session reset semantics in `src/pet_session.gd`, and cursor-frame generation in `src/pet_view.gd`. Use the existing integration seams and add focused tests before each behavior change.

**Tech Stack:** Godot 4.5.2, GDScript, bundled TrueType font, Windows desktop display server, existing native passthrough extension.

**Spec:** `docs/superpowers/specs/2026-09-19-pixel-menu-and-hover-design.md`

> **Superseded metrics (2026-09-19):** the hover-cursor constraints and Task 5 below
> (56×56 canvas, (28, 28) hotspot, three frames at 120ms) were replaced by the user-approved
> `docs/superpowers/specs/2026-09-19-settings-theme-and-hover-actions-design.md`
> (72×72 canvas, (36, 36) hotspot, five frames at 100ms), which also rebuilt the settings
> window to its v3 composition. Read this plan as the record of round one only.

## Global Constraints

- Bundle `assets/fonts/fusion-pixel-12px-proportional.ttf`, extracted from Fusion Pixel release `2026.09.01`, commit `51c6d2d`.
- Load the bundled font for root menu, scale submenu, settings window, speech bubble, and notice dialog; do not depend on Windows-installed fonts.
- Root menu order is exactly `角色`, `工具`, `显示`, `桌宠`; the scale submenu has exactly `原始大小 · 1 倍`, `放大 · 1.5 倍`, `放大 · 2 倍`.
- Settings has exactly one outer `ScrollContainer` and no nested vertical scrollbar.
- Middle-click resets the selected leader only when it hits a visible pixel and is not competing with a menu, settings window, or drag.
- Hover cursor frames are 56×56 with a 28,28 hotspot and use the 0→1→2→1 sequence at 120ms intervals.
- Do not add a runtime dependency; include font license and attribution in `THIRD_PARTY_NOTICES.md`.

## File Map

- Create: `assets/fonts/fusion-pixel-12px-proportional.ttf` — bundled Simplified Chinese Fusion Pixel font.
- Create: `assets/fonts/LICENSE-OFL` — font license text.
- Create: `src/pet_theme.gd` — shared font resource and palette helpers.
- Modify: `src/main.gd` — shared font usage, compact menu tree, current/all recovery actions, middle-click input, animated cursor updates, and notice styling.
- Modify: `src/settings_window.gd` — shared font/theme usage and one-scroll selectable quote rows.
- Modify: `src/pet_session.gd` — reset one character and cancel its active/queued attacks.
- Modify: `src/pet_view.gd` — generate/cache 56×56 pixel-safe hover cursor frames.
- Modify: `tests/test_core.gd` — selected-character reset behavior.
- Modify: `tests/test_app.gd` — menu tree, font, scroll, middle-click, and cursor-frame integration checks.
- Modify: `THIRD_PARTY_NOTICES.md` — Fusion Pixel attribution and OFL-1.1 notice.

### Task 1: Add the bundled font and shared theme

**Files:**
- Create: `assets/fonts/fusion-pixel-12px-proportional.ttf`
- Create: `assets/fonts/LICENSE-OFL`
- Create: `src/pet_theme.gd`
- Modify: `THIRD_PARTY_NOTICES.md`
- Test: `tests/test_app.gd`

**Interfaces:**
- Produces `PetTheme.font() -> FontFile` and color constants for all UI surfaces.
- The font resource path is stable and is included by the existing `export_filter="all_resources"` preset.

- [ ] **Step 1: Add the font asset and license.**

  Download `fusion-pixel-font-12px-proportional-ttf-v2026.09.01.zip` from the pinned release, copy its `fusion-pixel-12px-proportional-zh_hans.ttf` to `assets/fonts/fusion-pixel-12px-proportional.ttf`, and copy the upstream OFL text to `assets/fonts/LICENSE-OFL`.

- [ ] **Step 2: Add a failing bundled-font test.**

  Add to `tests/test_app.gd`:

  ```gdscript
  check(ResourceLoader.exists("res://assets/fonts/fusion-pixel-12px-proportional.ttf"), "bundled pixel font exists")
  check(app.menu.get_theme_font("font") == PetTheme.font(), "root menu uses the bundled pixel font")
  ```

  Run `Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_app.gd --quit-after 1200 -- --config-path=user://app-test.json`. The new resource assertion must fail before the asset/helper is added; existing headless native-window failures are recorded separately.

- [ ] **Step 3: Implement `src/pet_theme.gd`.**

  Use a preloaded `FontFile` and expose the fixed palette:

  ```gdscript
  class_name PetTheme
  extends RefCounted

  const FONT: FontFile = preload("res://assets/fonts/fusion-pixel-12px-proportional.ttf")
  const INK := Color("303247")
  const CREAM := Color("fff4d9")
  const GOLD := Color("ffe1a6")
  const CORAL := Color("e79777")
  const TEAL := Color("95e0d0")

  static func font() -> FontFile:
      return FONT
  ```

- [ ] **Step 4: Update attribution and verify the resource.**

  Replace the obsolete “Windows-installed fonts” sentence in `THIRD_PARTY_NOTICES.md` with the pinned Fusion Pixel attribution and OFL-1.1 source. Run the same test command and expect the bundled-font checks to pass.

- [ ] **Step 5: Commit.**

  ```powershell
  git add assets/fonts src/pet_theme.gd THIRD_PARTY_NOTICES.md tests/test_app.gd
  git commit -m "Add bundled pixel UI font"
  ```

### Task 2: Apply the pixel font and compact root menu

**Files:**
- Modify: `src/main.gd`
- Modify: `tests/test_app.gd`

**Interfaces:**
- Consumes `PetTheme.font()` and palette constants from Task 1.
- Produces a root `PopupMenu` plus one `scale_menu` submenu with exact labels and IDs.

- [ ] **Step 1: Write the menu-contract assertions.**

  Assert the root menu contains the four labeled groups in order, exact role/tool labels, one scale submenu, exact scale choices, quote settings, current recovery, all recovery, hide, and quit. Assert the root and submenu theme fonts are `PetTheme.font()` and their panel/hover colors match the palette.

- [ ] **Step 2: Run the assertions to verify the current menu fails.**

  Run the app integration test in the Windows display environment. The current flat menu should fail on group/submenu structure while preserving the existing headless limitations.

- [ ] **Step 3: Implement the menu tree.**

  Create and theme `scale_menu` before adding it to the root menu. Replace the flat scale items with `add_submenu_item("放大比例", "scale_menu", 30)`, add the three scale choices to `scale_menu`, and use labeled separators only for `角色`, `工具`, `显示`, and `桌宠`. Keep all existing IDs except the new submenu leaf IDs, and update `_open_menu()` to check the submenu’s selected scale item.

- [ ] **Step 4: Replace system font calls and style the notice.**

  Remove `_chinese_font()` and use `PetTheme.font()` for menu, bubble, critical label, and notice. Set notice font size to 16px, ink to `#303247`, and its dialog surface to the cream palette without changing its error flow.

- [ ] **Step 5: Run the menu-focused test and commit.**

  ```powershell
  .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_app.gd --quit-after 1200 -- --config-path=user://app-test.json
  git add src/main.gd tests/test_app.gd
  git commit -m "Organize root menu into pixel-style groups"
  ```

### Task 3: Rebuild quote editing as one scrollable settings page

**Files:**
- Modify: `src/settings_window.gd`
- Modify: `tests/test_app.gd`

**Interfaces:**
- Keeps `open_editor()`, `_add_row()`, `_update_row()`, `_delete_row()`, `_save()`, and file import/export behavior.
- Replaces `ItemList lines` with `VBoxContainer quote_rows`, `Array[int] filtered_indices`, and `int selected_draft_index`.

- [ ] **Step 1: Add failing layout assertions.**

  After opening settings, recursively count `ScrollContainer` nodes and assert the count is exactly one. Assert no `ItemList` exists and that quote rows are selectable `Button` controls inside the outer scroll content.

- [ ] **Step 2: Run the desktop/app test and observe the current nested list.**

  The current `ItemList` implementation should fail the no-`ItemList` assertion before the replacement.

- [ ] **Step 3: Replace the inner `ItemList`.**

  Keep the existing outer `ScrollContainer`, create a `VBoxContainer` for quote rows, and create one toggle `Button` per filtered draft row. Set the row text to `[%s] %s`, apply the cream/ink theme, and use the gold/coral style for the selected row. Connect each row to `_select_row(index)` and store the selected draft index.

- [ ] **Step 4: Update row actions without changing data semantics.**

  `_refresh_list()` clears and recreates buttons; `_select_row()` fills `input` and `stage`; `_update_row()` uses `selected_draft_index`; `_delete_row()` removes the same filtered draft row. Keep `_add_row()` appending a new `_entry()` and keep “save to make effective.”

- [ ] **Step 5: Apply the shared pixel theme and verify.**

  Set the settings `Theme.default_font` to `PetTheme.font()`, use 16px body text and 24px heading text, and apply the palette to filters, rows, buttons, volume controls, and footer. Run desktop and app tests, then commit:

  ```powershell
  git add src/settings_window.gd tests/test_app.gd
  git commit -m "Make quote settings a single-scroll pixel UI"
  ```

### Task 4: Add selected-leader recovery and middle-click input

**Files:**
- Modify: `src/pet_session.gd`
- Modify: `src/main.gd`
- Modify: `tests/test_core.gd`
- Modify: `tests/test_app.gd`

**Interfaces:**
- Produces `PetSession.reset_character(character: String = selected) -> void`.
- Main input calls `_recover_current()` only for a pressed middle button on `pet.hit_test(point)` when menus/settings are closed and no drag is active.

- [ ] **Step 1: Add the failing session test.**

  In `tests/test_core.gd`, damage both leaders, call `session.reset_character("male")`, and assert male progress returns to zero while female progress remains unchanged. Start and queue an attack before reset and assert `is_busy()` and `queued_count()` are both clear.

- [ ] **Step 2: Implement `reset_character`.**

  Validate the character ID, replace only that state with `_fresh_state()`, clear `_queue` and `_remaining` when resetting the selected character, emit `character_recovered`, then emit `changed`.

- [ ] **Step 3: Add the failing middle-click integration case.**

  Send a pressed middle `InputEventMouseButton` at a visible hit-test point and assert only the selected leader is reset. Send the same event outside `hit_test` and assert no reset.

- [ ] **Step 4: Implement `_recover_current` and input routing.**

  Handle middle-click before the left-button branch, guard against `menu.visible`, `settings.visible`, `pressed`, and `dragging`, call `session.reset_character(session.selected)`, clear the bubble and critical label, refresh the view, and persist no session progress. Keep `全部恢复正常` mapped to `session.reset_all()`.

- [ ] **Step 5: Run core/app tests and commit.**

  ```powershell
  .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_core.gd --quit-after 1200
  git add src/pet_session.gd src/main.gd tests/test_core.gd tests/test_app.gd
  git commit -m "Add middle-click leader recovery"
  ```

### Task 5: Animate the hover weapon cursor

> Superseded by the approved settings-theme and hover-actions spec: the shipped cursor uses a
> 72×72 canvas, a (36, 36) hotspot and five cached frames at 100ms per frame.

**Files:**
- Modify: `src/pet_view.gd`
- Modify: `src/main.gd`
- Modify: `tests/test_app.gd`

**Interfaces:**
- Produces `PetView.weapon_cursor_frames(weapon: String) -> Array[Texture2D]`, cached per weapon.
- Main uses `_hover_cursor_frame_for_time(elapsed: float) -> int` with phase boundaries at 0.0, 0.12, 0.24, and 0.36 seconds.

- [ ] **Step 1: Add deterministic cursor-frame assertions.**

  Assert `_hover_cursor_frame_for_time(0.0) == 0`, `0.119 == 0`, `0.12 == 1`, `0.239 == 1`, `0.24 == 2`, `0.36 == 1`, and `0.48 == 0`. Assert hammer/glove frame arrays each contain three 56×56 textures and are not the same texture resource.

- [ ] **Step 2: Run the assertions to verify the current static cursor fails.**

  The current code has no frame helper and only installs the 48×48 source texture, so the new checks must fail before implementation.

- [ ] **Step 3: Generate cached 56×56 frames in `PetView`.**

  For each weapon, create three transparent 56×56 RGBA images, blit the 48×48 source at `(4, 5)`, `(4, 4)`, `(4, 3)` for hammer or `(3, 4)`, `(4, 4)`, `(5, 4)` for gloves, and convert each image with `ImageTexture.create_from_image`. Return the cached array.

- [ ] **Step 4: Swap the cursor texture at the fixed cadence.**

  On hover entry reset `hover_cursor_elapsed` to 0 and install frame 0 with hotspot `(28, 28)`. While hover remains active, increment elapsed by `delta`, map it through `[0, 1, 2, 1]`, and call `Input.set_custom_mouse_cursor` only when the frame changes. On hover exit, menu open, settings open, or drag start, clear the custom cursor and reset the animation state.

- [ ] **Step 5: Run focused tests and commit.**

  ```powershell
  .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_app.gd --quit-after 1200 -- --config-path=user://app-test.json
  git add src/pet_view.gd src/main.gd tests/test_app.gd
  git commit -m "Animate the hover weapon cursor"
  ```

### Task 6: Full verification and export

**Files:**
- Modify: `tests/test_app.gd` only if an uncovered acceptance assertion is needed.

- [ ] **Step 1: Run all existing headless tests.**

  ```powershell
  $godot = '.tools/godot/Godot_v4.5.2-stable_win64_console.exe'
  foreach ($test in @('test_core.gd','test_desktop.gd','test_view.gd','test_female_idle.gd','test_attack_motion.gd')) {
      & $godot --headless --path . --script (Join-Path 'tests' $test) --quit-after 1200
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
  ```

- [ ] **Step 2: Import and export the Windows build.**

  Run `& $godot --headless --path . --editor --import --quit` followed by `& $godot --headless --path . --export-release 'Windows Desktop' 'dist/DesktopPet/DesktopPet.exe'`. Confirm the export includes the font resource and no script/import errors.

- [ ] **Step 3: Run `git diff --check` and inspect the final diff.**

  Confirm only the requested font/UI/input files and their tests changed; preserve all pre-existing unrelated `.scratch` edits.

- [ ] **Step 4: Commit verification changes if any.**

  ```powershell
  git add tests/test_app.gd
  git commit -m "Verify pixel menu and hover redesign"
  ```

## Spec Coverage Review

- Bundled font, source pin, license, and shared use: Task 1.
- Exact root menu and scale submenu: Task 2.
- One settings scroll region and clearer quote rows: Task 3.
- Middle-click current-leader recovery and explicit all-leader reset: Task 4.
- 56×56, 28×28-hotspot, 120ms hover animation: Task 5.
- Regression suite, import, export, and diff hygiene: Task 6.
