# Female 32-frame runtime QA

## Visual review

- Direction reference: `assets/art/female_style_reference.png`.
- Desk composition preview: `.scratch/desktop-pet/female-runtime-preview.png`.
- Inspected at native pixel size and enlarged nearest-neighbor scale: long hair, glasses, teal suit, coffee idle frames, progressive bruising, and a complete kneeling terminal pose are present.

## Automated checks

- `python tests/test_female_frame_assets.py`: passed.
- `tests/test_view.gd`: passed after importing all 32 generated female frames.
- `tests/test_desktop.gd`: passed after the shared-frame code change; it does not consume character art.
- `tests/test_core.gd`: passed after restoring access to the Godot user configuration directory.
- `tools/build.ps1`: passed; imports the 32 new frames, runs core, desktop, and view suites, exports the Windows application, and passes the startup-window probe.

## Environment limits

- Headless Godot did not fire the `RenderingServer.frame_post_draw` continuation in `tests/capture_art.gd`, so the checked-in gallery was not overwritten from this restricted session.
- The earlier restricted-session limitation on Godot editor settings is resolved; the final build imported the female PNGs successfully.
