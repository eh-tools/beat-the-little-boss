# SDD ledger — plan: .scratch/desktop-pet/plan.md

## Context and decisions

- User authorized implementation from the existing confirmed spec. Published the existing spec as the single implementation reference; preserved interview draft.
- New repository with no commits or code. Work occurs on `codex/desktop-pet`; no unrelated changes to preserve beyond the original docs.
- Godot 4.5.2 pinned for reproducible exports; Compatibility renderer.
- Native Windows layered-window passthrough toggles for main-window sprite pixels; a separate speech Window always passes clicks. This replaces the initially attempted Godot-only hit-test flag (ADR 0002).
- Implementation stays in the current checkout. Local tasks, no external issue publishing.

## Interface scan

| Tasks | Producer / consumer | Result |
| --- | --- | --- |
| 01 / 03 | Session attack events; portable JSON preferences; BubbleClock | Exact interfaces in 01 brief consumed by main.gd |
| 02 / 03 | PetView set_character/play_attack/hit_test/solid_test/weapon_texture | Pixel body 160×180, margin added only by main |
| 01 / 04 | Deterministic roll/time hooks and validated data methods | RefCounted core tests independent of renderer |
| 02 / 04 | Actual rendered gallery | Capture script owned by presentation worker |
| 03 / 04 | Native scene + settings + build | Isolated test config path; no real user preferences overwritten |
| 01 | Behavioral tests and module contracts | Reviewed; initial missing-file/recovery/default-quotes findings corrected with regression tests |
| 02 | Art and rig completeness | Complete; foreground-prop hit testing and visible kneeling corrected after review |
| 03 | Desktop/settings consistency | Real-window app test passes with zero platform errors; the owned speech window no longer requests its own topmost flag |
| 04 | Export/test evidence | Final ZIP rebuilt and launched from a fresh directory on September 16; QA in docs/qa/2026-09-16.md |

## Progress

- Task 01 implementer `/root/core`: core tests passed.
- Task 01 reviewer `/root/review_core`: three findings recorded in core-review.md.
- Root added failing first-launch/recovery regression tests, then fixed missing config and explicit recovery preserving `.corrupt`; expanded built-ins to multiple lines per stage.
- Task 02 implementer `/root/art`: original presentation complete; root integrated review fixes and final report.
- Task 03 root: window, settings, audio and geometry implemented. `test_desktop.gd` passes including draft CRUD.
- Task 04 root: export preset, build script, README, isolated app test prepared.
- Root fixed the owned speech window: `_apply_preferences` no longer sets `always_on_top` on the transient bubble, which Windows rejects and which then also broke the later hide path. Verified the regression guard has teeth by reintroducing the line (exit 4, 27 platform errors) before reverting. Real-window suite now reports zero platform errors.
- Root restored the export templates: resumed the truncated `.tools/templates.zip` to the full 1,353,063,159 bytes, verified SHA512 against the official release checksums, and unpacked `windows_release_x86_64.exe` / `windows_debug_x86_64.exe`. `tools/build.ps1` now completes and produces `dist/DesktopPet/DesktopPet.exe` and `dist/DesktopPet-Windows-x64.zip`.
- Launched the exported executable from a clean portable directory: window is borderless, topmost and 192x212; per-pixel transparency verified by diffing the desktop region with and without the pet (34.2% of the window rect changes, all four corners pixel-identical to the bare desktop); closing the window runs the quit path and writes a valid `preferences.json` (version 1, 46 quotes).
- Open defect found during that launch check: `Window.mouse_passthrough` cannot make the pet click-through to other applications. Godot 4.5.2 implements the flag as `return HTTRANSPARENT` in `WM_NCHITTEST`, and Windows only forwards the hit test to windows in the same thread. A real click on the transparent margin was swallowed by the pet in 3 of 3 attempts, and `WS_EX_TRANSPARENT` is never set on the window. Only `DisplayServer.window_set_mouse_passthrough()` (a `SetWindowRgn` region) passes through to other processes, which is the native clipping polygon this plan deliberately avoided.

## Completion — 2026-09-16

