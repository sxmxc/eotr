# Card pool expansion

Content uses existing Card resources, CardEffectConfig, CardResolver and normal
reward/shop registries. This page describes the authored additions; it is not a
claim of human balance testing.

## Pool inventory

Before expansion, Riftwalker has 27 resources: 17 in its draftable pile, but 26
eligible class entries in its registry. This existing discrepancy includes starter
identities; it is preserved, not silently reconciled. Void Shard is generated and
registry-excluded. Synthforged has 28 resources, seven starter identities supplying
11 starting cards, and 21 eligible draft identities. Only these two classes are
selectable; Voidbinder resources remain unfinished and are not expanded.

After expansion: Riftwalker has 35 resources, 25 pile entries and 34 eligible class
registry identities; Synthforged has 36 resources and 29 eligible class identities.
Six new shared identities bring the default registry-based pools to 40 and 35
respectively. Shared cards are explicitly classless, draftable entries in
`card_registry_shared.tres`, merged by RegistryData. The two enemy-inflicted
negative cards remain `allow_draft=false`; Void Shard remains excluded. Starting
decks and existing eligibility are unchanged. Explicit custom registries retain
their authored scope; class-pile fallbacks are not a second shared selection system.

## Authored cards

| Card | Pool | Cost | Rarity | Target | Effect | Role / tradeoff |
| --- | --- | ---: | --- | --- | --- | --- |
| Slipstream | Riftwalker | 1 | Uncommon | Visible free destination | Move up to 2 hexes. Draw 1. Exhaust. | Movement that replaces itself, once per battle. |
| Grounding Step | Riftwalker | 1 | Common | Visible free destination | Move 1 hex. Gain 1 Attunement. Exhaust. | Positioning establishes damage scaling, limited by exhaust. |
| Drink Deep | Riftwalker | 1 | Uncommon | Self | On a mana well: gain 2 Attunement and draw 1. Exhaust. | Rewards reaching a specific terrain cell. |
| Afterimage | Riftwalker | 1 | Common | Self | Gain 5 block. If you moved this turn, gain 6 more. | Movement turns modest defense into efficient protection. |
| Cash Out | Riftwalker | 0 | Uncommon | Self | Consume all your Attunement. Gain 1 energy per stack, up to 3. Exhaust. | Trade permanent battle scaling for an immediate turn. |
| Borrowed Spark | Riftwalker | 0 | Common | Self | Gain 2 energy. Gain 1 turn of Weakened. Exhaust. | Burst energy exposes the player to 50% more incoming damage for one turn. |
| Second Thought | Riftwalker | 1 | Uncommon | Self | Return the most recent other Skill in your discard to hand at its normal cost. Exhaust. | Retrieve a real card rather than Echo's free copy. |
| Backwash | Riftwalker | 1 | Rare | Visible enemy | Consume target's Corroded. Gain 4 block per stack consumed, up to 16. Exhaust. | Trade future corrosion damage and shred for survival. |
| Scrap Order | Synthforged | 0 | Common | Living construct | Dismantle a construct. Gain 2 energy. Exhaust. | Sacrifice board presence for a burst or a free deployment slot. |
| Service Cycle | Synthforged | 1 | Uncommon | Living construct | A damaged construct restores 4 HP, then attacks immediately. | Damaged-only command supports a frontline construct. |
| Crossfire | Synthforged | 1 | Uncommon | Visible enemy | Deal 3 damage once per construct in range of the target. | Deployment geometry creates multiple Analyze-enabled hits. |
| Spotter | Synthforged | 1 | Common | Visible enemy | Apply 1 Analyze per construct in range of the target (maximum 3). | Uses construct coverage to accelerate Analyze. |
| Relay Orders | Synthforged | 2 | Rare | Living construct | Selected construct and adjacent constructs attack immediately. Exhaust. | Clustering pays off; spread and enemy reach limit activation count. |
| Power Tap | Synthforged | 0 | Uncommon | Living construct | Consume a construct's block (at least 4). Gain 1 energy per 4 block, up to 2. Exhaust. | Convert construct defense into bounded burst energy. |
| Flanking Maneuver | Synthforged | 1 | Uncommon | Visible free destination | Move up to 2 hexes. Apply 1 Analyze to adjacent visible enemies. | Position the player to seed close-range Analyze. |
| Maintenance Window | Synthforged | 1 | Common | Self | Draw 1 card per damaged construct (maximum 3). | Keep wounded constructs alive to improve card flow. |
| Sure Footing | Shared | 1 | Common | Visible free destination | Move 1 hex. Gain 4 block. | A short safe reposition for either class. |
| Keep Distance | Shared | 1 | Common | Self | With no adjacent visible enemies: gain 12 block. | Strong defense requires space; less useful when surrounded. |
| Travel Light | Shared | 1 | Uncommon | Visible free destination | Move 1 hex. Draw 2. Exhaust. | Limited reposition and hand replacement. |
| Unbuckle | Shared | 0 | Uncommon | Self | With at least 6 block: lose all block and draw 2. Exhaust. | Trade already-paid defense for options. |
| Strip Supplies | Shared | 0 | Uncommon | Self | On a resource deposit: destroy its remaining resources. Gain 2 energy. Exhaust. | Immediate energy sacrifices permanent resource income. |
| Reserve Rations | Shared | 1 | Common | Self | Spend 8 gold to restore 4 HP. Exhaust. | Pay run economy and tempo for bounded healing. |

