# Synthforged — industrial combined arms

## Discovery and baseline

Character authority: `assets/rift/source/synthforged.webp`, inspected directly.
Preserve ivory angular armor, brass circular joints, gunmetal articulation and
cyan faceplate/gauntlet details. Amber machinery and red targeting are complementary.
The existing Riftwalker entity and Arcane Bolt illustration were also inspected.

Actual execution: CardUI → interaction controller → SynthforgedCard → CardResolver
→ existing effects or SummonHandler → recipient. Constructs use board occupancy,
and an awaited allied phase precedes enemies. Visuals never own these decisions.

Functional baseline: `.qa-tmp/visual/synthforged-functional-before/`, native Godot
4.7.2 Compatibility, seed 27, starter loadout, tier_0_blobs. timing.json contains
Pulse Rifle and Deploy Sentry. frame-02.png was inspected: the source character
is recognizable, fog masks hidden actors, and the battlefield/HUD remain readable.
No new card VFX were present. FFmpeg is absent; this baseline uses native stills,
not a reviewed movie or continuous-animation evidence.

## Direction

Weapons use short directional tracers, local ivory contact peaks and falling amber
fragments. Servo strikes emphasize compact mechanical contact. Rail fire is narrow
and forceful. Target scans converge red corner brackets and sweep once. Armor
segments close around the beneficiary without covering it. Fabrication and repairs
use hinged tool arms and localized welding sparks. Commands use distinct red
chevrons. Batteries and Overclock rise through three amber rails.

Each card has an authored effect scene with its own mode. Reuse native drawing
components without repeating a generic expanding ring. Transients end in under
0.6 seconds and respect presentation speed. No gameplay RNG, camera replacement,
damage callbacks, fog bypass, or shared animated material state.

## Acceptance

Inspect actual execution of every card and both construct attack styles. Sample
contact, recovery and overlapping effects. Preserve costs, outcome, target legality,
draw/exhaust behavior, turn ordering and action completion. Verify damage numerals,
small-scale character identity, source/contact alignment, interrupted cleanup,
target highlights, construct death and collapse. Report sparse-frame and audio
coverage separately from mechanic assertions.
