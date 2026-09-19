# Desktop Pet Implementation Plan

> Execute task by task using subagent-driven-development; the current session owns desktop integration and verification.

**Goal:** Deliver a playable Windows portable desktop pet matching the approved specification.
**Architecture:** Godot 4.5.2, small GDScript modules for gameplay, local data, presentation and desktop integration. Pixel layers attached to Bone2D hierarchies; no external runtime dependencies.
**Tech Stack:** Godot 4.5.2 Compatibility renderer, GDScript, original raster art and synthesized WAV audio.
**Spec:** [Published specification](spec.md). User authorized implementation on 2026-09-12; use the documented testing boundaries and implementation defaults.

## Global Constraints

- Windows 10/11 portable; offline, no accounts, no telemetry, no TTS.
- Both leaders; 160×180 body, 1/1.5/2 scale; per-session injuries, portable preferences.
- 36 progress cap; stage boundaries 9/18/27/36; 15% critical, fifth-hit guarantee; queue at most two requests.
- True Skeleton2D/Bone2D animation, distinct hammer and gloves, layered injuries and staged furniture collapse.
- Transparent background passes clicks; drag cannot attack; taskbar recovery after hide.

## Tasks

- [x] 01 Gameplay and local data: `src/pet_session.gd`, `src/pet_data.gd`, `src/bubble_clock.gd`, `tests/test_core.gd`. See [#4](https://github.com/eh-tools/beat-the-little-boss/issues/4).
- [x] 02 Original presentation: `src/pet_view.gd`, `assets/`, asset generation tools. See [#5](https://github.com/eh-tools/beat-the-little-boss/issues/5).
- [x] 03 Desktop integration: `project.godot`, `src/main.gd`, `src/settings_window.gd`, `src/audio.gd`, `src/main.tscn`. See [#6](https://github.com/eh-tools/beat-the-little-boss/issues/6).
- [x] 04 Tests, visual verification and Windows export: `tests/test_app.gd`, `export_presets.cfg`, `tools/build.ps1`, `README.md`, `docs/qa/2026-09-16.md`. See [#7](https://github.com/eh-tools/beat-the-little-boss/issues/7).

## Verification commands

```powershell
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --editor --import --quit
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --headless --path . --script tests/test_core.gd
& .tools/godot/Godot_v4.5.2-stable_win64_console.exe --path . --script tests/test_app.gd -- --config-path=user://app-test.json
./tools/build.ps1
```

Tests must report assertions and return nonzero on failure. Rendering captures use the actual Godot viewport. Record actual desktop checks separately from headless coverage.

## User follow-up

- [x] 05 Head/collar attachment and glove hooks: [#8](https://github.com/eh-tools/beat-the-little-boss/issues/8). Delivered 0.1.1 with failing-before/passing-after regressions, rendered contact sheet and clean-extraction startup verification.
- [x] 06 Refine chin injury and restore after kneeling: [#9](https://github.com/eh-tools/beat-the-little-boss/issues/9). Delivered 0.1.2 with a local jaw bruise, independent five-second terminal recovery and clean-extraction verification.
- [x] 07 Repair coffee sip layering and bubble anchor: [#10](https://github.com/eh-tools/beat-the-little-boss/issues/10). Delivered 0.1.3 with mouth-level cup motion, foreground sip layer and a visible-head speech anchor.
- [x] 08 Anchor the cigarette at the male leader's mouth: [#11](https://github.com/eh-tools/beat-the-little-boss/issues/11). Delivered 0.1.4 with role-specific idle prop parenting and smoke origin verification.
- [x] 09 Remove startup flashes: [#12](https://github.com/eh-tools/beat-the-little-boss/issues/12). Delivered 0.1.5 with a transparent staged startup window, no boot image and no onboarding bubble.