Movement range uses the existing movement modifier and destination legality.
Drink Deep requires the current tile to be a mana well. Crossfire and Spotter
count constructs whose actual attack range includes a visible portion of the
target. Analyze is still capped at three and applied per direct hit. Relay Orders
uses deployment order among selected/adjacent constructs and retains their normal
end-turn activations. Resource, defense and scaling trades consume their payment
before the ordinary configured payoff; resource and energy caps prevent scaling
beyond the authored bounds. Exhaust limits repeat use; multiple owned copies and
existing Echo interactions remain possible. These are design constraints, not a
claim of complete combo-space or campaign balance coverage.

## Implementation ownership

- Ordinary cards are `.tres` resources with explicit `effect_configs`; there is no
  card-ID dispatcher. Card handles payment, configured preview and ordinary targets.
- Movement resources use the existing `riftwalker/phase_step.gd` behavior with
  serialized movement/support effects and the existing formatted descriptions.
- ConstructSummonCard owns placement and fabrication discount only. Its script
  stays at the historical `synthforged/synthforged_card.gd` path and UID for saved
  resources. It contains no ID switch or per-card effects.
- Redeployment owns its two-stage placement validation in its own script. Salvage
  Probe owns current-tile gathering legality.
- Conditional cards have scripts beside their resource, containing that condition
  or tradeoff only, then use CardResolver for standard damage/block/draw/status.
- Old saved Synthforged cards that depended on lazy dispatcher configuration are
  rebound in SaveGame to their current authored definitions, retaining saved cost
  and exhaust. No compatibility dispatcher or empty wrapper class is retained.

## Artwork and validation

All 22 additions have distinct packaged 592 × 396 illustrations. Reference
ownership and rejected revisions are recorded in
`ai/visual/specs/card-expansion-boss-presence.md`; source review does not substitute
for native CardUI inspection. Shared art avoids class-exclusive characters.

Run `python tools/validate_project.py --godot "$godot" --synthforged` for original
Synthforged mechanics, expansion CardUI plays, shared selection and save recovery.
The original fixture covers the 28 original cards; ExpansionCardFixture covers
conditional additions for each class and shared cards. Native scenarios
`card-expansion-riftwalker` and `card-expansion-synthforged` use controlled setup
through the same CardUI/effect APIs. They are not natural-run balance evidence.
