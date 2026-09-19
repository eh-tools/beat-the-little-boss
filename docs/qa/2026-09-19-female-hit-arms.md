# Female hit arms — 0.1.17

The previous arm visibility guard returned whenever `active` was true or the stage was not zero. Since seated damage frames contain no complete arms, this removed both limbs during hits and injured rest. The corrected guard hides the supplemental arms only for the male role and terminal stage. Female seated damage poses use the existing arm chains, anchored to the current frame's shoulders, with wrist targets that follow the hip's recoil. Coffee playback stays disabled during hits and after injury.

## Evidence

- Before changes: core, desktop, view and female idle suites passed, confirming the missing coverage.
- Added regression matrix: 4 seated stages × 2 weapons × 2 directions × normal/critical × 1×/2× scale = 64 cases. Each samples attack startup, contact, recoil, the last active frame, completion and rest. All 64 failed the visible-arm assertion before the fix; injured resting stages 1–3 also failed.
- After changes: both arms/hands remain visible, shoulder/elbow/wrist joints stay connected, opaque sleeve pixels remain attackable, hands move with recoil and the cup remains on the desk.
- Existing full-cycle coffee, role-switching, terminal-art and scaling tests still pass.
- Core, desktop, view, female idle, female frame assets and real-window application integration passed.
- `tools/build.ps1` passed import, all Godot suites, export and the Windows startup probe. A new extraction of the archive passed the startup probe separately.

## Real-renderer captures

- Before: `../../.scratch/desktop-pet/female-hit-arms-before.png`.
- After: `../../.scratch/desktop-pet/female-hit-arms-after.png`.
- Both roles, all injury stages: `../../.scratch/desktop-pet/art-gallery.png`.

The after capture covers hammer hits and critical glove hits at all five stages and was visually inspected. `tests/capture_female_hits.gd` reproduces it. Source character textures and male behavior are unchanged.

## Package

- Executable: `dist/DesktopPet-0.1.17/DesktopPet.exe` (generic executable also updated).
- Archive: `dist/DesktopPet-Windows-x64-0.1.17.zip`, 37,763,009 bytes.
- File/product version: `0.1.17.0`.
- Exactly four files: EXE, native DLL, README, notices.
- SHA256: `A1B0C304B38DD86C8F7231C21EE80028928CC05EF1C426EAC6717618C04A8257`.
