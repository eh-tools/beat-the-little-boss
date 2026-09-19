# Female coffee rig — 0.1.16

The original normal idle drew only a framed torso. All articulated arm sprites were hidden, while coffee frames added a disconnected skin stroke and cup without hiding the separate desk cup. Switching between those crops also moved the head independently of the cup motion.

The corrected normal idle holds the approved clean body texture and uses the existing sleeve and hand textures on two fixed-length arm chains. The wrist owns the cup; the fingers render above its handle. Pickup, sip and lowering use an eased curve, with the cup rim aligned to the mouth. A hit cancels the sip and restarts its timing; injury and terminal states keep their existing frame rendering.

## Verification

- Baseline core, desktop, view and female asset suites passed.
- `tests/test_female_idle.gd` failed nine behavioral checks on the original implementation, including visible limbs, one held cup, frame stability, grip attachment and mouth contact.
- The repaired test samples all 841 poses in a 14-second cycle at 60 Hz. Shoulder/elbow/wrist contact, smooth elbow and cup movement, sleeve hits and cup occlusion pass. Separate checks cover 1×, 1.5× and 2× scale, visible fingers, both roles, all five stages, hit interruption and return to rest.
- Core, desktop, view, female idle and female asset tests passed after the fix.
- Real OpenGL `tests/test_app.gd -- --config-path=user://app-test.json` passed with an isolated preference file.
- `tools/build.ps1` passed imports, all four Godot test suites, Windows export and the startup-window probe. The new coffee regression suite is part of the build gate.
- The exported archive was extracted into a new directory; its startup-window probe passed. Both file and product versions are `0.1.16.0`.

## Rendered evidence

- Six real-renderer poses at 2× scale: `../../.scratch/desktop-pet/female-coffee-rig.png`, produced by `tests/capture_female_idle.gd`.
- Both roles and all injury stages: `../../.scratch/desktop-pet/art-gallery.png`, produced by `tests/capture_art.gd`.
- Original coffee sequence: `../../.scratch/desktop-pet/debug/female-idle-before.png`.

The captures were visually inspected. No character PNGs were edited. This change targets normal female idle; damaged and terminal artwork retain their existing presentation.

## Package

- Executable: `dist/DesktopPet/DesktopPet.exe`.
- Versioned copy: `dist/DesktopPet-0.1.16/DesktopPet.exe`.
- Archive: `dist/DesktopPet-Windows-x64-0.1.16.zip` (37,763,045 bytes).
- Archive contains exactly the EXE, native DLL, README and notices.
- SHA256: `B98999374CCE0D4F3D201EAF30EC8E100770D2EE7A038FF8F3ECB94E38F669B0`.

Jev was unavailable in this session. These results are from executable checks and renderer inspection; no model-based Jev evaluation is claimed.
