# Rebuild the male leader and desk layering
Status: ready-for-agent

The 0.1.10 region crop removed the body leak but still made the male leader look like a large head placed behind an unrelated desk. The approved design requires a single coherent desk scene using the existing 32-frame leader identity.

## Acceptance

- Reuse the existing 32-frame male leader textures; do not replace the character appearance with generated art.
- Show the full head, shoulders and upper chest behind the desk at a stable scale and baseline.
- Render connected hands on the keyboard layer, retain the smoking pose, and keep the desk as a complete foreground cabinet.
- Place the coffee cup at `(127, 118)` with its bottom at the desk edge.
- Preserve the female leader and full male terminal kneeling scene.

## Comments

2026-09-18: User approved the three-layer relationship and the coffee-cup placement in the visual companion. The design is recorded in `docs/superpowers/specs/2026-09-18-male-layered-desk-redesign.md`.
