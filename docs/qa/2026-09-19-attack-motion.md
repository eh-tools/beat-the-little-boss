# Attack motion — 0.1.18

## Changes

- Preserve the currently displayed frame during wind-up; switch to a stable reaction pose at contact and settle before action completion.
- Replace the instantaneous body recoil with a 45 ms eased onset. Retain peak recoil and the existing contact hold.
- Ease weapon travel, withdrawal and visibility. Hammer and critical attacks now visibly withdraw instead of fading at the contact point. Recovery uses the remaining duration, eliminating the critical animation's invisible trailing cooldown.
- Preserve fractional weapon coordinates until the renderer applies pixel snapping.
- Capture female hand positions at attack start and guide the coffee hand back on a 220 ms curve, avoiding a shoulder-crossing elbow flip.
- Restart idle timing for both roles after interruption, so the male role does not suddenly resume a raised smoking frame at the end.

Normal/critical durations remain 0.35/0.7 seconds. Damage, critical odds, queue capacity, terminal timing and gameplay settlement are unchanged.

## Verification

- Baseline core, view and female idle suites passed before changes.
- New `tests/test_attack_motion.gd` failed on the old premature-frame, recoil, withdrawal and end-pose behavior. Separate failing checks caught interrupted-coffee elbow flips and smoking resumption.
- All 128 combinations (2 roles × 4 seated stages × 2 weapons × normal/critical × 2 directions) pass the contact, peak impact, visible withdrawal and completion checks.
- Across contact ±1 ms, maximum body-angle change is **0.000117 radians**, versus the previous **0.08 radians** step.
- At 65% of recovery, every weapon has moved at least **30.56 pixels** away from its contact position and is still visible.
- At 60 Hz, the interrupted female hand/elbow maximum frame steps are **7.58/11.54 pixels**; the straight-line intermediate attempt produced a **47.23-pixel** elbow jump and was replaced.
- Core, desktop, view, female idle, attack motion and female frame asset suites pass. The new motion suite is part of `tools/build.ps1`.
- Real OpenGL application integration passed with an isolated preference file.
- Full build/export and both exported-directory and fresh-extraction Windows startup probes passed.

## Rendered comparison

Before/after sequences were captured from Godot at 60 Hz for both roles. Key wind-up, contact and recovery frames were inspected. The comparison uses the same timings and display scale in both rows; top is before, bottom is after.

- Video: `../../.scratch/desktop-pet/attack-motion-comparison.mp4`.
- Looping GIF: `../../.scratch/desktop-pet/attack-motion-comparison.gif`.
- Capture harness and baseline source: `../../.scratch/desktop-pet/debug/capture_attack_motion.gd` and `pet_view_before_motion.gd`.
- Individual captures: `../../.scratch/desktop-pet/debug/motion-female/` and `motion-male/`.

These changes address motion continuity; no claim of increased rendering FPS is made.

## Package

- Executable: `dist/DesktopPet-0.1.18/DesktopPet.exe` (generic executable also refreshed).
- ZIP: `dist/DesktopPet-Windows-x64-0.1.18.zip`, 37,763,822 bytes.
- File/product version: `0.1.18.0`.
- Exactly EXE, native DLL, README and notices.
- SHA256: `0A69F10492AC7C47BA087DBF424094CA5E6AC0D1BB980035E8C378396D4A48B7`.
