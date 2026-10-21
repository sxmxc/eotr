# Ruin activation: an echo in broken stone

## Discovery and baseline

ProcGenTilemap.apply_tile_effects -> _trigger_ancient_ruin_effect selects one
RuinTileEffect, executes it and emits its description through WorldMessageData.
BoardOverlay already draws warm broken columns. Ruins remain repeatable; there
is no consumed state. Preserve weights, RNG calls, effect values, start-tile
handling, death cleanup, camera, sound, targeting and turn scheduling.

Native baseline: .qa-tmp/visual/ruin-before, Godot 4.7.2 Forward+, seed 1,
tier_0_blobs, 1920x1080 recorded at 30 fps for five seconds. Inspected
ruin-1-contact.png and ruin-2-rise.png. The illustrated player stands over the
existing gold column landmark. No tile-local activation is visible; the empty
outcome appears in the left message rail. Initial messages compete with the
first activation. These are still observations, not continuous-motion review.

The development-only ruin fixture pauses policy actions, changes the occupied
tile's type, and restricts the effect pool to block then empty before invoking
the real apply_tile_effects API. It does not simulate effects. Native startup
effects still execute normally. This isolates repeat activation, not movement,
targeting, enemies or collapse. timing.json records event and PNG timestamps.

## Direction

Communicate that the occupied ruin responded, including when it grants nothing.
Echo the existing broken-column silhouette in aged gold, briefly lifting five
world pixels and fading within 0.45 seconds. Keep it inside the tile footprint,
behind actor silhouettes; no expanding ring, fullscreen flash, shake or new sound.
The outcome message begins with Ancient Ruin, preserving its authored description
and routine priority. No reward numbers are inferred from effect configuration.

## Acceptance

At +0.1 and +0.23 seconds the local column echo should identify the activated
tile while the actor and block labels remain readable. At +0.76 seconds the
transient must be gone. Independent instances must own their animation and free
on completion or parent teardown. Baseline/revised final observations, activation
order and RNG state must match. Test lethal movement separately. Compare native
PNGs from the same fixture; do not claim audio, full motion or campaign coverage.

FFmpeg is unavailable on PATH. Use the existing capture module to retain native
AVI, scenario, command, logs and timing, with fixture-saved phase PNGs. The standard
FFmpeg extraction and side-by-side encoding step remains unexercised.
