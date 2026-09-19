# Bundle the pixel UI font, a shared theme module and precomputed cursor frames

Status: accepted, 2026-09-20

The context menu, the quote-and-volume window and the notice dialog were each styled inline with `SystemFont` and hand-built `StyleBoxFlat` values, so colors, borders and metrics drifted between surfaces and the shipped look depended on fonts installed on the machine.

Bundle `assets/fonts/fusion-pixel-12px-proportional.ttf` (Fusion Pixel, OFL-1.1) and keep every palette color, stylebox factory and generated pixel icon in one `src/pet_theme.gd`. The root menu, scale submenu, settings window, speech bubble and notice all read that palette; the settings window receives one `Theme` from `PetTheme.build_settings_theme()` instead of styling each control by hand. The hover weapon cursor is precomputed once per weapon into five transparent 72×72 textures by nearest-neighbour inverse sampling of the approved rotation, mirror and translation tuples, then swapped every 200ms around a fixed (36, 36) hotspot.

The tradeoffs are a 7 MB font in the repository and in the portable package, and a theme module that must grow a helper for each new control surface — a general theme framework was deliberately out of scope. Frame generation costs about 52k samples on the first hover per weapon and nothing afterwards; it avoids a second always-on-top overlay window and keeps the OS pointer as the real input cursor, so the art moves while the click position stays honest.

References: `docs/superpowers/specs/2026-09-19-pixel-menu-and-hover-design.md`, `docs/superpowers/specs/2026-09-19-settings-theme-and-hover-actions-design.md`, [Fusion Pixel font](https://github.com/TakWolf/fusion-pixel-font).
