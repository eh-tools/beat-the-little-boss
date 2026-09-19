# Settings theme parity and hover attack actions

Date: 2026-09-19
Status: user-approved visual direction

## Goal

Correct two regressions in the current pixel-menu implementation:

1. Make the quote-and-volume settings window look like the approved `menu-layout-v3.html` companion instead of a dark Godot system form.
2. Replace the nearly static hover cursor offsets with readable weapon actions: a hammer strike for the inflatable hammer and alternating left/right hooks for the glove.

The user approved visual-companion option A at `http://localhost:54030/`: strong, readable motion on a fixed cursor hotspot.

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

The native window title becomes `语录与音量设置 · Beat the Little Boss`. Inside the native window, the complete settings page follows the approved v3 composition:

1. an ink header bar with gold `语录与音量设置` text;
2. a cream content surface;
3. muted `QUOTE WORKSHOP` eyebrow, 24px ink heading, and compact description;
4. role/category filters grouped on the warm filter panel;
5. cream quote rows with a fixed-width coral stage tag, ink text, ink border, and gold selected state;
6. cream text entry and consistently styled stage selector;
7. teal primary/action buttons with 2px ink borders and a 3px pixel shadow; destructive delete uses coral;
8. a warm-tan volume track with coral fill/grabber and an ink audio toggle;
9. import/export/default actions and close/save actions in the same visual language.

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