- The historical passthrough defect above is resolved by the small native GDExtension (native-report.md and ADR 0002). On September 14, both transparent margins and the visible speech bubble passed real input through to an independent Tk application; opaque leader pixels still attack.
- Art review findings resolved: all foreground props block hits and dedicated visible kneeling legs remain above the terminal wreckage. Settings save footer stays inside its window.
- Final review's universal-quote finding resolved: universal and exact-stage candidates are combined; the default-library-plus-custom-entry regression passes.
- Fast drag first failed its event-coordinate regression. Button-down now records event.position rather than a later OS mouse position. Full renderer tests pass; actual Windows drag moved (950,690) to (975,705), saved that position, and caused no attack. The following real click caused exactly one normal attack.
- Final tools/build.ps1 passed import, core/desktop/view suites and Windows export. Real-renderer app suite and native ABI/flags suite also passed separately with no errors.
- Final ZIP is 34,963,351 bytes, contains only EXE, native DLL, README and notices, and starts successfully from a new extraction directory. QA, controls and compatibility limits are recorded in docs/qa/2026-09-16.md and README.md.
- Implementation tasks 01–04 complete. Windows 10, other GPUs and mixed-DPI/multiple-monitor hardware remain unverified; geometry tests do not claim hardware coverage. No external publication or Git commit was performed.

## Follow-up 0.1.1 — head attachment and glove hooks

User screenshots exposed a 7-pixel head/collar offset plus a further 4-pixel lift during glove hits. Fixed the chin pivot and kept recoil rotation attached. Glove attacks now follow mirrored arcs with inward knuckles, opposite-side guard and visible recovery. New regressions failed before the changes and now pass for both roles/all stages and normal/critical hits; full core/desktop/view and real renderer integration suites pass. Rendered frames inspected in docs/qa/hooks-after.png.

Task 05 is complete. The user is running the original dist/DesktopPet/DesktopPet.exe, so it was not stopped or replaced. Version 0.1.1 is in dist/DesktopPet-0.1.1/ and dist/DesktopPet-Windows-x64-0.1.1.zip; generic ZIP refreshed. Clean-extraction startup verified, file version 0.1.1.0. Export excludes dist resources after discovering local preference JSON in the previous export log; final export log contains no res://dist/ entries. No user configuration was modified.

## Follow-up 0.1.2 — chin bruise and terminal recovery

User identified the persistent chin overlay as an object across the neck and requested automatic restoration after kneeling. Failing regressions showed the original 26×13 strip and the session remaining at 36 after the entire desired hold. Replaced it with a 12×8 one-sided lower-jaw bruise. Added a per-character recovery timer equal to the 1.2-second finale plus a five-second terminal hold, a one-shot `character_recovered` signal, and immediate main-view reconstruction. The other character's progress remains unchanged.

Core/desktop/view and real renderer application suites pass. Updated gallery inspected. `DesktopPet-Windows-x64-0.1.2.zip` contains only the EXE, native DLL, README and notices; clean extraction launch exited 0 and reports version 0.1.2.0. SHA256: `155F364A967F577E79BE5BD48D64194465B14A93649B1742AC33BCBC2DDCBE2D`. The running 0.1.1 process was left alone.

## Follow-up 0.1.3 — coffee sip and speech anchor

User marked the female coffee hand/cup being hidden by the head and a distant speech bubble. Test-first evidence: cup center was 12 pixels from the mouth, the sip forearm was at the head z layer, and the bubble bottom was 37 pixels above the visible head. Idle sip now moves the cup to the mouth-local endpoint and lifts its arm/forearm above the head only during idle; bubble placement uses the visible head anchor rather than transparent-window top.

Renderer close-up inspected in docs/qa/sip-closeup.png. Core, desktop, view and app tests pass. `DesktopPet-Windows-x64-0.1.3.zip` contains exactly EXE, DLL, README, notices; clean extraction launch exited 0 at version 0.1.3.0. SHA256: `CC141D2E145606D9150F7D37ACC32779258CB3EB3466E603B8FEF289E1476819`. Existing running 0.1.1 process left untouched.

## Follow-up 0.1.4 — cigarette anchor

