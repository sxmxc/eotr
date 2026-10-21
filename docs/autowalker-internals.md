# AutoWalker internals

For prerequisites, commands, controls, artifacts and troubleshooting, use the
[operator guide](autowalker.md). AutoWalker is developer automation around the
real Run/GameWorld scenes, not a parallel combat simulator. The same runner
serves headless batches, visible Watch, replay and visual capture.

## Layers and action boundaries

| Source | Responsibility |
| --- | --- |
| `tools/run_autowalker.py` | Argument validation, original-project launch, temporary saves, process isolation, logs, retention and exit status. |
| `scenes/developer/autowalker/watch.gd` / `.tscn` | Authored inspector, controls and startup/exit behavior. |
| `scripts/autowalker/runners/runner.gd` | Simulation lifecycle, limits, observations, actions, replay and report writing. |
| `scripts/autowalker/core/gameplay_interface.gd` | Live combat observation/legal actions and validated execution. |
| `scripts/autowalker/core/progression_interface.gd` | Real route, reward, shop, rest, treasure, event and transition actions. |
| `scripts/autowalker/core/loadouts.gd` | Versioned attainable encounter test presets and fingerprints. |
| `scripts/autowalker/policies/policy.gd` | Random/greedy/stress scoring with a dedicated policy RNG. |
| `scripts/autowalker/core/watchdog.gd` | Stalled-action/turn observation. |

A card action revalidates phase, live cost, resolution state, fog, cells and
Card.is_valid_target, then uses CardUI.play → Card.play → existing effects.
Turns use BattleStateController. There are no coordinate clicks or synthetic
damage rules. Hand readiness and outstanding damage/movement resolution define
safe decision boundaries; awaiting Card.play alone is insufficient for every
async effect. Fog commits visibility before its presentation fade.

Pause prevents new decisions at an action boundary, allowing current effects and
enemy turns to finish. Step allows one action or continues until the turn changes.
Start/restart/replay replacement also waits for a busy action boundary. Speed
adjusts supported presentation timing and decision delay, **not Engine.time_scale**.
Headless execution skips/shortens presentation waits while retaining real gameplay
status, damage, movement and phase work. It cannot certify native GPU behavior.

The launcher runs the actual imported project; only user data goes into system
temp. Reports/logs go into a selected `.qa-tmp/` subdirectory, never a copied
project tree. Direct editor Watch uses editor saves/settings. Automation is for
debug/editor builds and excluded by release export presets.

## Policies and visibility

Current policy version is **2.1.0**. Random ranks legal actions with seeded policy
randomness; greedy scores useful attacks, survival, efficiency, movement and
progression choices; stress favors movement/edges. They are heuristic probes,
not optimal planners and not human balance models. They do not fully forecast
all statuses or multistep combinations.

Policies receive visible enemy information and enumerated legal actions, not
hidden deck order or hidden enemy health. Diagnostic checkpoints can include
hidden entities for replay validation; never feed that diagnostic data back into
policy scoring. Gameplay RNG, policy RNG and presentation randomness are distinct.

Run mode uses actual unlocked routes, continuation/reward controls and card
choices. The current adapter supports real shop purchases and act transitions,
as well as rest, treasure and events. It re-enumerates choices before execution.
Encounter loadout/health overrides are rejected for run mode, which acquires its
build through progression. Not every branch or future custom popup is necessarily
supported: add explicit adapter actions when adding a new interaction.

## Replay, failure detection and reports

Reports record seed, build/engine/policy versions, mode, encounter, loadout identity,
ordered structured actions and pre-action checkpoints/fingerprints with RNG state
strings. A seed is not an action replay. Replay validates state and actions before
executing and stops on divergence rather than forcing the old result. Rules,
content, imports or engine changes can invalidate traces; cross-engine binary
determinism is not promised. Legacy reports resolve the old relic-free loadout;
new reports reject changed preset fingerprints.

Time/turn/action/per-turn/trace limits bound runs; a 30-second no-progress watchdog
identifies softlocks. Live invariants detect overlapping entities, missing player
or living enemies outside the board. Ground-path reachability is a warning because
ranged/teleport solutions may exist. Invalid live actions are reconsidered and
stop after three; replay stops immediately. Unexpected teardown produces evidence.
Configured-limit aborts and strategic losses remain distinct from technical failures.

Completed simulations write `simulation-<seed>.json`. Headless and verify-watch
also write a fresh summary; regular interactive Watch does not. Reports contain
outcome/reason, metric version, counts, timing, warnings, action trace/checkpoints,
run/session identity and loadout fingerprint. V2 health damage/healing/net loss
and cumulative turns have different meanings from v1; do not compare them as
though equivalent. The comparison tool matches seed, encounter, policy/version,
mode, metrics and loadout fingerprint and reads the latest summary's session,
excluding stale files from previous launches.

The launcher requires a fresh summary and checks Godot status/log script failures.
It returns nonzero for technical/launcher failures even when a partial report exists.
Ctrl+C uses a separate process group and invocation-specific stop file: request
normal boundary shutdown, wait at most 20 seconds, then kill/reap an unresponsive
child. It returns 130, preserves completed reports and does not claim an unfinished
simulation completed. Python polls to avoid Windows timed-wait interruption issues.
A wall-clock launcher deadline produces launcher-failure evidence and exit 2.

## Telemetry and bounded storage

TelemetryManager configures independent local JSONL and optional configured HTTP
clients with QA/bot attribution and shared session/run context. The local client
does not depend on upload success. Watch/summary expose health, consent, pending
queue, retries, delivery/rejection counts and last_error. Explicit local/upload
flags and disposable consent behavior are described in the operator guide.
Shutdown drains best-effort for up to 15 seconds, respecting retry backoff; it
is not a durable spool. See [telemetry](telemetry.md) for schema/query semantics.

Each launch starts a fresh 8 MiB JSONL session. Runtime caps include 32 reports,
64 MiB report storage per output and a 16 MiB compact trace. Python retention
prunes generated artifacts older than 14 days or above 256 MiB in the selected
output directory, protecting active files and replay input. Every five seconds
it checks the live log; reaching 8 MiB requests shutdown, then trims only after
the writer exits and emits a storage-limit failure. Small temporary overshoots
are possible. Scratch saves/caches, links, unrelated files and sibling evidence
are excluded. Copy important evidence outside the pruned directory.

## Validation and limits

[Testing](testing.md) lists focused combat, controls, loadout, telemetry, campaign
and Python checks. Tests can establish action legality, cancellation, counters,
queue behavior and replay rejection; native captures establish only the frames
actually inspected. Use the simulation report and matching session's summary to assess a run;
use the engine log to distinguish gameplay failures from shutdown diagnostics.
Bot outcomes measure the selected policy and setup. Human difficulty, renderer
performance and release behavior need their own playtests or measurements.
