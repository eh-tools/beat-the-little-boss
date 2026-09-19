# Rebuild the male leader and desk layering
Status: ready-for-agent
Completion: complete

The 0.1.10 region crop removed the body leak but still made the male leader look like a large head placed behind an unrelated desk. The approved design requires a single coherent desk scene using the existing 32-frame leader identity.

## Acceptance

- Reuse the existing 32-frame male leader textures; do not replace the character appearance with generated art.
- Show the full head, shoulders and upper chest behind the desk at a stable scale and baseline.
- Render connected hands on the keyboard layer, retain the smoking pose, and keep the desk as a complete foreground cabinet.
- Place the coffee cup at `(127, 118)` with its bottom at the desk edge.
- Preserve the female leader and full male terminal kneeling scene.

## Comments

2026-09-18: User approved the three-layer relationship and the coffee-cup placement in the visual companion. The design is recorded in `docs/superpowers/specs/2026-09-18-male-layered-desk-redesign.md`.

2026-09-18: Implemented the approved scene using the existing 32 male-frame textures only. Normal male stages use a compact upper-body layer behind a desk-top layer, frame-derived desktop hands, and a foreground cabinet layer; the smoking frame exposes the original raised hand without a duplicate desktop hand. The cup is at `(127, 118)`, where its base meets the desk edge. The terminal state restores the full kneeling frame and damaged furniture.

The view regression suite was written before the implementation and failed against the previous one-desk scene. Core, desktop, view, complete export, Windows startup, and fresh-extraction startup checks now pass. `dist/DesktopPet-Windows-x64-0.1.11.zip` reports file/product version `0.1.11.0`; SHA256: `251FB443B4BF4F1FF30333C58B2B1D4769F2A855C03CB62715EA446ECCE6D7EC`.

2026-09-18: Follow-up fixes remove the frame-derived hand crops, which were creating the visible seam and misplaced fragments. The upper-body crop now terminates directly behind the desktop edge. During male attacks the monitor, keyboard, coffee and both desk layers retain their normal positions; only the leader skeleton recoils.

`DesktopPet-Windows-x64-0.1.12.zip` passed the full build and a fresh-extraction startup test. It reports file/product version `0.1.12.0`; SHA256: `26DE3479FFC3F76D97CA56361EE57AB9A58D51B3ED6FF71C9164071367B8925A`.

2026-09-18: Follow-up 0.1.13 fixes the remaining transparent gap. The old crop ended at screen y=119 while the opaque desktop began at y=125. Some damage frames also ended at source y=140–144, substantially above the idle torso. Expanded the seated crop to source y=160 and computed a cached vertical offset from each frame's solid torso center, placing its base at y=130 beneath the desktop. Existing breathing and recoil remain attached to the hip. Source PNG files are unchanged.

Smoking frames 04–07 also contain a stray sprite-sheet strip at source y=22–31. A runtime top crop hides it without moving the character; pixel hit testing now accounts for region offsets. Full terminal kneeling and female animation are preserved.

Desk-contact regressions failed before the fix (456 failed assertions), then passed across all 28 seated frames, both breathing extremes, four seated stages, both attack directions, and normal/critical weapons. Smoking-strip and cropped-alpha-mask regressions also failed before their respective fixes. Core, desktop, view, real-window app integration, export, startup, and fresh-extraction startup checks pass. All 32 frames were inspected in `.scratch/desktop-pet/male-desk-all-frames.png` using the retained diagnostic capture in `.scratch/desktop-pet/debug/`.

`DesktopPet-Windows-x64-0.1.13.zip` contains only the EXE, native DLL, README, and notices. File/product version: `0.1.13.0`; SHA256: `7E8A71D26BF1EDF0E9E9F233AB2F5DC2CD4F07B1B398241D05BF87F9B1A3BF9D`. The currently running copy in the user's archive temporary directory was left running; the updated executable is `dist/DesktopPet/DesktopPet.exe`.

2026-09-18: User screenshots showed that 0.1.13's idle pose still buried the chest and hands behind the desk. Its torso scan stopped at source y=159, falsely treating the crop boundary as the torso bottom; the idle torso actually extends through y=171. The scan now covers the full source image, and each frame crops at its own measured torso bottom. This restores about nine screen pixels of chest in the normal idle pose without detaching the body. The desktop draws behind the seated hands, while props and the cabinet remain in front. Hit testing likewise permits clicking exposed hands over the desktop.

Four new idle-collar clearance checks failed before the full-height scan. Desktop layering and visible-hand hit checks then failed before their corresponding fix. All view regressions, core/desktop suites, real-window integration, export/startup, and fresh-extraction startup checks pass. Inspected the complete frame gallery and a Godot-rendered before/after comparison at `.scratch/desktop-pet/idle-layer-comparison.png`. Original sprite assets remain unchanged.

Delivered `dist/DesktopPet/DesktopPet.exe` and `dist/DesktopPet-Windows-x64-0.1.14.zip`, file/product version `0.1.14.0`. SHA256: `717E29E200AB153669D570DD2322AB9082821C4F5EDD5B087958AEF81E1CA563`. Generic ZIP refreshed; the user's existing running instance was not closed.

2026-09-19: User approved the idle proportions but reported that attacks visibly shrink the male leader. The damage frames' continuous head/torso silhouettes measured only 77–88% of the idle height despite identical canvas dimensions. Cached per-frame scale compensation now brings frames 16–27 to the approved idle silhouette height. Scaling stays uniform on both axes and is anchored at the existing body center and desktop baseline. Frames 00–15 retain their exact original scale and horizontal position; full terminal frames retain their previous treatment. No PNG assets changed.

All 12 damage-size regressions failed before the correction, then passed. Added checks for unchanged idle/smoking scale, restoration after hits, actual attack playback, and persistent injury size. Inspected the complete gallery and `.scratch/desktop-pet/hit-size-comparison.png` (idle, previous hit, corrected hit). Core, desktop, view, real-window integration, full build/startup, and fresh-extraction startup tests passed.

Delivered `dist/DesktopPet/DesktopPet.exe` and `dist/DesktopPet-Windows-x64-0.1.15.zip`, file/product version `0.1.15.0`. Generic ZIP refreshed. SHA256: `C807BEB6F129A9DB6F67DC17AD27096B4A61C567AE22B9A3DB5D97202160CD9C`.
