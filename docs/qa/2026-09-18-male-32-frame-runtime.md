# Male 32-frame runtime animation

## Scope

The approved 16-frame idle/smoking sheet and 16-frame damage/terminal continuation are normalized into 32 transparent 160×180 textures. The boss sprite stays attached to the existing `hip` bone; external hammer and glove attacks remain separate weapon animation layers.

## Verification

- `tests/test_core.gd`: passed.
- `tests/test_desktop.gd`: passed.
- `tests/test_view.gd`: passed, including all 32 frame assets, idle frame advancement, sustained hit-frame selection for stages 1–3, terminal frames, hit recoil, and both character rigs.
- `tools/build.ps1`: passed import, export, native startup probe, and portable ZIP creation.
- Exported EXE version info: `Beat the Little Boss`, `0.1.8.0`.
- Portable ZIP SHA256: `6F02717BC4CD20893DAC5E723AB1DEF03903CBE986B7BE61BAD3FBE25544C903`.
