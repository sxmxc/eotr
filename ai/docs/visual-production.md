# Visual production overhaul — 2026-10-18

Unchecked items are unfinished. This initiative supersedes the collage art direction
in `rift-overhaul.md`; character illustrations and gameplay remain authoritative.

- [x] Audit card definitions, shared UI, grid, terrain, shaders and feedback.
- [ ] Generate five independent illustrations and inspect in rendered card UI.
- [ ] Replace environmental atlas without changing 32 × 32 hex geometry.
- [ ] Replace all 29 illustrations; remove obsolete card compositor.
- [ ] Fix verified shader/effect defects and polish event feedback.
- [ ] Exercise actual combat, collapse, overlapping effects and AutoWalker.
- [ ] Review native captures, resource validation and performance limitations.
- [ ] Finish cleanup, journal and progress records.

## Direction and inventory

Original hand-illustrated fantasy scenes, dark outlines, controlled shading,
teal clothing, ivory mask, brown equipment. Cyan is focused magic, gold is
resources/energy, plum is corruption. Distinct perspectives, settings and actions;
existing character masters serve as design references only. No sprite collage.
Each card uses a 592 × 396 WebP in a 148 × 99 shared CardVisuals viewport.
Hand, popup inspection, rewards and deck share that scene. Costs/layout unchanged.
Per-card mechanics, concepts, production and validation live in
`visual-card-inventory.json`.

Terrain: `assets/rift/terrain/hex_atlas.png`, 128 × 64, four columns/two rows,
32 × 32 pointy hexes. `game_board.tres` preserves atlas IDs, navigation, collision,
custom data and coordinates. RESOURCE (0,0), CORRUPTED (1,0), RIFT_GATE (2,0),
MANA_WELL (3,0), ANCIENT_RUIN (0,1), depleted (2,1), highlight (3,1).
ProcGenTilemap owns terrain/resources/fog/collapse; presentation must read it.
Resource counts already use separate UI. Target highlights are separate meshes.
Fog uses another TileSet and a noise shader. No new terrain mechanics needed.
Character textures are 512-square, with bounded silhouettes and grounded shadows;
retain artwork/footprints. The existing native capture runner exercises shared UI.

## Feedback audit

CardResolver/CardFxRunner sequence projectiles before authoritative effects.
Projectile timeout and completion guard exist; preserve them. VisualFX subclasses
own short-lived particles, sprite animations and tweens. Damage profiles distinguish
block and health damage; Utils.shake already cancels old tweens and restores origins.
Enemy/player death, movement and collapse use existing animations. Obelisk summons
are synchronous gameplay and may receive cosmetic feedback only after placement.
AutoWalker changes engine time scale; existing tweens/particles inherit it.
No AnimationTree found in first-party combat. AnimationPlayer remains appropriate
for card transitions, tile collapse and shield shine. Audio stays with existing
effect/card/action owners; avoid duplicate sounds or gameplay RNG for cosmetics.

Verified issues to address:

- ElectricArcFX builds global points on a local Line2D, hardcodes player as origin,
  writes shared material state and adds its own large shake on top of card impact.
- Arc wrapper survives after its child line frees. Shield shine hides a child but
  never frees its root. Spark uses 500 primary + 100 secondary particles, with a
  large visibility rectangle and long tails for a small single hit.
- Target shader uses a regular-hex slope unlike the board's actual pointy shape;
  declared min/max alpha and highlight alpha are ignored.
- White flash shader discards node fade modulation. Highlighter uses straight
  blend mode with premultiplied RGB and can take sqrt of a negative edge gradient.

All shader files and material consumers are recorded in the audit inventory.
Working noise fog, burn, vignette and specialized outline/aura effects should be
retained unless actual validation reveals a defect. No global postprocess added.

## Validation record

Pending. Static/headless checks do not establish visual quality or frame rate.
