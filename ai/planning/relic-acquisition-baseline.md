# BKL-008 relic acquisition baseline - 2026-10-20

This is a historical snapshot, not current runtime documentation. Current policy
2.1.0 supports purchases and current RunStats persists run identity; those later
changes do not repair attribution in this old dataset. Keep its cutoff, SQL and
cohort limits when assessing BKL-008. See [current telemetry](../../docs/telemetry.md).

## Decision

Keep relic balance unchanged. Confidence: 9/10 that the present data does not
justify reducing shop stock; confidence in any particular balance value is low.
Existing source-specific events are enough for an observed acquisition baseline.
A rarity framework or new reward manager is unnecessary.

## Plan and scope

1. Audit live deduplicated telemetry, identities, automation and floor coverage.
2. Compare eligible runs by source/build/outcome and record attribution limits.
3. Propose minimal measurement fixes before any gameplay tuning.

No runtime scripts, addon code, reward pools, prices, presentation or dashboards
were changed. This completes the baseline investigation, not the balance task.

## Dataset and method

Read-only Grafana datasource: telemetry-clickhouse.
View: telemetry.events_deduplicated (ReplacingMergeTree FINAL).
Game: echoes_of_the_rift. All retained environments/builds were inspected.
Snapshot cutoff: 2026-10-21 02:03:38 UTC (October 20, 9:03:38 PM Chicago).
Both event timestamp and ingested_at are bounded by that cutoff. The oldest
selected event is 2026-10-18 03:15:59 UTC. This is retained development/QA
data, not a production player sample. Query: relic-acquisition-baseline.sql.

The extract contains 12,216 selected events, below the 20,000-row query limit.
Group nonempty run IDs by environment and source_type. Keep exactly one
run_started per identity. For bots additionally require exactly one
simulation_started with encounter=run; exclude encounter-only simulations and
ambiguous/unlinked identities. Do not use all simulation_completed events as
a denominator: most are isolated combat tests.

Eligible cohort: 260 identities, 24 human-labelled and 236 bot.
All 38 acquisition events (30 treasure claims, 8 purchases) belong to this cohort.
All 30 claims have a treasure_room_exited event in the overall extract; claim
counts are not opening counts. Starting relics and save restoration are not
counted, since they do not emit these acquisition events.

One legacy bot identity mixes nine simulation starts, including encounter tests,
and has no run_started. Excluded. Four additional legacy run_started identities
do not satisfy the one matching run-mode simulation requirement. Thus 20 of the
24 bot run starts in build 0.1.1.0 qualify. Newer bot builds retain all run starts.
The human cohort has no observed console_command_used events in this extract;
absence of that event does not establish unassisted or production play.

## Observed acquisitions per started run

Human-labelled rows are development; bot rows are qa. Keep builds separate.

| Source | Build | Runs | Treasure claims | Shop purchases | Claims/run | Purchases/run |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Human | 0.0.7.0 | 1 | 0 | 0 | 0.000 | 0.000 |
| Human | 0.1.1.1 | 4 | 0 | 1 | 0.000 | 0.250 |
| Human | 0.2.0.0 | 14 | 1 | 7 | 0.071 | 0.500 |
| Human | 0.2.1.0 | 5 | 0 | 0 | 0.000 | 0.000 |
| Bot | 0.1.1.0 | 20 | 1 | 0 | 0.050 | 0.000 |
| Bot | 0.2.0.0 | 201 | 28 | 0 | 0.139 | 0.000 |
| Bot | 0.2.1.0 | 15 | 0 | 0 | 0.000 | 0.000 |

These are acquisitions observed before each run's last available event, not
expected acquisitions for a full run. Do not pool builds to infer a trend.
Human shop acquisitions occurred in six run identities; five are build 0.2.0.0.
Zero bot purchases measure policy coverage, not affordability or player demand.

## Incomplete runs and outcomes

No run_completed events were present. No eligible bot run finished with win.

