# Obelisk terminology and current role

Obelisks are stationary enemies that attack and summon reinforcements. Destroying
an Obelisk stops its future actions and summons; enemies already on the board
remain. Current encounters require defeating the remaining hostiles. Obelisk
destruction alone is not an instant victory.

An Obelisk can be a useful priority target because removing it prevents further
reinforcements. It is not the encounter's automatic victory condition.

## Existing variants

Both variants use the player-facing name **Obelisk**. The labels below describe
existing resources for contributors; they are not new enemy names or types.

| Contributor label | Stats resource under `scenes/enemy/obelisk/` | Max HP | Available actions |
| --- | --- | --- | --- |
| Base variant | `obelisk_enemy.tres` | 20 | Summon, wait, ranged attack |
| Strengthened variant | `obelisk_t1_enemy.tres` | 60 | Summon, wait, ranged attack, block |

The stats resources select their respective authored AI scenes. Summoning uses
the existing spawn action's turn, live-enemy-cap and viable-tile checks. These
variants do not require a separate taxonomy, registry or gameplay change.

## Naming and encounter rules

- Use **Obelisk** for the enemy in current design guidance and player-facing copy.
- Use **base variant** or **strengthened variant** when distinguishing the existing
  resources. Keep resource paths and identifiers stable.
- Treat older "rush the pillar" language as historical design intent, not the
  current victory rule. Avoid using "pillar" as an alternate Obelisk type name.
- A **boss** describes an encounter or boss enemy; an Obelisk is not automatically
  a boss or a boss phase. The future boss redesign belongs to BKL-031. Whether
  future bosses retain Obelisks remains a separate design decision.

`EncounterDefinition` defaults to `ELIMINATE_HOSTILES`; current battle resources
do not override that default. The code retains an optional `DESTROY_OBELISK`
objective and a corresponding victory branch in `game_world.gd`. That capability
does not describe the rules used by current encounters and is not enabled by this
documentation change.

## Source of truth

Check `scripts/resources/encounter_definition.gd` and the encounter resources under
`resources/data/battles/` for victory configuration. Check
`scenes/game_world/game_world.gd` for victory handling, and the stats and AI
resources under `scenes/enemy/obelisk/` for variant behavior. Update this document
when those authored rules change; link here instead of duplicating the taxonomy.
