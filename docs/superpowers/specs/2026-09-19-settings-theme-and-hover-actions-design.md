# Settings theme parity and hover attack actions

Date: 2026-09-19
Status: user-approved visual direction

## Goal

Correct two regressions in the current pixel-menu implementation:

1. Make the quote-and-volume settings window look like the approved `menu-layout-v3.html` companion instead of a dark Godot system form.
2. Replace the nearly static hover cursor offsets with readable weapon actions: a hammer strike for the inflatable hammer and alternating left/right hooks for the glove.

The user approved visual-companion option A: strong, readable motion on a fixed cursor hotspot. The durable visual reference is `docs/superpowers/specs/assets/settings-theme-hover-actions-approved.html`; it uses the repository font and weapon assets through relative paths and is the appearance source of truth for this change.

## Settings window visual contract

The existing root context menu remains unchanged. The settings window must use the same bundled Fusion Pixel font and palette as that menu:

- ink `#303247`;
- cream `#fff4d9`;
- gold `#ffe1a6`;
- coral `#e79777`;
- teal `#95e0d0`;
- warm control surface `#fff9e8`;
- filter panel `#f3dfb6`;
- secondary border `#d4a476`.

The native window remains 620×660 with a 570×610 minimum size, and its title becomes `语录与音量设置 · Beat the Little Boss`. Inside the native window, the complete settings page follows the approved v3 composition:

1. an ink header bar with gold `语录与音量设置` text;
2. a cream content surface;
3. muted `QUOTE WORKSHOP` eyebrow, 24px ink heading, and compact description;
4. role/category filters grouped on the warm filter panel;
5. cream quote rows with a fixed-width coral stage tag, ink text, ink border, and gold selected state;
6. cream text entry and consistently styled stage selector;
7. teal primary/action buttons with 2px ink borders and a 3px pixel shadow; destructive delete uses coral;
8. a warm-tan volume track with coral fill/grabber and an ink audio toggle;
9. import/export/default actions and close/save actions in the same visual language.

Exact layout metrics:

- the single outer scroll fills the client area and contains the entire page;
- the ink header is 48px high with 16px horizontal padding and 20px gold text;
- the cream content area uses 24px left/right, 20px top, and 18px bottom padding with 12px vertical spacing;
- the eyebrow is 14px, heading 24px, description 16px, and body/control text 16px;
- the filter panel has a 2px secondary border, 9px inner padding, 9px column gap, and two equal-width controls;
- filter, input, selector, and action controls are at least 38px high with 2px ink borders;
- the quote list has a 2px ink outer border and no spacing between rows; rows are at least 38px high with a 2px warm separator;
- each quote tag is 66px wide, coral, centered, and separated from the cream quote text by a 2px ink border;
- selected quote text uses a gold background; unselected quote text uses `#fff9e8`;
- action rows use 10px gaps; pixel-button shadows are `(3, 3)` in ink;
- the volume section has a 2px dashed secondary top border and 14px horizontal gaps;
- the volume track is 12px high with a 2px ink border and a 12×12 coral square grabber;
- the only vertical scrollbar is 10px wide, with a warm track and coral grabber.

All text and control dimensions remain integer-valued. Corners are 0–2px for controls and 6px only for the outer panel where appropriate. The window retains exactly one vertical `ScrollContainer`; no quote-list control may create a nested scrollbar. All current editing behavior remains intact: adding, selecting, updating, deleting, validation, import/export, restoring defaults, volume changes, and saving.

The settings theme should be defined through focused helpers in `src/pet_theme.gd` and applied from `src/settings_window.gd`. It must style `OptionButton` and its popup, `LineEdit`, `Button`, `CheckButton`, `HSlider`, separators, and the one scrollbar so no default dark Godot control remains visible. This is not a general theme framework; only helpers required by the current settings window are in scope.

## Hover attack animation