| Source/build | Observed status | Runs | Claims | Purchases |
| --- | --- | ---: | ---: | ---: |
| Human 0.0.7.0 | Unresolved | 1 | 0 | 0 |
| Human 0.1.1.1 | Combat loss observed | 1 | 0 | 1 |
| Human 0.1.1.1 | Unresolved | 3 | 0 | 0 |
| Human 0.2.0.0 | Combat loss observed | 4 | 0 | 3 |
| Human 0.2.0.0 | Unresolved | 10 | 1 | 4 |
| Human 0.2.1.0 | Unresolved | 5 | 0 | 0 |
| Bot 0.1.1.0 | Simulation loss | 20 | 1 | 0 |
| Bot 0.2.0.0 | Simulation loss | 192 | 25 | 0 |
| Bot 0.2.0.0 | Aborted | 9 | 3 | 0 |
| Bot 0.2.1.0 | Simulation loss | 14 | 0 | 0 |
| Bot 0.2.1.0 | Softlock | 1 | 0 | 0 |

Human combat loss is evidence from encounter_completed, not a dedicated terminal
run event. Unresolved includes stopped collection, saved/quit, ongoing or lost
history; do not relabel these as abandoned or lost. Save loading does not restore
a persisted telemetry run ID, so resumed human runs may have fragmented history.
The extract includes floor events with empty run IDs (19 starts, 6 completions);
these cannot be assigned to a started run. No acquisition has an empty run ID.

## Floor comparison and limits

Neither acquisition event contains floor. floor_started is emitted for combat
nodes only (run.gd:283-314), not shops or treasure. Assigning a purchase to the
previous battle would silently understate its floor. Current treasure placement
at row 8 suggests floor 9, but historical events lack exact floor provenance.
Some claims follow a reported battle floor 10; do not force all claims to 9.
No per-floor acquisition averages can be reported reliably from these records.

The following is only a coverage diagnostic: number of eligible identities whose
maximum recorded floor/floors_climbed is at least the threshold. It does not prove
complete observation of every earlier floor. Zero human coverage at 9 despite a
treasure claim demonstrates why these are lower bounds.

| Source/build | >=1 | >=3 | >=6 | >=9 | >=12 | >=15 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Human 0.0.7.0 | 1 | 0 | 0 | 0 | 0 | 0 |
| Human 0.1.1.1 | 4 | 1 | 1 | 0 | 0 | 0 |
| Human 0.2.0.0 | 13 | 5 | 3 | 0 | 0 | 0 |
| Human 0.2.1.0 | 5 | 3 | 0 | 0 | 0 | 0 |
| Bot 0.1.1.0 | 20 | 6 | 1 | 1 | 1 | 1 |
| Bot 0.2.0.0 | 201 | 148 | 65 | 28 | 12 | 5 |
| Bot 0.2.1.0 | 15 | 10 | 1 | 1 | 0 | 0 |

Shop visit counts also cannot be reconstructed exactly: shop_left_empty_handed
does not count visits where cards or relics were bought. Purchases per visit
would have an invalid denominator.

## Source findings and next actions

1. AutoWalker progression_interface.gd:36-37 exposes leave_shop only. Add
   purchasing behavior only as a separately scoped bot capability; do not read
   zero purchases as evidence for reducing stock.
2. Minimal measurement follow-up: emit room entry for every selected map node,
   with numeric floor and node type; attach that floor to purchase/claim events.
   Reuse the existing event/context mechanism. No new reward framework needed.
3. Persist and restore telemetry run identity across saves; distinguish new and
   resumed runs. Define a terminal run outcome separately from session shutdown.
4. Collect representative human runs with complete room histories. Compare
   acquisition curves only among runs observed through each floor, separating
   wins, losses and unresolved records, builds and automation.
5. Revisit shop stock/prices only after excess supply is demonstrated. The current
   sample contains just one human treasure claim and eight human shop purchases.

Follow the backend-first schema workflow for any future instrumentation.
No telemetry code or schema was changed in this investigation.

## Verification

- Read-only live query succeeded; retained cutoff and deduplicated view recorded.
- Reconciled cohort acquisitions to all extracted claims/purchases: 30 + 8.
- Excluded standalone encounter wins and ambiguous legacy bot IDs.
- Inspected run save/load, floor emission, treasure, shop and bot progression.
- Runtime tests are not needed for documentation/query-only work.
- Formatting and JSON validation results are recorded in the task handoff.

