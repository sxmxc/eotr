# AutoWalker: architecture and validation

For setup and everyday use, start with the [AutoWalker user guide](autowalker.md).
It covers your first battle, Watch controls, headless batches, replays, comparisons,
command options and troubleshooting. This document explains implementation behavior
and records validation evidence.

AutoWalker instantiates the actual GameWorld and, for run mode, Run. Both visible and
headless execution use `scripts/autowalker/core/gameplay_interface.gd`. Card actions
revalidate live costs, phase, resolution state, fog, valid cells and Card.is_valid_target,
then execute CardUI.play → Card.play → existing effects. Turns use the existing battle
controller. There is no duplicate combat engine and no coordinate-based input.

## Execution and controls

The Python launcher isolates saves and retains the project's `telemetry/config_path`
(or production.tres) unless `--telemetry-local` selects the Null configuration.
Automated validation always uses an isolated Null configuration. No launcher starts
backend services. Headless batches execute sequentially; parallel workers have not
been added without profiling evidence.

Launcher projects, isolated saves, reports and captures are generated under `qa/`.
The `qa/.gdignore`, Git ignore rules and release export filters keep QA artifacts
out of imports, source control and packaged games. `build/` is reserved for exports.

The Watch inspector exposes observed state, the selected action, reason, scores,
alternatives and the original replay outcome/reason. Pause stops decisions at
resolution boundaries; effects and enemy turns already resolving finish. Speed
changes supported presentation timing and decision delay without changing global
Engine.time_scale. Start, restart and replay loading wait for an action boundary
when an action is busy. The scene is debug-only and automation paths are excluded
by release export presets.

The launcher puts Godot in a separate process group/session so terminal Ctrl+C is
handled by Python. It sends a unique per-invocation stop-file path to the runner;
on interruption, creating that file pauses decisions, waits for a busy action to
finish and requests normal telemetry-aware shutdown. The launcher waits up to 20
seconds, then kills and reaps an unresponsive child. Interrupted launches return
130 and retain completed simulation reports; they do not claim an unfinished
simulation completed.

## Policies and observability

Random ranks legal actions randomly with a dedicated seeded policy RNG. Greedy
scores attacks, low-health targets, card energy efficiency, Obelisk pressure,
survival and moves toward visible enemies. Stress favors movement and edge positions.
These are interchangeable modes of the independently testable policy class, version
1.0.0. Greedy is a lightweight baseline, not an optimal planner; it does not forecast
all statuses or multistep combos. Policies see visible enemy data and legal actions,
not hidden deck order or hidden enemy health. Full diagnostic checkpoints include
hidden entities only for replay validation, never as policy inputs.

Run mode uses actual unlocked routes, battle continuation, reward buttons and card
choices. It also supports rest, treasure/relic collection and event options; its shop
policy currently leaves without purchasing. It does not invent progression content.
Reward and route actions are re-enumerated before execution. A run was exercised
through battles, reward collection, a drafted card and later defeat; a complete
15-floor campaign victory and every optional room branch have not been verified.
There are currently no gameplay producers of the generic card-cost selection popup;
if future cards start using it, automation will need explicit popup actions.

## Resolution, replay and failures

Played cards leave the hand immediately, before burn animation, avoiding double
discard at fast pacing. Damage/movement counters and hand readiness establish actual
resolution boundaries. Fog visibility commits synchronously before fade presentation.
Headless skips camera waits/projectiles/death presentation and shortens presentation
delays while retaining actual status, damage, movement and phase execution.

Gameplay RNG is separate from policy RNG and presentation randomness. Screen shake,
decals and pile inspection no longer consume the gameplay stream. Replay records
build/engine/policy version, seed, encounter/run mode, ordered structured actions,
RNG state strings and state fingerprints/checkpoints before actions. The seed is not
assumed sufficient. Replay revalidates actions and stops on divergence; it never
forces an old result onto incompatible state. Replays are expected to diverge across
rule/content changes and are not a promise of cross-engine binary determinism.

Limits detect stalled resolution, wall-clock timeouts, excessive actions/turns and
bot cycling. Live invariant checks flag overlapping entities, missing players and
live enemies outside the board, and report unreachable grounded paths as warnings
because ranged/teleport solutions can still be legal. Unexpected teardown produces
a failure artifact. Invalid actions are rejected and reconsidered, stopping after
three; replay stops immediately. Strategic losses and configured action/turn limits
are distinct from defects. Current Obelisk summons are synchronous: preview tiles
are not pending combatants. Dead Obelisks cannot summon or act.

