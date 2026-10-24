# Card expansion and act-boss presence

## Discovery and invariant contracts

CardUI → CardInteractionController → Card.play → CardResolver → existing
effects is the execution path. Standard effects are serialized on each card resource; conditional cards have
individual scripts beside their resources. SummonHandler still owns constructs.
ProcGenTilemap remains the only occupancy owner. Footprints use relative cube
coordinates, retain one health/status identity, and reserve both movement ends.
Phantom Camera remains the only camera authority. Costs, provenance, seeded RNG,
hand/exhaust ownership, boss rewards and elimination victory remain authoritative.

Baseline: `.qa-tmp/visual/expansion-bulwark-before`, seed 1, greedy, eight seconds,
native Godot 4.7.2, stills only. Frame 02 was inspected: Bulwark's silhouette is
roughly player-sized beneath a dominant health meter. Its exposed state is visible.
This is source evidence for scale, not evidence of continuous animation or audio.

## Required reference ownership

Style: `assets/rift/cards/arcane_bolt.webp` and the approved prompt constraints in
`ai/visual/reference/visual-card-prompts.json`. New compositions must read within
148 × 99 pixels, use simple inked planes and subdued backgrounds, and preserve
the full 3:2 composition through existing art packaging.

Riftwalker identity: `assets/rift/entities/riftwalker.webp` and
`assets/rift/source/riftwalker.webp`. Teal hood/sleeves, tapered ivory mask with
long eye openings, brown gloves/boots, brass clasp. Check shoulder–elbow–wrist
continuity and thumb orientation. The initial Cash Out hand was rejected by the
user; a near-identical correction is insufficient and must not be accepted.

Synthforged identity: `assets/rift/source/synthforged.webp` and its entity master.
Use the existing card reference appropriate to the action: `field_repairs.webp`,
`fire_command.webp`, `deploy_sentry.webp`, or `reserve_capacitor.webp`. Preserve
the angular ivory helmet, cyan slit within black faceplate, ivory plates, dark
articulated limbs, brass round bearings and black mechanical fingers. Reference
the actual `synthforged_pike.webp` / `synthforged_sentry.webp` construct when present.
The first Synthforged batch omitted its character reference and is rejected.
Do not bind those images as finished artwork. Corrected images must be inspected
before expanding the replacement batch.

Boss identity: use the original `bulwark.webp`, `spectre.webp`, `obelisk.webp`
alongside card style. Spectre retains its teal torn hood, hollow ivory mask,
cyan chest core and plum spectral lower body. Reject the horn-bearing variant:
it invents an accessory and loses this identity. Core may broaden its stone
structure, retaining the dark fractured stone, brass restraints and plum fissure.

## Boss direction

Bulwark: broad low armored wedge, three-cell body, fixed swept ram lane. Telegraph
every threatened footprint cell and stop at first collision. Closed space and
recovery create the arc. Amber tread stays distinct from quiet occupied-cell ink.

Spectre: tall mobile apparition, one mechanical cell because the existing
Memory Anchor supplies the spatial dependency. Larger authored spectral silhouette
with the existing chorus echoes and reap journey. No invented body parts or phase.

Core: broad stationary three-cell siege mass; relays remain separate actors.
Lit link and transfer retain the existing counterplay. Do not imply the crystal
has individually damageable parts. Collapse on any body cell is lethal, as for
other actors; no environmental immunity.

Native AnimationPlayer supplies arrival, restrained idle, windup and release.
It animates Sprite2D only; root position, occupancy and action completion are
never cosmetic callbacks. Existing hit/death feedback remains, and presentation
stops on death. Grounded mass comes from silhouette and bounded settling,
not extra particles or screen shake. Contact anchors move to the authored body.

## Acceptance evidence

Inspect source illustrations at full size and card viewport size, with anatomy,
character/construct identity, silhouette, mechanic and composition checked per
asset. No blanket approval from generation or packaging success.

Capture actual CardUI plays for all new identities using controlled legal setup
through existing APIs, asserting outcomes separately from captures. Show shared
eligibility through actual reward/shop consumers for both classes. Capture all
three bosses at normal framing, ram telegraph/movement and footprint targeting.
Test hidden-anchor/visible-body targeting, blocked footprint destinations, odd/even
column translation, AoE once per entity, collapse of a non-anchor body tile,
death cleanup and remaining-relay victory. Review native PNGs and timing records;
continuous motion/audio remain unverified unless reviewed directly.
