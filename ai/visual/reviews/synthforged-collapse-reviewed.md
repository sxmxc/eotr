# All 28 Synthforged cards through real CardUI — synthforged-collapse-reviewed

Status: inspected; accepted for collapse before/after coverage.

Evidence: `.qa-tmp/visual/synthforged-collapse-reviewed`; 95 frames originally
captured, two collapse frames retained after redundant-evidence cleanup.
Expected event observed: True.

## Inspection
Inspected `synthforged-collapse-construct-before.png` at 31.26 seconds and
`synthforged-collapse-construct-after.png` at 35.42 seconds. Actual viewport is
1920×1080. The Pike stands on an endangered edge cell beside the player, with
18/18 health and 999 fixture block; after authoritative shrink its tile, body
and badges are gone while the player remains on the inner cell. Overclock +2
and 5/3 energy are also visible before collapse. Fixture completion at 35.74
seconds reports no failures. This is the actual board shrink path, not a mock.

## Findings
The earlier collapse capture did not clearly frame the endangered construct.
The fixture now chooses a nearby edge, awaits player movement and calls the
existing overview camera before capture. No gameplay camera behavior changed.
The small Pike and its health/block badges are visible before destruction.

## Regression checks
Observed: collapse before/after geometry, construct disappearance, retained player,
health/block badges, Overclock feedback and battlefield atmosphere. Mechanics
assert immediate occupancy release and destruction despite block. Continuous
falling motion, tile-edge synchronization during motion, camera impulses and
audio were not reviewed. Other card/attack coverage is recorded in
[the primary review](synthforged-reviewed.md).

## Decision
Accept the observed collapse state transition. Sparse PNGs do not establish
continuous animation or audio quality; FFmpeg is unavailable.
