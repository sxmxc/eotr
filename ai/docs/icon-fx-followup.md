# Icon, route and complete effect follow-up — 2026-10-18

The previous production pass fixed technical defects but left visually mismatched
stock spell art and the old icon hover aura. This follow-up completes that review.

- [x] Identify legend mappings, HUD inconsistency and premature route label.
- [x] Replace icon hover expansion with native, theme-authored color feedback.
- [x] Bind every legend row to the map's shared icon mapping, including events.
- [x] Match resource icon to crystal deposits; normalize HUD icon sizes and clock.
- [x] Replace incompatible stock spell animations with reference-guided illustrated FX.
- [x] Review all first-party particle, impact, ward, movement, death and collapse uses.
- [x] Validate icon hover, route entry, all effect families and gameplay.
- [x] Remove superseded assets/materials only after complete reference checks.

New raster effects use the approved Arcane Bolt and original Riftwalker as explicit
style references: broad expressive ink contours, simplified cel shading, restrained
detail. Cyan arcane energy, plum hostile corruption, ochre fire and gold restoration
remain distinct. Assets live in the repo and use native SpriteFrames/AtlasTexture
or existing GPU particles. Gameplay effects, damage and RNG remain authoritative.

Eight transparent 4-by-2 sheets supply 64 illustrated frames: cyan and plum
projectiles, gold restoration, ochre fire, corruption mist, impact dust, ward
shell and claw strokes. Four extracted frames provide native GPU particle
textures. `illustrated-fx-sources.json` retains the exact prompts and source paths;
`prepare_rift_art.py SOURCE KEY fx` packages sheets and particle extracts. No
character cutouts, photorealistic lighting or unrelated stock spell imagery.

New assets must follow the approved Arcane Bolt illustration's visual language.
Always include it and the original Riftwalker as explicit references when creating
raster assets. Preserve dark contours, simple readable shapes, controlled shading,
restrained texture and the cyan/plum/gold/ochre palette. Judge the result at its
actual gameplay size before extending it. Card scene composition remains unique
to each card and must survive its 148-by-99 art viewport.

Fixed presentation stays in the existing scenes and shared theme. Icon hover now
uses `ThemedIconButton` to bind theme colors without expanding or duplicating the
texture. Map legend rows use the exact MapNode theme mapping, including Event;
route selection displays Entering rather than prematurely Cleared. The HUD's
resource icon depicts the same crystal cluster as terrain; clock and health use
consistent logical sizes. Selection uses a hand-illustrated cyan energy marker
in `assets/rift/fx/target_ring.webp`, generated with the approved references.
The rejected smooth-arc/diamond SVG was removed. Its replacement uses tapered
inked ribbons, controlled shading and a transparent center, scaled to the unit's
hex; it is not an unrelated HUD glyph.

Electric arcs use an ink/core shader on native Line2D geometry. The fade now uses
float endpoints; integer tween endpoints caused a sudden step instead of a fade.
Projectile charge completion cannot restart a loop after impact. Obelisk shots use
world coordinates and no longer take over the camera. Effect roots release after
playback; the player's persistent ward hides and can replay. Enemy death uses two
brief layers; restoration uses 24 particles, impacts 12, summoning 8, treasure
4-by-12. The earlier full shader inventory is updated in
`visual-effects-inventory.json` with explicit retained/replaced decisions.

Removed 67 superseded files and import/UID sidecars after path and UID checks:
old hover/ward materials and shaders, per-effect legacy scripts, unused template
scenes and stock spell/confetti/selection textures. The inventory records every
removed path. The first production pass already removed `assets/card` frame
dependencies; `CardVisuals` and the shared theme remain the single card renderer.

Validation: Godot 4.7.2 native UI and combat suites pass, as do headless combat,
art/reference checks and scene resource checks. Regression checks cover legend
mapping, repeated bounded hover, Entering state, effect cleanup, overlapping
particles, all four projectile families, continuous arc fade and persistent ward
replay. Native captures are under `qa/compatibility-validation/overhaul-fx-*.png`,
`overhaul-legend.png` and `overhaul-icon-hover.png`.

Offline AutoWalker seeds 731–733 completed three encounters (one win, two losses)
with zero invalid actions, softlocks, timeouts or harness failures; four summons.
Seed 731 also completed a rendered 12-turn victory. Existing AI fallback counters
were 7 across the batch and 3 in rendered play; these are not a new FX behavior.
No online telemetry was sent. This validates the changed presentation and turn
flow, not full-campaign balance, exports or other graphics hardware. Windows
certificate-store diagnostics remain environment-specific.
