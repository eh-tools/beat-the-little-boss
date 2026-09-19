# SDD ledger — plan: docs/desktop-pet/plan.md

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

## Follow-up 0.1.11 — male layered desk scene

The normal male leader scene now keeps the approved original 32-frame character identity while composing the figure as upper body behind the desk, frame-derived hands on the desktop, and a complete foreground cabinet. Smoking suppresses the duplicated right desktop hand so the original raised cigarette hand remains visible. The coffee cup is positioned at `(127, 118)`, with its base aligned to the front desk edge. The terminal state retains the complete kneeling frame and broken furniture.

New view checks were failing before the layer implementation and now pass, along with core, desktop, full build, Windows startup, and fresh-extraction startup checks. `DesktopPet-Windows-x64-0.1.11.zip` contains only the EXE, native DLL, README, and notices; its file/product version is 0.1.11.0. SHA256: `251FB443B4BF4F1FF30333C58B2B1D4769F2A855C03CB62715EA446ECCE6D7EC`.

## Follow-up 0.1.12 — stable male desk during hits

The frame-derived desktop hand fragments were removed because their source bounds made a visible seam and stray upper fragments. The male upper-body crop now ends behind the desk edge, so the desk forms one continuous foreground. Male hit recoil stays on the leader skeleton: the desk layers, monitor, keyboard, papers, ashtray, and coffee remain anchored at their normal positions.

New View regressions first failed for the old crop and moving hit props, then passed after the fix. Core, desktop, view, complete export, Windows startup, and fresh-extraction startup checks pass. `DesktopPet-Windows-x64-0.1.12.zip` contains exactly the EXE, native DLL, README, and notices; its file/product version is 0.1.12.0. SHA256: `26DE3479FFC3F76D97CA56361EE57AB9A58D51B3ED6FF71C9164071367B8925A`.

## Follow-up 0.1.13 — male torso contact across frames

Fixed the actual transparent gap between the seated torso and opaque desktop by extending the crop and aligning each frame's solid torso center below the desk edge. This accommodates the shorter damage frames while retaining the original PNGs, compact scale, breathing, and recoil. Runtime cropping also removes the disconnected strip above smoking frames 04–07; region-aware pixel hit testing matches the resulting visible character.

Failing-first regressions cover all 28 seated frames, breathing extremes, stages 0–3, normal/critical attacks, smoking strips, and cropped hit masks. Core, desktop, view, real-window app integration, complete build, and fresh-extraction startup tests passed. All 32 rendered frames were inspected. Version 0.1.13.0 is available in `dist/DesktopPet/DesktopPet.exe` and `dist/DesktopPet-Windows-x64-0.1.13.zip`; generic ZIP refreshed. ZIP SHA256: `7E8A71D26BF1EDF0E9E9F233AB2F5DC2CD4F07B1B398241D05BF87F9B1A3BF9D`. The existing running copy and user preferences were preserved.

## Follow-up 0.1.14 — restore the complete idle seated pose

User screenshots exposed that the previous no-gap checks did not ensure a visible chest and resting hands. Removed the artificial y=160 limit from torso measurement: all seated frames now use their actual torso bottom, with a matching per-frame crop. Normal idle frames regain their lower torso and forearms. The tabletop is behind the seated character, with props and the cabinet in front; visible hands remain clickable.

New collar-clearance, layering, and hand-hit checks failed before their fixes. Core, desktop, view, real-window integration, build/startup, and clean-extraction startup checks pass. Inspected all frames plus the before/after render in `.scratch/desktop-pet/idle-layer-comparison.png`. Version 0.1.14.0 is in `dist/DesktopPet/DesktopPet.exe` and `dist/DesktopPet-Windows-x64-0.1.14.zip`; generic ZIP refreshed. SHA256: `717E29E200AB153669D570DD2322AB9082821C4F5EDD5B087958AEF81E1CA563`. Sprite assets and the existing running instance remain unchanged.

## Follow-up 0.1.15 — keep male damage frames at idle size

Preserved the user-approved idle pose and corrected the smaller artwork within damage frames 16–27. Each damage frame receives a cached uniform scale based on the continuous head/torso silhouette, anchored at the existing desktop baseline and body center. Idle/smoking and full terminal frames retain their prior proportions; PNGs are unchanged.

All 12 frame-size regressions failed before the fix (77–88% of idle height). Frame-size, idle-preservation, attack-playback, persistent-injury, and all prior view tests now pass, alongside core/desktop tests, real-window integration, full build, and clean-extraction startup checks. Inspected the full gallery and `.scratch/desktop-pet/hit-size-comparison.png`. Version 0.1.15.0 is in `dist/DesktopPet/DesktopPet.exe` and `dist/DesktopPet-Windows-x64-0.1.15.zip`; generic ZIP refreshed. SHA256: `C807BEB6F129A9DB6F67DC17AD27096B4A61C567AE22B9A3DB5D97202160CD9C`.

## Follow-up 0.1.16 — female coffee arm attachment

