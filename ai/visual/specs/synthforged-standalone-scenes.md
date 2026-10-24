# Synthforged standalone effect scenes

Replace `synthforged_fx.gd`'s mode-switched drawing with editable scene nodes and
AnimationPlayer tracks. Preserve the existing amber/ivory machinery and red scan
shapes; this is an ownership refactor, not an art redesign.

Execution: CardUI → Card → CardResolver/config → DamageEffect or support effect →
assigned VisualFX scene. Movement uses the existing Card.cast_fx path. Construct
attacks select their scene through ConstructDefinition.attack_fx. Generic playback
aligns ImpactAnchor and SpellOrigin; no card-specific drawing code remains.

Keep targeting, energy, damage, Analyze, block, construct operations, hit waits,
camera authority and gameplay RNG unchanged. Scene animation owns geometry,
opacity and duration; generic playback applies presentation speed and cleanup.

Matched native evidence: `.qa-tmp/visual/synthforged-scenes-before/` and
`.qa-tmp/visual/synthforged-scenes-after/`, original synthforged-cards fixture,
seed 27, Godot 4.7.2. Both timing.json files report fixture completion without
failures. The fixture supplies controlled initial conditions through the real
CardUI path. Representative inspection and limits are recorded in the matching
[review](../reviews/synthforged-scenes-after.md).
