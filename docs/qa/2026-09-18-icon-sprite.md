# Icon sprite follow-up

## Scope

The male pet now uses the boss character from the application icon as a transparent upper-body sprite. The generated source includes a desk for reference; the runtime asset keeps only the character and reuses the existing desk, chair, weapon, and foreground layers.

## Verification

- `tests/test_core.gd`: passed.
- `tests/test_desktop.gd`: passed.
- `tests/test_view.gd`: passed, including male icon visibility/hit testing, female rig visibility, both weapons, both directions, critical hits, and terminal collapse.
- `tools/build.ps1`: passed import, export, native startup probe, and portable ZIP creation.
- Exported EXE version info: `Beat the Little Boss`, `0.1.7.0`.
- Portable ZIP SHA256: `4BECE69E86BF653CCCFEECA570856ECA88C63C6860B9B88B319D3068894EF2A9`.

The headless app integration script still reports environment-specific native-window flag mismatches and is not part of the export gate; the real startup probe used by the build passes.