The OS cursor remains the actual input cursor. Its hotspot is fixed at `(36, 36)` on a transparent 72×72 canvas so the pointer does not jump while the artwork moves.

Both weapons use five cached frames at 100ms per frame, looping every 500ms while hover is active. Hover entry always starts on frame 0. Hover exit, menu opening, settings opening, and dragging restore the system cursor exactly as today.

### Inflatable hammer

The five frames read as:

1. ready/wind-up at approximately `-40°`;
2. raised at approximately `-58°` and 4px upward;
3. downward swing at approximately `-15°`;
4. impact at approximately `+34°` and 8px downward, with the hammer head crossing the fixed hotspot;
5. rebound at approximately `-20°`.

### Glove

The single glove source texture is mirrored to create alternating sides. The five frames read as:

1. left wind-up, 15px left at approximately `-18°`;
2. left hook impact near the hotspot at approximately `+8°`;
3. mirrored right wind-up, 15px right at approximately `-18°`;
4. mirrored right hook impact near the hotspot at approximately `+8°`;
5. centered neutral/recovery frame.

`PetView` precomputes the frames from the existing 48×48 weapon textures using nearest-neighbor inverse sampling for rotation, mirroring, and translation. Frames are cached per weapon; no per-frame image allocation occurs during hover. Attack choreography and the visible in-scene weapon rig remain untouched.

The transform convention is exact:

1. Canvas coordinates start at the 72×72 image's top-left; +x is right and +y is down.
2. Angles are clockwise-positive degrees, matching Godot's 2D screen-space convention.
3. For each destination pixel, subtract the frame's destination pivot, inverse-rotate by the frame angle, undo horizontal mirroring around the source pivot when requested, then add the source pivot. Round to the nearest source pixel and copy it when in bounds; otherwise leave the destination transparent.
4. Hammer source pivot is `(24, 40)`. Hammer frame tuples `(angle, destination pivot)` are: `(-40°, (45,58))`, `(-58°, (55,54))`, `(-15°, (42,62))`, `(+34°, (19,61))`, and `(-20°, (46,61))`. The impact tuple places the hammer head over the fixed hotspot.
5. Glove source pivot is `(24, 24)`. Glove frame tuples `(flip_h, angle, destination pivot)` are: `(false, -18°, (20,40))`, `(false, +8°, (34,36))`, `(true, +18°, (52,40))`, `(true, -8°, (38,36))`, and `(false, 0°, (36,40))`. Frames 1 and 3 are the left and right impact poses.

## Boundaries

- `src/pet_theme.gd`: shared palette and small settings-control style/texture helpers.
- `src/settings_window.gd`: settings hierarchy and applying the shared theme.
- `src/pet_view.gd`: cursor frame generation and frame-index timing.
- `src/main.gd`: fixed `(36, 36)` hotspot and existing hover lifecycle.
- No new runtime dependency, artwork file, input behavior, quote model, or attack-state change.

## Verification

Add or update tests that fail on the current implementation and verify:

- the settings background, header, filters, row, input, button, slider, and popup styles use the approved colors and bundled font;
- one outer `ScrollContainer` exists and quote rows contain none;
- add/update/delete/save behavior is unchanged;
- cursor textures are 72×72 and transparent outside their transformed art;
- hotspot remains `(36, 36)` in `main.gd`;
- hammer frame images differ by both rotation and position at indices 0–4;
- glove frames alternate unmirrored/mirrored left and right impacts;
- timing boundaries are frame 0 at 0ms, frame 1 at 100ms, frame 2 at 200ms, frame 3 at 300ms, frame 4 at 400ms, and frame 0 again at 500ms;
- core, desktop, view, female-idle, attack-motion, and app integration suites still pass where supported;
- the Windows portable export contains the revised UI and cursor resources.

## Non-goals

- Redesigning the root context-menu hierarchy.
- Changing the pet's click attack animations or damage model.
- Replacing the native Windows title bar.
- Adding animated sprite assets or a second cursor-overlay window.
