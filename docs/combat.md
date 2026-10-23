# Combat and the hex battlefield

A battle combines a card hand with positional choices on a shrinking board.
Energy pays for attacks, defense, movement and utility. Block absorbs ordinary
damage; health, statuses and modifiers determine the resulting effects. Card
costs and targets can change during a turn, so a preview is not authorization to
execute a stale action. The normal interaction/automation paths share live
authorization through the battle-owned CardInteractionController. PlayerHand injects it into normal and
spotlight draws. Release rechecks phase, cost, pending work, fog and target
ownership before taking the action lock; freed targets safely return to hand.
The same controller routes click/drag/aim input. Right click cancels selection;
moving an aimed card's cursor into the bottom cancel zone returns it to hand.
Cancellation clears targets without spending energy. The controller owns the
active gesture and sibling locks, restores dragged cards before phase cleanup,
and clears selectors/tooltips when a card or battle exits. States retain their
presentation hooks. Picking, highlights and tooltip enemy modifiers share the
owning battle's context and invalidate together when targets die or enter fog.
Self/area cards still use the scene-authored drop area; automation uses the same
live authorization. Committed tile targets remain alive until effects complete.

GameWorld composes the battle. BattleStateController advances player and enemy
phases; PlayerHandler resolves draw/status/relic work, and EnemyHandler sequences
enemy actions. Both handlers cancel queued continuations when battle shutdown
begins; that does not imply every independently dispatched effect is undone.
Never advance a phase from a visual callback that can outlive its owner.

## Board, visibility and terrain

ProcGenTilemap owns actual cells, fog and occupancy. The current TileSet uses
**64 × 64 pointy hexes** and a **256 × 128** four-column/two-row terrain atlas.
Use its `cell_to_world` / `world_to_cell` conversion for entities and feedback.
Distance helpers and TileMap adjacency are not interchangeable in every case;
preserve the relevant movement/targeting API rather than substituting coordinates.

| Terrain | Current role |
| --- | --- |
| Resource | Finite deposits harvested through the gather effect; depletion updates terrain and economy. |
| Corrupted | Rejected by ordinary free movement, not a universal ban on every special effect. |
| Mana well | Applying its tile effect grants one energy and marks the player mana-buffed. |
| Rift gate | Selects another viable gate and teleports through the existing movement path. |
| Ancient ruin | Rolls a weighted RuinTileEffect and displays its result. Repeatable, not a consumed chest. |

Fog commits visibility before its fade animation. Highlights and enemy information
must respect visibility; tall sprites/effects must not expose hidden enemies.
`board_overlay.gd` renders highlights/warnings from board state; terrain depth
rebuilds from map generation and presentation-change notifications. Neither owns
a parallel occupancy map.

Collapse removes outer cells on the encounter's cadence (default three rounds).
BattleStateController decides when; GameWorld/ProcGenTilemap perform the shrink
and entity checks. Warnings follow visible endangered cells. Falling artwork is
cosmetic evidence of an authoritative erase, not the event that decides whether
a cell exists. Collapse is lethal terrain loss, not an ordinary blockable attack.

## Cards, enemies and victory

Cards expose cost, target type, valid cells and optional custom validation.
Card.play pays energy, emits the committed play event, and resolves configured
effects or the custom hook. CardFxRunner sequences configured projectiles before
effects. Keep impact visual ownership clear to avoid duplicated effects/sounds.
StatusHandler manages durations/stacks; ModifierHandler applies scaling hooks.
Entering an enemy's death sequence cancels its queued status applications and
batch completion. Effects and duration changes already committed remain; pending
statuses do not apply during death feedback. Ordinary enemies and Obelisks share
this death boundary.
[Authoring](content-authoring.md) explains how to extend these paths.

Enemy AI uses conditional/weighted actions with performability checks and fallback
decisions. Moving enemies use bounded path queries; ranged tactics can seek an
engagement ring rather than a melee destination. Intent is the current plan and
may be reselected after conditions change. Inspect action/fallback telemetry and
the actual turn trace when a displayed intent differs from execution.

Current encounter resources use **ELIMINATE_HOSTILES**: every remaining hostile
must die. An **Obelisk** is a stationary enemy with attacks and bounded summons.
Killing it prevents future actions/summons but leaves already spawned enemies.
Every normal and Elite encounter includes one Obelisk; act bosses are exempt.
The base and strengthened resources under `scenes/enemy/obelisk/` share the
player-facing name. They have 20 and 60 maximum HP respectively; their authored
AI differs, including block on the strengthened variant. Spawn actions enforce
cadence, live-enemy caps and viable tiles; preview tiles are not pending combatants.

`EncounterDefinition` retains an optional `DESTROY_OBELISK` objective and GameWorld
has its corresponding branch. That capability is not the current encounter rule.
An Obelisk is not automatically an act boss. The [campaign guide](campaign.md)
describes the distinct boss fights and aggregate hostile-health HUD.

Use [AutoWalker](autowalker.md) for reproducible turn/occupancy failures, focused
[combat tests](testing.md) for lifecycle contracts, and native
[visual QA](visual-production.md) for timing, fog, camera and feedback.