Each completed simulation writes `simulation-<seed>.json`. Headless batches and
`--verify-watch` write `summary.json`; regular Watch does not. The launcher also
captures a Godot log. Artifacts include outcomes, turns, net health loss, Obelisk destruction
turn, summons, cards used, invalid decisions/actions, timing, warnings and action
checkpoints. Metrics v2 measures actual health damage, effective healing and net
health loss separately; turns span all battles in a simulation. Legacy v1 used net
health loss as damage and the final battle's turns for run mode. QA telemetry uses
the standalone addon and starts a fresh bounded `events.jsonl` each session. Report/replay files are distinct QA artifacts,
not a temporary telemetry implementation. Reusing an output directory/seed overwrites
its simulation artifact, so use separate directories for build comparisons.
Reports carry unique run/session IDs assigned before scene startup. Comparisons
match metric versions and only read the latest summary's session. Retention keeps
32 reports/64 MiB per output directory with a 16 MiB compact trace budget; Python
tools additionally prune generated QA artifacts after 14 days or above 256 MiB.
See the user guide for active-file protections, exclusions and archival advice.

When the configured transport is enabled HTTP, a second addon client sends bot
events to the existing endpoint with `environment=qa`, `profile=qa` and
`source_type=bot`. Both clients share session/run context and keep independent
bounded delivery queues; a backend outage does not block local JSONL or simulation
reports. Each destination generates its own event IDs; HTTP retries preserve their
IDs. The Watch inspector and summary.json expose upload counts, pending events,
retries, consent and last_error. In Grafana select QA / bot and the current build.

Completed headless batches and closing Watch wait up to 15 seconds for queued
telemetry, respecting retry backoff. A warning and summary health expose pending
uploads at the deadline; delivery is best effort, not a durable upload spool.
The local JSONL remains available when the backend is unreachable. The startup
message explicitly reports backend-plus-local or local-only routing. No HTTP client
is created when configured telemetry is disabled, non-HTTP, or --telemetry-local.

## Validation evidence — 2026-10-17

Metric/retention correction: five launcher tests, four storage/comparison tests and
eight ingestion tests pass. Godot checks cover healing/block/overkill, fresh JSONL,
startup identity, unique runs, cumulative turns and report retention. A two-battle
run reports 10 total turns separately from final battle turn 4; 292 actual events
pass the updated ingestion validator. A lowered test log threshold requests normal
shutdown and produces a storage-limit artifact with no orphan stop request.
The full compatibility suite loads 531 resources and has zero failed assertions,
but this run exits nonzero on four retained shutdown resources and known diagnostics.
No live ingestion deployment, Grafana query or MCP connection was performed.

Launcher lifecycle regression: `python tools/test_run_autowalker.py` (no engine or
backend required). Five tests cover exit-code propagation, process isolation,
interruptible polling, graceful stop/report preservation and forced child cleanup.
Polling avoids the installed Python 3.10.2 Windows timed-wait retry behavior during
KeyboardInterrupt. A simulated interrupt during headless play and after a rendered
Watch victory returned 130 without a traceback or static-string/navigation-parser
shutdown errors; the completed Watch report's checksum stayed unchanged. These
checks use local telemetry only. A normal rendered check still exposed existing
texture/resource cleanup diagnostics.

QA path migration: AutoWalker launches successfully with its default output under
`qa/autowalker/`. The moved baseline and candidate batches match all three seeds
with unchanged outcomes, turn counts and net health loss. Standalone telemetry tests
and Watch control assertions pass from projects under `qa/`; the controls process
still exits nonzero on existing shutdown resource-retention diagnostics.
The full compatibility runner from the new location exits 0, loads 531 first-party
resources and reports zero failed assertions; existing shader/certificate and
single-resource shutdown diagnostics remain.

Backend-free upload routing regression:
`python tools/validate_project.py --godot <executable> --autowalker-telemetry`.
It substitutes a fake asynchronous transport before any network processing and
checks batching, retries, consent, queue pressure, local independence and bot context.

- Independent addon test project: zero failed assertions; no game autoloads included.
- Combat test: zero failures for legal enumeration, stale cost rejection, paid custom
  card, single pile commit, hand removal, dead-Obelisk spawn rejection, continued
  combat after Obelisk death, range/occupied movement and elimination victory.
- Control test: zero failures for pause, action step, turn step, presentation speed
  without global time scaling, and stop.
- Full compatibility smoke: 530 first-party resources, zero failed assertions.
- Greedy tier-0 seeds 1–3: three wins, turns 6/5/8, 24/20/31 actions, one summon,
  no failures, softlocks, timeouts or invalid player actions. This is bot-only evidence.
- Random tier-1 seeds 1–2: two losses, no failures. Stress seeds 1–2: one loss and
  one configured-limit abort, no failures; two stale enemy intents were reselected.
- Native Watch replay: 12 actions/three turns reproduced without divergence; winning
  seed 2 replay reproduced 20 actions/five turns and victory, with a saved native capture.
- Run mode: 76 actions through routes, combat, continuation, rewards and a drafted
  chrono_jab card, ending in defeat without runner failure. Its 307 actual JSONL
  events passed the ingestion validator using the canonical schemas, without a server.
- Backend: seven mocked ingestion tests and static dashboard/YAML/manifest/SQL-feature
  checks pass. No SQL execution or backend end-to-end integration was performed.

Existing certificate-store, headless shader-compiler and intermittent retained-resource
shutdown diagnostics remain. Passing assertions do not establish a clean engine exit,
large statistical balance conclusions, release-export correctness or renderer performance.
