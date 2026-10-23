# Authoring gameplay content

Content is authored as Godot Resources and composition scenes. Registries make it
available to selection systems; creating a file alone does not put it into a run.
Start from a nearby working example and preserve its runtime ownership contracts.
Use the sandbox for quick inspection, then the actual Run/GameWorld path for
integration. [Architecture](architecture.md) explains those owners.

## Cards

1. Inspect `resources/data/cards/riftwalker/arcane_bolt.gd` and its `.tres`, then
   create a Card subclass/resource under the appropriate class directory. Give it
   a stable ID, name, cost, rarity, target type, description and artwork.
2. Prefer `effect_configs` with CardEffectConfig factories and `_sync_effect_configs`
   for standard damage, block, energy and other supported effects. CardResolver
   executes them through existing effects. Override `resolve_effects` or the legacy
   `apply_effects` only where the mechanics require it; retain Card.play's cost and
   event path instead of duplicating it.
3. Make targeting agree with the effect. `get_valid_targets` returns hex cells;
   `is_valid_target` checks additional live conditions. A SINGLE_TILE base target
   list is all used cells, not automatically legal movement. Use the board's free,
   corruption, occupancy and range predicates where appropriate.
4. Keep descriptions/previews consistent with modifiers. Config preview helpers
   account for dealt/taken scaling; test altered costs, block, multiple hits,
   empty targets and dead targets. Resource `_init()` runs before serialized exports
   are assigned, so resynchronize configurations before resolution where needed.
5. Add to the class's `draftable_cards` and/or starting deck as intended and to the
   relevant `resources/data/registries/card_registry_*.tres`. Registry entries carry
   class, tags, weight, unlock and draft eligibility. `no_draft`/`allow_draft=false`
   exclude a card from drafts. Shop/reward scenes can build empty registries from
   draftable piles; verify the actual consumer rather than relying on one list.

Use `CardEffectConfigHelper.apply_card_defaults(self, config, false)` for
projectile-owned contact visuals and pass `true` for effect-owned contact visuals.
The helper fills missing sound, projectile and selected contact visual fields;
explicit overrides on that owner survive. It clears the other owner's contact
visual field. Call it after loading serialized exports (normally in
`_sync_effect_configs`), including when reusing an existing config. Keep serialized
configs consistent with that ownership: Void Shard and Arcane Bolt attach their
contact visual only through the projectile. An effect-owned config may still
inherit a projectile for travel, with no projectile contact visual. Configured
projectiles run before their effects; do not add a second gameplay damage callback
on arrival. Existing custom utility `cast_fx` is cosmetic, not another resolver.
Keep per-effect overrides, such as Nano Shield's separate energy feedback,
explicit. The helper accepts CardEffectConfig, not legacy Effect nodes; it does
not choose damage, hit count, status, target, projectile mode or camera values.

Add the card to hand in the sandbox and inspect cost, target highlights and modified
description. Play it through CardUI, inspect energy and resulting state, then end
the turn to check pile/exhaust behavior. Use focused combat checks and a short
AutoWalker run for lifecycle-sensitive changes; use native captures for new art/FX.

## Relics and statuses

Relic resources/scripts live in `resources/data/relics/`; the base class is
`scripts/resources/relic.gd`. Set stable ID, type, class eligibility, starter flag,
icon and description. `initialize_relic(owner)` / `deactivate_relic(owner)` bind
and release passive signals; timed relic types are driven by RelicHandler. See
Feedback Circuit for a passive event-driven example. Disconnect the exact callbacks
you connected and handle owner deletion/battle shutdown. Do not treat cancellation
of the handler as cancellation of all effects a relic already dispatched.

A new relic needs explicit membership in its intended shop, treasure, Elite or act
reward pool. `can_appear_as_reward` excludes starters and mismatched classes;
consumers also exclude owned IDs. An icon/resource alone does not make it obtainable.

Statuses derive from `scripts/resources/status.gd`, with application/lifetime
managed by `ui/status_ui/status_handler.gd` and modifiers by ModifierHandler.
Follow existing stack/duration rules and remove callbacks/modifiers on expiration
and teardown. The status lifecycle validator checks this independently of bot play.

## Enemies, encounters and bosses

EnemyStats resources and AI scenes live under `scenes/enemy/`; EnemyCatalog at
`resources/data/catalogs/enemy_catalog.tres` supports inventory/developer lookup.
Use Enemy or MovingEnemy and existing EnemyAction lifecycle. Author stats, intent,
actions and optional EnemyTactics; keep advertised intent aligned with performability
and fallback behavior. Use the actual ranged engagement/pathing helpers.

An encounter consists of:

- A composition `.tscn` under `resources/data/battles/`, instancing enemy scenes
  with their intended stats/AI. Obelisk spawn pools remain authored on instances.
  Every normal and Elite composition must include exactly one Obelisk. Act bosses
  are exempt; keep their authored signature actors (including Memory Anchor).
  Use an explicit spawn pool drawn from the encounter roster. Restored compositions
  use the base Obelisk for normals and the existing strengthened profile for Elites;
  previously authored profiles remain unchanged.
- An EncounterDefinition `.tres` containing stable ID/name, tier, category, tags,
  unlock, positive weight, enemy composition, battlefield dimensions, rewards and
  terrain/spawn/collapse settings.
- Membership in the active act's typed EncounterRegistry.encounters array.
  See [campaign](campaign.md) for the three registries and tier ranges.

Keep ID, category and tier on the definition; do not duplicate selection metadata
in another pool. Registry.select filters tier/category/tags/unlock/weight and can
use an explicit unlocked ID override; empty eligible pools return null rather
than unrelated content. GameWorld duplicates the selected definition for mutable
reward totals. The familiar `battle_stats` property is an EncounterDefinition.

Optional authored stage fields include `player_start_cell`, `enemy_start_cells`,
`arena_floor`, `terrain_cells` and `reveal_arena`. Defaults preserve procedural
behavior. Other fields control dimensions, minimum spawn distance, starting tile,
corruption weight, shape and collapse cadence. Inspect a current boss definition
before using fixed cells; ensure every spawn lies on the resulting board and does
not overlap. Default victory is elimination; do not enable DESTROY_OBELISK merely
because a composition includes one.

The three current bosses reuse the existing enemy/action adapter and normal
damage/occupancy/completion path. Preserve their counterplay and act placement;
[campaign guide](campaign.md) explains their counterplay and progression. Extend
the existing combat lifecycle when adding boss behavior.

After saving resources, complete editor import, run the resource guard and relevant
combat/campaign validator, then launch the exact `.tres` via AutoWalker. Check
spawn legality, intent, fog, collapse, summons, remaining-hostile victory and reward
continuation. A successful isolated encounter does not prove registry eligibility;
inspect or test map selection too. `scenes/devtools/data_editor.tscn` is the
existing data editor; definitions must be saved before registry references.

For artwork dimensions, packaging and inventories, see
[visual production](visual-production.md). For layout, see [UI authoring](ui-authoring.md).