User reported the male cigarette had moved onto his hand. Cause was the shared idle prop inheriting the female cup's arm motion. The prop now reparents to the head for male, where its first pixel is within seven pixels of the mouth; it returns to the right forearm for female. Smoke keeps using that prop's tip, so it now rises from the mouth cigarette. Core, desktop and view tests pass, and an inspected renderer capture is in docs/qa/smoke-closeup.png.

`DesktopPet-Windows-x64-0.1.4.zip` contains exactly EXE, DLL, README and notices. A clean extraction launch exited 0 at version 0.1.4.0. SHA256: `056814DA2AB5CF7A3D8C500DB67BF45C6AE8676DCCF49EEC23E6DC54C6C61381`. Existing running 0.1.3 process left untouched.

## Follow-up 0.1.5 — startup flashes

User reported a Godot graphic and a second box flashing at launch. A Windows window/screen probe reproduced a transient incomplete main frame at the default center position and the explicit onboarding speech bubble. Startup now disables the Godot boot image, uses a transparent 1×1 placeholder, and restores the configured 192×212 window after one rendered frame; the onboarding bubble call was removed. Core, desktop, view, app integration, import/export and the exported startup probe all pass.

`DesktopPet-Windows-x64-0.1.5.zip` contains exactly EXE, DLL, README and notices. The versioned output is in `dist/DesktopPet-0.1.5/`; the existing 0.1.4 process was not stopped or overwritten. ZIP SHA256: `69E758E5D09BA822FA4D0647C6DE48ABF85C320DD9064111554F6476A7EC17B3`.

## Follow-up 0.1.7 — icon-derived male sprite animation

The male leader now uses a transparent upper-body sprite derived from the new application icon, attached to the existing hip bone so idle breathing, smoking motion, hit recoil, and terminal collapse remain visible. The female character remains on the articulated sprite rig. The icon is embedded in the Windows export and the product name is `Beat the Little Boss`.

Core, desktop, and view tests pass. The app integration test still reports the known headless-only window flag mismatches and does not terminate cleanly in this environment; it is not used as the export gate. The export will be rebuilt after the asset import.

## Follow-up 0.1.8 — 32-frame male sprite animation

The approved 16-frame idle/smoking sheet and 16-frame damage/terminal continuation are normalized into 32 runtime textures. `PetView` selects the idle, smoking, sustained hit, injury-stage, kneeling, and recovery frames while the sprite remains attached to the hip bone. Boss frames contain no punch pose; hammer and glove attacks remain external weapon animations.

## Follow-up 0.1.9 — stable male animation cadence

The 0.1.8 sprite appeared to twitch because all twelve base frames looped continuously at 8 fps and persistent injury states rotated through three differently registered full-body poses. Idle now uses a 14-second authored sequence: held calm poses, slow expression changes, then a 3.5-second smoking action. Each injury stage holds one matching damaged pose; the four-frame reaction still runs during every actual hit.

The new timing regressions fail on 0.1.8 and pass after the fix. Core, desktop, view, export, Windows startup, and clean-extraction startup checks pass. `DesktopPet-Windows-x64-0.1.9.zip` contains exactly the EXE, native DLL, README, and notices; its file/product version is 0.1.9.0. SHA256: `18C163B343946097B8BAF6ABD116C4C8B4055FF41EDB26EAFBFB5796BD5EF73F`.

## Follow-up 0.1.10 — male leader desk integration

The male sprite previously rendered in full behind a desk texture with transparent regions, causing suit and hands to appear through the drawers and lower desk opening. Non-terminal male stages now use the existing `Sprite2D` region to draw only the top 160×108 pixels, while the unchanged desk remains in front. This retains the face, shoulders, smoking action, and hit recoil above the desk while removing the detached lower-body leak. The terminal kneeling stage turns the region off so its full pose and wreckage remain visible.

New view regressions verify the desk-edge region, reject an under-desk body pixel, and preserve the terminal sprite. Core, desktop, view, export, Windows startup, and clean-extraction startup checks pass. `DesktopPet-Windows-x64-0.1.10.zip` contains exactly the EXE, native DLL, README, and notices; its file/product version is 0.1.10.0. SHA256: `D11665B8EB0E30181105D5F733047CDB7DB3B4FDB05D2CA3EA76CBB0EA63E880`.
