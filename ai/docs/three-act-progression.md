# Three-act campaign (0.3.0.0)

The campaign traverses The Fracture, Corruption and The Unmaking: 15 floors
each, 45 total. ActDefinition.campaign() loads resources/data/acts/*.tres;
scenes/run/run.gd owns transitions, persistence and final victory. The first
two bosses open transition rewards; only the third ends the run.

The active registries contain 40 definitions (18/11/11): 30 normal, seven
Elite and three bosses. Elites are optional tactical groups, not mid-run
bosses. Every Elite entrance has a non-Elite alternative. Rest floors are
5 and 14, treasure is floor 9, and each act boss is floor 15. The legacy
registry preserves historical definitions for compatibility and sandbox use.

| Act | Boss encounter ID / tier | Counterplay |
| --- | --- | --- |
| Fracture | tier_2_bulwark_channelers / 2 | Sidestep the committed ram route; punish recovery with 50% increased incoming damage. |
| Corruption | tier_2_void_spectre / 5 | Attack cards add voices, other cards remove them; kill the Memory Anchor to stop deck pollution. |
| Unmaking | prismatic_siege / 8 | Damage the lit relay to transfer actual health damage to the core; destroy it to interrupt discharge. |

Bosses reuse normal action completion, occupancy, damage and collapse.
All hostiles must die, including surviving relays after a core-first kill.
The boss HUD aggregates actual hostile health. Introductions, intentions,
music and signature effects distinguish fights. Sources: scenes/enemy/bosses/
and ui/world_ui/boss_health.gd. Historical Triune/Core Nexus pillar stages
are not the current design.

Save version 2 persists act, completed floors, run identity and pending
transition rewards. Legacy saves retain their existing Act I map. Future
versions are rejected without deleting the file. Mid-combat reload restores
the pre-room checkpoint. Transition rewards guard against duplicate claims.

Transitions grant an exclusive relic and 35 gold, then healing or removal
plus smaller healing. Combat offers discovery or recovery. Elites add
resources and an available relic, with gold fallback. Rest/shop refinement
uses shared card selection and a minimum deck size of eight.

Telemetry preserves the deployed schema: act/run/encounter context lives in
metadata. Lifecycle markers use stat_changed and metadata.lifecycle_event.
No backend deployment is required.

The corrected Void artwork replaces the existing 1536x1024 atlas in place:
assets/rift/menus/act_environments.png. Dimensions, crops and rendering
behavior are preserved. The art correction adds no battlefield/camera feature.

Validation evidence and limitations: ai/state/journal-bkl-031.md.
