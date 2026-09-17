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
