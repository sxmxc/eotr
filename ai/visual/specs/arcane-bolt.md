# Arcane Bolt: concentrated contact

## Discovery
Actual path: resources/data/cards/riftwalker/arcane_bolt.tres -> CardUI.play -> CardResolver -> scripts/resources/card/card_fx_runner.gd -> electric_arc_projectile_fx.tscn -> spark_fx.tscn -> arcane_hit_signature.tscn. The card deals six damage for one energy. Projectile completion precedes resolution; body anchors and the existing 16-strength / 0.15-second camera impulse remain authoritative. The spark wrapper supplies bounded particles and an illustrated impact. Seed 1, greedy, tier_0_blobs produces Arcane Bolt as its first card at roughly 0.53 seconds.

## Baseline evidence
.qa-tmp/visual/bolt-baseline/capture.avi and frames/02-0.687.png, frames/03-0.917.png inspected as stills. At 0.687 the white/cyan spiral covers most of the Blob silhouette; at 0.917 the body and damage numeral are readable again. Continuous motion and sound have not been inspected. The background, ink-edged character and cyan energy in these native frames are the art references.

## Direction
Communicate a precise arcane hit with a concentrated cyan-white contact accent, allowing the struck creature to remain recognizable. Preserve launch path, particles, contact timing and recovery. Reduce only the illustrated hit layer from 0.30 to 0.21 scale (70% linear size); keep the shader canvas, color, duration and particles intact. This shared contact signature also serves other spark impacts, so this is a narrowly scoped shared presentation change, not an ability-specific mechanical change.

## Acceptance
At matching first-hit phases, cyan/white contact must remain visible while exposing more of the Blob perimeter. Damage text and target highlight must remain legible. Retain duration 0.32 seconds, all costs/damage, source/target relationships and camera impulse. Compare action sequence and terminal observation. Flag unrelated camera/HUD movement or shared-impact coverage limits; do not claim full regression coverage from this sample.
