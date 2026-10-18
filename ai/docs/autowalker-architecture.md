# AutoWalker: operation, architecture and validation

AutoWalker instantiates the actual GameWorld and, for run mode, Run. Both visible and
headless execution use `scripts/autowalker/core/gameplay_interface.gd`. Card actions
revalidate live costs, phase, resolution state, fog, valid cells and Card.is_valid_target,
then execute CardUI.play → Card.play → existing effects. Turns use the existing battle
controller. There is no duplicate combat engine and no coordinate-based input.

## Commands (PowerShell, from repository root)

Replace the executable path for your installation. The launcher isolates saves and
uses offline Talo settings. It never starts an analytics backend.

```powershell
python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe --watch
python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe --policy greedy --seed 1 --count 3 --encounter res://resources/data/battles/tier_0_blobs.tres --output build/qa-baseline
python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe --watch --replay build/qa-baseline/simulation-1.json
python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe --mode run --policy greedy --max-actions 1000 --timeout 300 --output build/qa-run
python tools/compare_autowalker.py build/qa-baseline build/qa-candidate --output build/qa-comparison.json
```

Watch can also open `scenes/developer/autowalker/watch.tscn` directly in the editor.
The developer panel offers Start, Stop, Play, Pause, action/turn stepping, speed,
Restart, seed, encounter resource path, policy, encounter/run mode and replay path.
The inspector includes current observed state, selected action, reason, scores and
alternatives, plus the original replay outcome/reason. Pause stops decisions at
resolution boundaries; already resolving effects/enemy turns finish. It does not
pause midway through effects or alter global Engine.time_scale. Speed changes
supported presentation timing and decision delay. Start, restart and replay loading
wait for an action boundary when an action is busy. The scene is
debug-only and automation paths are excluded by release export presets.

`--verify-watch` runs the native renderer, captures `watch.png` after action two and
exits after the simulation; use for rendered checks. Regular `--watch` remains open.
Headless accepts `--seed`, `--count`, `--policy`, `--encounter`, `--max-turns`,
`--max-actions`, `--timeout`, `--output` and `--replay`. Execution is sequential;
parallel workers have not been added without profiling evidence.

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

Each simulation writes `simulation-<seed>.json`; batches write `summary.json` and a
Godot log. Artifacts include outcomes, turns, net health loss, Obelisk destruction
turn, summons, cards used, invalid decisions/actions, timing, warnings and action
checkpoints. `damage_taken` currently measures net starting-minus-final health,
not gross incoming damage after any healing. QA telemetry uses the standalone addon
and writes bounded `events.jsonl`. Report/replay files are distinct QA artifacts,
not a temporary telemetry implementation. Reusing an output directory/seed overwrites
its simulation artifact, so use separate directories for build comparisons.

## Validation evidence — 2026-10-17

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
