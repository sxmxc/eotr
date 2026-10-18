# Visual production overhaul — 2026-10-18

Unchecked items are unfinished. This initiative supersedes the collage art direction
in `rift-overhaul.md`; character illustrations and gameplay remain authoritative.

The later icon/FX follow-up replaces the stock spell art and hover aura retained
by this initial pass. See [icon-fx-followup.md](icon-fx-followup.md) for the final
style requirements, effect inventory, cleanup and validation.

- [x] Audit card definitions, shared UI, grid, terrain, shaders and feedback.
- [x] Generate five independent illustrations and inspect in rendered card UI.
- [x] Replace environmental atlas without changing 32 × 32 hex geometry.
- [x] Replace all 29 illustrations; remove obsolete card compositor.
- [x] Fix verified shader/effect defects and polish event feedback.
- [x] Exercise actual combat, collapse, overlapping effects and AutoWalker.
- [x] Review native captures, resource validation and performance limitations.
- [x] Finish cleanup, journal and progress records.

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

29/29 independent illustrations shipped at existing canonical references, including
the two common burden cards. The user approved regenerated Arcane Bolt as the
primary style reference. Subsequent generations received that complete image and
original Riftwalker/Horror/Blob designs as explicit image references. Cinematic
first attempts were rejected. Each finished image was generated separately from
actual mechanics and packaged by full-frame downscaling, without sprite collages.
Prompts, sources, mechanics, concepts, unique hashes and per-card validation are
in the adjacent `visual-card-*.json` inventories. Runtime uses only repo assets.

The new atlas depicts slate slabs, ochre crystal deposits, branching plum
contamination, cyan fissures/pools, depleted sockets and crumbling stone.
Packaging retains the exact previous alpha mask, cell addresses and dimensions.
TileSet collision/navigation and authoritative board behavior are untouched.
Opaque fog now uses compatible slate blue rather than pale brown. Resource counts,
legal targeting and collapse contours continue to read existing state. Background
stars are dimmed; original character artwork and footprints are preserved.

18 shaders/VisualShaders audited, 12 retained and 6 unreferenced variants removed.
Fixed arc uniform casing, local/world coordinates, material sharing and wrapper
lifetime; reduced its width from 200 to 3 world pixels and removed duplicate shake.
Hit flashes/outlines preserve tint/fades; targeting matches actual hex geometry.
Shine uses straight alpha, isolated materials and its owner's texture, then frees
its root. Vignettes guard zero radius/speed and invalid smoothstep edges. Working
specialized fog/burn/outline implementations remain. See the effects inventory.

Movement leaves a brief bounded departure echo. Teleport previously faded the
non-drawing parent Node2D; it now fades the actual sprite and relocates while
hidden. A 14-particle wisp marks an actual Obelisk summon after authoritative
placement. Cosmetic playback does not gate combat logic. Existing damage/death,
audio, block/status, camera and collapse systems remain. No gameplay RNG, AI,
targeting rules, balance, encounters or mechanics were changed.

Native Godot 4.7.2 Forward+ compatibility passed. Inspected 1920 × 1080 captures
of all 29 cards in production CardPileView (three pages), five-card battle hand,
hover/inspection, reward selection, targeting, fog and collapse warning states.
The actual battle scene exercised two overlapping arcs, shield shine, sixteen
simultaneous impacts and a summon wisp; every transient root released. Headless
compatibility/combat checks passed, including editor-authored face-style recovery.
Artifacts: `qa/compatibility-validation/overhaul-*.png`,
`qa/visual-complete-native.log`, `qa/visual-complete-headless.log`, and
`qa/visual-complete-overlap.log`.

Offline AutoWalker seeds 731–733 completed three real encounters: 99 card plays,
14 enemy deaths, eight collapses, four summons and one Obelisk destruction.
Native Watch seed 734 completed another encounter with two summons. Both summaries
report zero simulation failures, invalid card actions, softlocks and timeouts.
Existing enemy AI recorded seven fallback decisions in the headless batch and one
in Watch; AI was not changed. Reports: `qa/visual-final-autowalker/` and
`qa/visual-final-rendered/`.

Impact allocation fell from 700 particles across three emitters to 32 in one.
Sixteen simultaneous bursts allocate 512 particles, plus 14 for the summon fixture;
all 17 particle roots released. Per-card trails fell from 5,000 particles to 128
with 0.35-second lifetime. No hardware FPS improvement is claimed: offscreen native
captures and bounded overlap checks are not a shipping performance benchmark.
Known Windows certificate-store and Godot shader-debug sampler diagnostics remain
in logs. Broad hardware profiling, full campaign and export QA were not performed.

Removed the old card compositor, symbol-painted terrain generator, shared arena
background, six unused shader variants and dead spark resources. Retained existing
menu/variant packaging in `tools/build_rift_presentation.py`, which cannot write
card illustrations. No rejected generated intermediates were added to the repo.

## Card frame authoring and legacy asset cleanup

There is one shared renderer: `ui/card_ui/card_visuals.tscn`, used by hand and menu
cards. Layout belongs in that scene; face/cost/rarity surfaces and interaction
styles belong in `resources/themes/rift_ui.tres`. Scripts bind card data and select
authored state variations; they do not build a second card frame system.

Removed four unused old texture declarations, the old rarity bitmap, empty
foreground/outline controls, unused local styles, and all six image sources/import
sidecars under `assets/card/`. No runtime reference to that folder remains.
Rarity uses the shared CardRarityMark style. Normal state preserves the face
variation authored on CardBackgroundTexture; hover/modified styles are Inspector
exports. A regression check verifies returning from hover honors scene styling.
Edit the shared scene and theme directly; old frame PNGs are unnecessary.
