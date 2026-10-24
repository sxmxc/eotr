# Campaign, bosses and persistence

A run crosses **The Fracture**, **The Corruption** and **The Unmaking**.
Each act has 15 floors, for **45 floors total**, and ends with its own boss.
Health, deck, relics and currency carry into the next act. The first two bosses
open a reward and recovery transition; defeating the final boss completes the run.

## Route and encounter selection

`ActDefinition.campaign()` loads the Fracture, Corruption and Unmaking resources
under `resources/data/acts/`. Each supplies its encounter registry, tier numbers,
recovery rows, environment/music and boss relic. Run configures MapGenerator
from the active definition and carries player/economy/relic state between acts.

| Act | Registry under `resources/data/registries/` | Early / late / boss tiers |
| --- | --- | --- |
| I: The Fracture | `encounter_registry_act1.tres` | 0 / 1 / 2 |
| II: The Corruption | `encounter_registry_corruption.tres` | 3 / 4 / 5 |
| III: The Unmaking | `encounter_registry_unmaking.tres` | 6 / 7 / 8 |

Tier is a selector value, not an act number or floor. Each act begins with combat,
uses early-tier rooms through row 2, and later-tier rooms thereafter. Rows are
zero-based: recovery rows 4 and 13 mean floors 5 and 14; row 8 is treasure on floor
9; floor 15 is the boss. Other connected nodes can be combat, shop, rest or event.
Elites come from eligible late combat pools and promote the node type;
`_ensure_elite_alternatives()` prevents an entrance from forcing only Elites.

EncounterRegistry filters unlocked positive-weight definitions by tier, category
and required tags. MapGenerator avoids the previous two encounter IDs where
alternatives exist. The active registries contain 40 definitions
(18/11/11: 30 normal, seven Elite and three bosses). AutoWalker
`--all-encounters` also discovers resources outside these pools. To check campaign
availability, inspect membership in the act registry rather than the sweep result.
Every normal and Elite encounter contains exactly one Obelisk. Act boss compositions
retain their distinct mechanics and are exempt from that requirement.

## Boss mechanics

Boss scripts in `scenes/enemy/bosses/` adapt to the normal enemy action, damage,
occupancy and cancellation lifecycle. `ui/world_ui/boss_health.gd` shows aggregate
actual hostile health. Victory still requires all hostiles, including surviving
relays after killing their core.

**Bulwark** (`tier_2_bulwark_channelers`, tier 2) commits a short ram route toward
the player's position at preparation. Subsequent movement does not redirect it.
The ram deals 10 blockable damage; recovery takes 50% increased ordinary incoming
damage. Sidestep, block or exploit recovery. It checks surviving cells/occupancy
and can abandon the ram to escape collapse.

**Void Spectre** (`tier_2_void_spectre`, tier 5) alternates listening and reaping.
Attack cards add chorus voices; other cards remove them, capped at three. Reap
deals one 3-damage hit plus one per voice, then resets chorus. A **Memory Anchor**
supports the Spectre: while alive it is healed for four during listening,
and a reap at two or more voices adds Void Residue to the draw pile. Destroying
the Anchor stops that dependency. Card sequencing, block and target priority
all matter.

**Prismatic Siege** (`prismatic_siege`, tier 8) rotates an active link across three
stationary relays. Actual health damage to the lit relay also damages the core;
blocked damage and excess overkill are not transferred. Destroying that relay
interrupts the current 9-damage discharge. With no relays, the core discharges
for four. The core is directly attackable throughout; core-first kills leave
relays alive. Collapse can remove outer relays.

## Rewards and economy

RunStats keeps gold and resources separately. Normal combat offers encounter
currency ranges, accumulated enemy spoils, and a choice of card discovery or
recovery (six HP plus the zero-based act index). Card discovery uses the existing
rarity-weighted draft pool and shared selection UI. Elites add two resources and
an eligible unowned relic, with 35 gold fallback when their relic pool is exhausted.

Shops offer cards for gold and relics for resources, filter already-owned or
ineligible relics, and apply shop-cost modifiers. Rest restores 30% of maximum
health or offers deck refinement; shop refinement costs 60 gold. Removal through
the shared refinement control preserves a minimum deck size of eight. A campfire
commits one choice: resting, refining or continuing locks the remaining actions
during its exit fade and cancels any pending refinement selection. Treasure
opens through its own scene and hands its rolled relic to the reward interface.
Events use actual affordability/choice handlers and can cause noncombat defeat.
Lethal event costs end the run and remove its checkpoint. Once the room is
detached, pending choice/exit callbacks cannot reopen the map or save that run.

Beating either of the first two act bosses opens the transition view. Advancing
awards the act's exclusive relic if unowned, 35 gold, and either 40% max-health
healing or removal plus 20% healing. Transition flags guard repeat claims. Only
the final act boss ends the run and removes the completed checkpoint. Inspect
`run.gd`, `battle_rewards.gd`, `shop.gd`, `rest.gd` and transition/refinement
controls when changing payouts; there is no universal reward manager.

## Checkpoint saves

SaveGame writes `user://savegame.res` (progression version 2). It includes RNG
state, RunStats, PlayerStats, current deck/health/relics, the selected map graph,
last node, floor count and elapsed active-play time. RunStats persists act index,
completed-act floors, telemetry run ID and pending transition/claim flags.

Run saves on the map and before room entry. Save-and-quit during combat preserves
the pre-room checkpoint and updates elapsed time; it does not serialize a
half-resolved fight. Resuming re-enters the room. Pending transitions restore
their view. Legacy version 0/1 saves keep their original map as Act I before
joining the next authored act. Unsupported newer versions and invalid progression
are rejected while retaining the file for recovery.
Missing deck resources and null card entries are also rejected before run startup,
with recovery guidance and the original file retained. Empty decks remain valid.
Map validation also rejects incomplete grid rows, missing or misplaced nodes,
route targets outside the next stored floor, and a last node outside the recorded
completed floor. Current and legacy maps use the same structural checks; loading
does not regenerate or repair a rejected graph. Selectable monster, Elite and boss
rooms must retain their encounter resource; unused grid cells do not require one.

Older checkpoints can embed a non-boss composition missing its Obelisk. For a known
normal/Elite encounter, loading restores the current registered composition only
when the saved scene has no Obelisk and the registered scene does. This retains
the saved route, encounter ID/settings/rewards, player state and boss compositions.
The repair is in memory; loading itself does not rewrite the checkpoint.

Writes go to sibling `savegame.pending.res`, then rename over the destination.
Failure shows a recoverable dialog and retains the previous save. Failed
Save and Quit keeps gameplay paused with the pause menu available for recovery;
successful saving returns to an unpaused main menu. Loading uses
fresh save/subresource data and deep duplication for mutable dependencies. This
is not a guarantee of power-loss durability on every filesystem. The timer counts
active unpaused time, including transitions/hit-stop, excluding paused/offline time.

Use `python tools/validate_campaign.py --godot "$godot"` for bounded lifecycle and
boss checks; `--bosses-only` narrows it, and `--capture` uses native rendering.
Artifacts go to `.qa-tmp/bkl-031/campaign/`. To exercise the route, rooms and
transitions together, use AutoWalker run mode with a campaign-sized turn budget.
See [testing](testing.md) for that command and how to interpret its results.
