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

Enemies export an anchor-relative cube-coordinate `footprint`. ProcGenTilemap
expands it to offset cells and remains the only occupancy owner. Registration,
destination legality, path queries and movement reservations use the whole body;
reservations cover both origin and destination until completion/cancellation.
Self-overlap is legal; unrelated actors, missing cells and (for grounded units)
corruption reject placement. Single-cell actors use the same APIs.

An enemy is revealed when any surviving body cell is visible. Target highlights
include only visible occupied cells; selecting one resolves to the one enemy.
Adjacent attacks and construct range use the nearest visible occupied cell.
An area intersecting multiple body cells still produces one recipient per hit;
intentional multi-hit effects remain separate hits. Current bosses have one
health/status identity, with no independently damageable body parts.

Collapse removes outer cells on the encounter's cadence (default three rounds).
BattleStateController decides when; GameWorld/ProcGenTilemap perform the shrink
and entity checks. Warnings follow visible endangered cells. Falling artwork is
cosmetic evidence of an authoritative erase, not the event that decides whether
a cell exists. Collapse is lethal terrain loss, not an ordinary blockable attack.
Losing any currently occupied body cell kills the enemy through block and releases
its complete footprint. A cancelled move does not fall merely because its abandoned
destination collapsed. No act boss has collapse immunity.

## Synthforged and allied constructs

Synthforged starts with 35 HP, three energy, four cards per turn and view range
one. **Overclock** adds two energy after the normal reset on player turns 4, 8,
12 and every fourth turn thereafter; the count restarts each battle. Overclock
Core represents this passive and displays the cycle without granting a second
activation. Riftwalker's Adaptive Surge, movement refund and Obelisk bonus remain
class-specific.

**Analyze** is a battle-local enemy status, capped at three stacks. Each stack
adds one damage to each direct player/construct hit before target mitigation;
block absorbs it normally. DamageEffect requires explicit player-side provenance,
so enemy attacks, terrain and damage-over-time effects receive no Analyze bonus.
Consuming attacks remove and snapshot the stacks first and apply their authored
bonus without adding the consumed stacks again. Ordinary attacks and previews
share these rules.

**Summon** cards deploy stationary allied constructs onto visible, free resource
cells within two hexes. Corrupted/special terrain and occupied cells are illegal.
Three constructs may coexist; deployment at the cap is unavailable. They block
movement through the shared occupancy map, have independent HP/block/modifiers,
and do not count as hostiles, rewards or victory requirements. Sentry/Pike/Bastion/
Siege profiles are respectively 12/18/30/16 HP, 3/5/4/8 damage and 3/1/1/4 range.

After player cleanup, BattleStateController awaits an allied phase before enemy
actions. Constructs act in deployment order, including their deployment turn.
Each selects the nearest visible hostile in range, then lowest HP, then spawn
order. Fire Command adds an activation. Constructs turn their sprites toward
the attack recipient before firing, retaining their facing for vertically aligned
targets. Ally support uses the same cursor-pickable collision layer as other units.
Construct block clears at player turn
start; repairs clamp to maximum HP. Enemy ordinary attacks choose the nearest
reachable player-side unit, preferring the player on ties. Boss signatures,
rooted rift seals and player-energy-specific attacks retain their authored focus.
Intent descriptions identify attacks aimed at constructs.

Redeployment selects a construct and then an adjacent legal resource cell. Either
stage may be cancelled without spending energy. Source and destination are both
revalidated at commitment. Death, collapse and battle shutdown release occupancy
and cancel future allied work; collapse bypasses block. Constructs and Analyze
are discarded with the battle and are not added to room-checkpoint saves.

## Card resolution and hostiles

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

## Combat event feed

DamageEffect carries an explicit source actor or named cause (Burn, Poison,
Corrosion, Ancient ruin); collapse supplies its own cause. Player reports the
health delta inside the actual application callback, after modifiers, block and
HP clamping. Prevented damage is a separate outcome. Floating player numbers use
that same received amount. Enemy names come from EnemyStats, never node IDs.
Visibility is sampled from board fog when the effect resolves, independent of
camera position. Currently fogged enemies are anonymous, matching the enemy rail;
there is no persistent enemy-identity knowledge model. Narration and spawn notices
also respect fog. Damage effects retain their cause after their creator exits.

The left event feed uses chronological, borderless rows with a restrained accent
for consequential events. Routine messages expire after at least three seconds,
extended for length, and cannot evict outcomes. Four live rows in a bounded scrolling area limit its footprint;
overflow remains available through Recent events, a chronological 40-entry
battle-local history. Overflow discards routine history before outcomes, and
consecutive identical routine messages are suppressed. Important outcomes remain through enemy resolution and get
at least ten seconds after control returns (extended for longer messages); ending
that turn cancels expiry and the next player turn restarts the reading window.
New outcomes replace the oldest live row only when all slots are occupied; history
keeps individual hits and prevented attacks. No aggregate turn total is generated.
