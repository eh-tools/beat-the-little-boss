# Pixel menu, settings, and hover interaction redesign

Date: 2026-09-19
Status: ready-for-user-review

## Goal

Make the desktop pet's first-level menu, settings window, speech UI, and hover weapon feedback read as one pixel-art interface. Reduce menu clutter, remove the settings window's double vertical scrolling, add a middle-click recovery shortcut, and make the hover weapon feel alive without affecting attack animations.

## Visual direction

- Bundle `assets/fonts/fusion-pixel-12px-proportional.ttf`, extracted from the official `TakWolf/fusion-pixel-font` release archive `fusion-pixel-font-12px-proportional-ttf-v2026.09.01.zip` at `https://github.com/TakWolf/fusion-pixel-font/releases/tag/2026.09.01` (release commit `51c6d2d`). Load it as a Godot `FontFile` resource rather than relying on Windows font availability.
- Use integer font sizes, nearest-neighbor rendering, and the existing palette: `#fff4d9` cream surfaces, `#303247` ink, `#ffe1a6` hover/selection, `#e79777` coral accent, and `#95e0d0` confirmation accent.
- Apply the same font and palette to `PopupMenu`, the quote settings window, speech bubbles, and notices. Keep the existing pixel art and transparent desktop-window behavior unchanged.
- Include the font's OFL-1.1 license text at `assets/fonts/LICENSE-OFL`, and add this attribution to `THIRD_PARTY_NOTICES.md`: `Fusion Pixel Font 12px proportional by TakWolf and upstream contributors, from TakWolf/fusion-pixel-font release 2026.09.01, commit 51c6d2d; licensed under SIL Open Font License 1.1.` Remove the current notice that says no UI font files are redistributed.

## Menu hierarchy

The root context menu is reduced to four labeled groups, in this exact order:

1. `角色`: `男领导 · 甩锅担当`, `女领导 · 画饼专家`.
2. `工具`: `充气大锤    1`, `双拳套        2`.
3. `显示`: `放大比例` submenu with `原始大小 · 1 倍`, `放大 · 1.5 倍`, `放大 · 2 倍`, followed by `总在最前` and `播放音效`.
4. `桌宠`: `语录与音量设置…`, `恢复当前领导（中键）`, `全部恢复正常`, `隐藏到任务栏`, and `退出`.

Each group is introduced by one labeled separator; there are no unlabeled separators between individual actions. `语录与音量设置…` is one root item that opens the settings window.

The root menu keeps only actions that are useful for quick switching. Scale choices are a small submenu. Quote editing and volume controls remain in a dedicated second-level settings window, but it uses the same pixel theme as the root menu.

## Settings window layout

Use exactly one outer `ScrollContainer` for the complete settings page. Replace `ItemList` with a non-scrollable `VBoxContainer` of selectable row controls inside that same content flow; no child control may own a vertical scrollbar. The page order is:

1. title and short explanation;
2. character and quote-category filters;
3. selectable quote rows;
4. quote editor and row actions;
5. sound toggle and volume slider;
6. import/export/default actions;
7. close and save actions.

Rows must make their category/stage tag visually distinct from the quote text. The selected row uses the existing gold/coral selection treatment. Empty categories and validation messages keep the current behavior.

## Recovery interaction

Middle-clicking a visible hit-test pixel of the current leader resets only the selected leader's session state. It is ignored while the context menu or settings window is visible, while a drag is in progress, and when the click is outside `hit_test`. Recovery cancels the selected leader's active attack and queued attacks, clears its bubble and critical feedback, refreshes the view, and persists no session progress (session state is intentionally ephemeral). The root-menu action `恢复当前领导` uses the same behavior. A separate explicit root-menu action `全部恢复正常` keeps the existing all-leaders reset behavior.

## Hover weapon motion

Keep the OS cursor as the input cursor, but rotate through three precomputed pixel-safe cursor textures while hover is active. The source weapon textures are both 48×48; each cursor frame is 56×56 with the source placed inside a 4px transparent margin. The hotspot is always `(28, 28)`. On hover entry, time starts at `t=0` with frame 0. Use a 120ms cadence and ping-pong sequence `0 → 1 → 2 → 1`: frame 0 for `0 ≤ t < 120ms`, frame 1 for `120ms ≤ t < 240ms`, frame 2 for `240ms ≤ t < 360ms`, frame 1 for `360ms ≤ t < 480ms`, then repeat. Hammer source offsets are `(0, +1)`, `(0, 0)`, `(0, -1)`; glove source offsets are `(-1, 0)`, `(0, 0)`, `(+1, 0)`. Reuse the selected weapon. Stop the animation and restore the system cursor on menu open, drag, settings open, or hover exit. Attack animation state remains owned by `PetView` and must not be interrupted by hover frames.

## Boundaries and verification

- Keep menu construction and input routing in `src/main.gd`.
- Keep quote editing and settings layout in `src/settings_window.gd`.
- Keep hover-frame generation and hover state in `src/pet_view.gd` or a small adjacent utility only if the existing file boundary becomes unsafe.
- Add tests for the exact root menu group/item order and scale submenu, bundled font loading, the exact count of one `ScrollContainer` and zero nested vertical scrollbars, middle-click recovery/cancellation, and hover-frame changes at `t=0`, `120ms`, `240ms`, and `360ms`. The tests must inspect this acceptance table:

| Surface | Font | Size | Required colors/layout |
| --- | --- | --- | --- |
| Root menu | bundled `FontFile` | 16px | panel `#fff4d9`, ink `#303247`, hover `#ffe1a6`, coral border `#e79777`, 2px outer border, 6px corner radius |
| Scale submenu | same `FontFile` | 16px | same panel/hover/ink theme and one submenu level only |
| Settings window | same `FontFile` | 16px body, 24px heading | one outer `ScrollContainer`, no nested vertical scrollbar, gold selected row, coral action border |
| Speech bubble | same `FontFile` | 14px body, 18px critical label | panel `#fff4d9`, border/ink `#303247`, critical gold `#ffe491`, critical outline `#553447` |
| Notice dialog | same `FontFile` | 16px | cream `#fff4d9` surface, ink `#303247`, coral error text `#ffd2a6`, no font fallback |
- Run core, desktop, view, female-idle, attack-motion, and app integration tests where the display server supports them; run a Windows export check for the bundled font and application resources.

## Non-goals

- No redesign of the leader artwork or attack choreography.
- No persistent session-progress storage.
- No general settings framework or new third-party runtime dependency beyond the font resource and its license notice.
