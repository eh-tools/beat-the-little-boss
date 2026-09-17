# Replace the male pet with the icon-derived sprite
Status: ready-for-agent
Completion: complete

The user preferred the boss character from the new application icon and asked to use it as the male pet sprite.

## Acceptance

- The male character uses the icon-derived face, glasses, hair, suit, and tie in the desktop pet.
- The existing desk, chair, hit testing, weapon swings, and female articulated character remain available.
- The Windows application and taskbar use the same icon, named `Beat the Little Boss`.

## Comments

2026-09-18: Generated a transparent pixel-art upper-body sprite from the icon character, removed its baked-in desk, and connected it to the existing PetView furniture and weapon layers. The male icon sprite now follows the hip bone, so idle breathing, smoking motion, hit recoil, and terminal kneeling all remain animated. Added the approved 16-frame idle sheet plus 16 sustained damage/terminal frames as 32 normalized textures; boss frames contain no punch pose. The female character keeps the existing bone rig. Added `assets/icon.png` and `assets/icon.ico`, wired the Windows export icon and English product name, and excluded the large source reference from exports. Core, desktop, and view tests pass.

2026-09-18: Fixed the 0.1.8 male animation twitching. The cause was scheduling all twelve base frames at 8 fps during every idle period and continually rotating three full-body injury poses. Idle now follows a 14-second authored sequence with long held poses and a deliberate 3.5-second smoking segment; injury stages hold their persistent pose until a real hit starts the four-frame reaction. Regression tests fail on the old cadence and pass on the new cadence. Core, desktop, view, export, Windows startup, and clean-extraction startup checks pass for 0.1.9.

2026-09-18: Fixed the male leader and desk integration in 0.1.10. Normal through heavy-injury male poses now render only the upper 160×108 portion of each existing sprite frame, with the unchanged desk drawn in front. This prevents the body from appearing through the transparent spaces between drawers and desk legs. The terminal stage disables the crop so the complete kneeling frame and broken furniture remain visible. New View regressions prove the region dimensions, reject a desk-underbody pixel, and retain the terminal frame. Core, desktop, view, export, Windows startup, and clean-extraction startup checks pass.