Following the female 32-frame addition, the user reported detached coffee and limbs. Normal idle had hidden the articulated arms and painted an unattached coffee fragment into body frames. It now holds the approved clean torso and animates connected shoulder/elbow/wrist chains using existing sleeve and hand textures. One cup follows the wrist through an eased pickup, mouth contact and return to the desktop. Hits interrupt the sip, and role/stage transitions hide the idle rig. Male frames and all source PNGs are unchanged.

Nine failing-first regression checks now pass, including full-cycle continuity and scaled hand/cup/mouth contact. Core, desktop, view, female idle, female asset, real-window integration, build and clean-extraction startup checks passed. Rendered evidence and package details are in `docs/qa/2026-09-19-female-coffee-rig.md`; task 13 is complete. Version 0.1.16.0 is in `dist/DesktopPet/DesktopPet.exe` and `dist/DesktopPet-Windows-x64-0.1.16.zip`; generic ZIP refreshed. SHA256: `B98999374CCE0D4F3D201EAF30EC8E100770D2EE7A038FF8F3ECB94E38F669B0`.

## Follow-up 0.1.17 — keep female arms during hits

Fixed the previous coffee guard hiding both arms during attacks and all seated injury stages. Arm visibility now covers female stages 0–3 independently of sipping. Shoulder anchors follow the current frame and wrists move with hip recoil; the cup stays on the desk. Terminal frames retain their own arms without an extra overlay.

The expanded regression first failed all 64 attack combinations plus injured resting visibility, then passed after the fix. Core, desktop, view, female idle/assets, real-window integration, full build and fresh-extraction startup all passed. Inspected hit/critical-hit captures across all five stages. Task 14 is complete; QA is in `docs/qa/2026-09-19-female-hit-arms.md`. Version 0.1.17.0 is in `dist/DesktopPet-0.1.17/DesktopPet.exe`; the generic executable/ZIP are updated. Versioned ZIP SHA256: `A1B0C304B38DD86C8F7231C21EE80028928CC05EF1C426EAC6717618C04A8257`.

## Follow-up 0.1.18 — smooth attack motion

Replaced the instantaneous contact recoil with eased onset/recovery, held the pre-hit frame until contact, and stabilized reaction-to-rest transitions. Both weapons now visibly withdraw; critical recovery fills its original 0.7-second duration. Female coffee interruption follows a curved hand transition, and male idle timing restarts after a hit to avoid returning to a raised smoking pose. Damage, queue behavior and action durations are unchanged.

All 128 motion cases pass, alongside prior arm/coffee, core, desktop, view, asset, real-window integration, full build and fresh-extraction startup checks. Contact angle discontinuity fell from 0.08 to 0.000117 radians. Before/after renderer captures and metrics are in `docs/qa/2026-09-19-attack-motion.md`; task 15 is complete. Version 0.1.18.0 is available in `dist/DesktopPet-0.1.18/DesktopPet.exe`, with generic outputs refreshed. ZIP SHA256: `0A69F10492AC7C47BA087DBF424094CA5E6AC0D1BB980035E8C378396D4A48B7`.

## Follow-up 0.1.20 — pixel menu, settings theme and hover actions

The root context menu is grouped into 角色 / 工具 / 显示 / 桌宠 on the bundled Fusion Pixel font, and middle-click recovers the selected leader only on a visible pixel. The quote-and-volume settings window was rebuilt to the user-approved v3 composition: a 48px ink header bar with gold 20px text, a cream content surface, a warm bordered filter panel, one outer scroll holding the whole page, quote rows with 66px coral stage tags and a gold selected row, teal 2px-bordered action buttons with 3px pixel shadows (coral for delete), a 2px dashed volume rule with a 12px warm track and coral square grabber, and a single 10px vertical scrollbar with a warm track and coral grabber. The approved design spec supersedes the earlier 56×56 / three-frame cursor metrics.

The hover weapon cursor now keeps the OS pointer on a fixed (36, 36) hotspot inside a transparent 72×72 canvas and loops five cached frames per weapon at 100ms per frame. Frames are generated once per weapon by nearest-neighbour inverse sampling that applies the approved rotation, mirroring and translation; the glove impact frames are exact mirrors about the hotspot axis. Hovering allocates no images, and hover exit, menu open, settings open and dragging still restore the system cursor.

New cursor and settings-theme regressions in `tests/test_desktop.gd` and `tests/test_app.gd` failed on the previous 56×56 three-frame cursor and the dark settings form, then passed. Core, desktop, view, female-idle, attack-motion and the real-window app suite pass; rendered reference captures are `.scratch/desktop-pet/settings-top.png` and `settings-bottom.png`. Version 0.1.20.0 is packaged as `dist/DesktopPet-Windows-x64-0.1.20.zip`; ZIP SHA256: `98FFD764595E74DA1D1651BA46A5E90FDA3CC99BC7D6DA998594A2DD37DBD186`. Two review passes tightened the cursor assertions (unique per-frame position and rotated shape, exact mirror pairs, impact frames covering the hotspot), removed the trailing row separator, corrected the action-button shadow to a zero-spread 3px block, and confirmed the scale submenu is parented to the root menu and can open.
