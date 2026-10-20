# Using AutoWalker

AutoWalker plays the game for you so you can watch decisions, repeat a battle, or
check several seeds after a gameplay change. It uses the real combat and run scenes.

Start with [your first battle](#1-watch-your-first-battle). Once that works, try
[headless batches](#3-test-several-seeds-without-a-window),
[replays](#4-replay-a-recorded-battle), or [run mode](#5-test-run-progression).
Implementation details and past test results are in the
[architecture notes](autowalker-architecture.md).

## 1. Watch your first battle

You need Python available as `python` and Godot 4.7.2. Open this project in the
Godot editor once and let its import finish before using the launcher. The launcher
copies the generated import and script caches; it cannot start from an unimported checkout.

Open PowerShell **in the repository root** (the folder containing `project.godot`).
Set the path to your Godot executable, replacing this example with your installation:

```powershell
$godot = 'D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe'
```

Run one visible battle against the tier-0 blobs:

```powershell
python tools/run_autowalker.py --godot "$godot" --watch --encounter res://resources/data/battles/tier_0_blobs.tres --output qa/qa-first
```

The game window opens and the bot starts playing automatically with the `greedy`
policy and seed `1`. The developer panel shows its current state, chosen action,
reason, and alternative scores. The window stays open after the battle finishes;
close it when you are done.

You can also press **Ctrl+C** in the launcher's terminal. The launcher asks Godot
to stop at an action boundary and flush telemetry, waiting up to 20 seconds before
forcing termination. It returns exit code `130` without a Python traceback and
preserves completed reports. An unfinished battle does not get a completed report.

After the battle completes, open `qa/qa-first/simulation-1.json` to see the
outcome and recorded actions. The same folder contains `godot.log` and local
telemetry in `events.jsonl`. Regular Watch mode does **not** write `summary.json`.
Stopping or closing an unfinished battle does not produce a completed simulation report.

The examples upload bot telemetry by default when the project's HTTP transport is
enabled and consent permits it. Add `--telemetry-local` only for an offline run.
The launcher runs the original project directly and does not start backend services.
Disposable saves use automatically cleaned system temp storage, separate from
normal game saves. Never create duplicate project trees or junction workspaces.

QA files now live under `qa/`. Existing result folders keep their names: for
example, the former `build/qa-baseline/` is now `qa/qa-baseline/`. Update any saved
commands and replay paths accordingly. `build/` holds packaged game exports.

| Location | Contents |
| --- | --- |
| `qa/autowalker/` | Reports, telemetry and logs when you omit `--output`. |
| System temp directory | Disposable saves/settings, automatically removed after execution. |
| Your `--output` directory | `simulation-<seed>.json`, `events.jsonl`, `godot.log`, and, for headless/rendered checks, `summary.json`. |

Generated files under `qa/` are ignored by Git and Godot imports and excluded from
release exports. The launcher requires custom output directories to be under `qa/`
so automatic retention covers them.

Local data is temporary: each launch starts a fresh `events.jsonl` session (capped
at 8 MiB), keeps at most 32 simulation reports per directory, and limits a replay
trace to 16 MiB. Watch also caps report storage at 64 MiB per output directory.
The Python QA tools prune generated artifacts older than 14 days and trim the
oldest artifacts to a 256 MiB total budget. During an AutoWalker launch this runs
every five seconds, with active files and the replay input protected; the active
Godot log reaching 8 MiB ends the launch with exit code 2 and a
`launcher_storage_limit` artifact; the file is trimmed only after Godot closes.
Small temporary overshoots between checks are
possible. Scratch caches, game saves, linked source assets and unrelated files are
excluded from pruning. Copy evidence you want to keep outside `qa/`.

## 2. Inspect decisions in Watch mode

Use **Pause at next action boundary**, then **Step one action**, to follow the bot
one decision at a time. Effects and enemy turns already in progress finish before
the pause takes effect.

| Control | What it does |
| --- | --- |
| Start | Starts a fresh simulation using the seed, encounter, policy, and mode fields. Clears a loaded replay. |
| Pause at next action boundary | Pauses new decisions after the current action finishes resolving. |
| Play | Resumes decisions after a pause. |
| Step one action | Allows one bot action, then pauses again. |
| Step one turn | Allows decisions until the turn number advances, then pauses. |
| Stop | Stops the current simulation. Use Start or Restart to begin again. |
| Restart simulation | Restarts the current settings, or the loaded replay. Use Start to apply edited fields. |
| Speed | Changes supported animation timing and the delay between decisions (0.5x–4x). |
| Load replay path below | Loads the JSON report at the replay path and starts replaying it. |

An action can be a card play, a movement, ending a turn, or a run-progression choice.
Speed does not change global `Engine.time_scale`, and Pause does not freeze an
animation halfway through.

You can also open `scenes/developer/autowalker/watch.tscn` in Godot and press **F6**
to run that scene. Click **Start** in its panel to begin. The direct editor path uses
the editor project's saves and telemetry configuration; use the Python launcher
for isolated saves and the offline flag. These tools are for debug/editor builds
and are excluded by the release export presets.

## 3. Test several seeds without a window

Omit `--watch` to run headlessly. This example plays seeds **1, 2, and 3**, one after
another, then exits:

```powershell
python tools/run_autowalker.py --godot "$godot" --seed 1 --count 3 --policy greedy --encounter res://resources/data/battles/tier_0_blobs.tres --output qa/qa-baseline
```

Read the batch totals:

```powershell
Get-Content qa/qa-baseline/summary.json
```

Start with `failures`, `timeouts`, and `softlocks`, then inspect `wins`, `losses`,
and `aborted`. For an individual result, open `simulation-<seed>.json` and check
`outcome`, `reason`, `warnings`, and `trace`.

| Outcome | How to interpret it |
| --- | --- |
| `win` / `loss` | The game reached victory or defeat. A bot loss is not a runner failure. |
| `aborted` | A turn/action limit or bot-cycling guard stopped the simulation. Read `reason`. |
| `replay_complete` | The recorded action list was exhausted. Counted under `aborted` in the summary. |
| `timeout` / `softlock` | The time limit expired, or no action/turn completed for 30 seconds. Investigate the report and log. |
| `divergence` | Replay state no longer matches the recorded checkpoint. |
| `invalid_action` / `invariant_failure` / `unexpected_teardown` | Action validation, a live-state check, or scene lifetime failed. Inspect the report and log. |

For headless runs, exit code `0` does not mean every seed won. The launcher returns
nonzero for reported failures, script errors, a missing fresh summary, or a nonzero
Godot exit. A launcher deadline produces `launcher-failure.json` and exit code `2`.

Use a **new output folder** for each batch you want to keep. Running the same seed
into the same folder overwrites its simulation report. Watch and replay runs can
overwrite reports too.

## 4. Replay a recorded battle

Pass a `simulation-<seed>.json` report, rather than a summary or telemetry file.
Use a different output folder so you keep the original recording:

```powershell
python tools/run_autowalker.py --godot "$godot" --watch --replay qa/qa-baseline/simulation-1.json --output qa/qa-replay
```

The report supplies the seed, policy, encounter, and mode. Replay follows its
recorded actions and checks state before executing each one. It stops if the state
diverges; changes to rules, content, or engine version can make an old replay
incompatible. Reusing a seed alone is not equivalent to replaying the action trace.

For a rendered check that exits automatically, replace `--watch` with
`--verify-watch`. It attempts to save `watch.png` after the second action and writes
a summary when the simulation finishes. Use it for a single simulation; multi-seed
batches require headless mode.

## 5. Test run progression

`encounter` mode plays one battle. `run` mode starts a new run and follows routes
through combat, rewards, card drafts, rest, treasure, and events:

```powershell
python tools/run_autowalker.py --godot "$godot" --mode run --policy greedy --max-actions 1000 --timeout 300 --output qa/qa-run
```

Add `--watch` to see it play. The encounter selection is unused in run mode. The
shop policy currently leaves without buying anything. A complete 15-floor victory
and every optional branch have not been verified, so use this as progression QA
with those limits in mind.

## 6. Compare before and after a change

1. Run the headless batch from section 3 into `qa/qa-baseline` before the change.
2. Make the gameplay change, then run the same command with
   `--output qa/qa-candidate`. Keep the seed range, encounter, policy, and mode the same.
3. Compare the reports:

```powershell
python tools/compare_autowalker.py qa/qa-baseline qa/qa-candidate --output qa/qa-comparison.json
```

The comparison matches seed, encounter, policy, policy version, mode and metrics version. Check
`matched_simulations` and the unmatched counts first. It reports average metric
differences and changed outcomes; it does not declare a regression. Small bot
samples are not enough to establish balance changes.

Reports with `metrics_version: 2` distinguish `damage_taken` (actual health removed
by damage, excluding block and excess overkill), `healing_received` (effective
healing), and `net_health_loss` (starting health minus final health). `turns` counts
all player turns across the simulation; `last_battle_turn` and `floors_climbed`
provide the battle and progression counters separately. Legacy v1 reports used net
health loss as damage and only the final battle's turns for a run. Regenerate both
comparison batches with the same metrics version. Comparison reads only reports
matching the latest summary's session, excluding stale seeds from earlier launches.

## Command options

All examples assume `$godot` is set in the current PowerShell session. See the
launcher’s own option list with `python tools/run_autowalker.py --help`.

| Option | Default | Use |
| --- | --- | --- |
| `--godot PATH` | Required | Godot executable to launch. Quote paths containing spaces. |
| `--watch` | Off | Visible interactive session; stays open after completion. |
| `--verify-watch` | Off | Rendered check with capture and automatic exit. Use instead of `--watch`. |
| `--telemetry-local` | Off | Keep telemetry local without contacting the configured backend. |
| `--mode encounter\|run` | `encounter` | One battle or run progression. |
| `--encounter PATH` | `res://resources/data/battles/tier_1_channelers_bulwark.tres` | BattleStats resource for encounter mode. The introductory examples use the easier tier-0 blobs instead. |
| `--policy greedy\|random\|stress` | `greedy` | Greedy scores useful actions; random ranks legal actions randomly; stress favors movement and board edges. |
| `--seed N` | `1` | Starting simulation seed. |
| `--count N` | `1` | Number of sequential simulations in headless mode, incrementing the seed each time. |
| `--max-turns N` | `50` | Turn limit checked against the current turn number. |
| `--max-actions N` | `500` | Maximum completed bot actions per simulation. |
| `--timeout SECONDS` | `120` | Simulation time limit. Longer visible runs may need a larger value. |
| `--output PATH` | `qa/autowalker` | Report directory inside `qa/`, relative to the repository root or absolute. |
| `--replay PATH` | None | Simulation JSON to replay; use a separate output directory. |

## When something goes wrong

| Symptom | What to check |
| --- | --- |
| Python cannot find the tool | Run from the repository root, where `project.godot` lives. |
| Godot cannot be launched | Check `$godot` points to an existing executable. |
| Missing `.godot` cache files or resource imports | Open the real project in Godot 4.7.2 and let import finish, then retry. |
| Editing fields does not change the next simulation | Click Start to apply them. Restart reuses the current settings. |
| Play does nothing after Stop or battle completion | Click Start or Restart. Play only resumes a pause. |
| No `summary.json` after Watch | Use headless mode or `--verify-watch` for a summary. A completed Watch battle still writes its simulation report. |
| Replay diverges | Check whether gameplay, content, or engine version changed since recording. Keep the original report for diagnosis. |
| Report exists but the launcher exits nonzero | Read `godot.log` for script errors and shutdown diagnostics. Check the summary's failure counts. |
| Ctrl+C returns exit code `130` | This means you interrupted the launcher. Completed reports remain usable; the unfinished simulation was stopped. |
| No events appear in Grafana | Check that you omitted `--telemetry-local`, HTTP telemetry is enabled, consent is satisfied, and the backend is reachable. Inspect telemetry health in Watch or the summary; filter Grafana to QA / bot and the current build. |

Backend outages do not block local reports or JSONL telemetry. Completed headless
batches and closing Watch wait up to 15 seconds for queued uploads. Delivery is best
effort; pending uploads and errors appear in telemetry health.

For automated control and telemetry checks, recorded validation evidence, and known
engine diagnostics, see [architecture and validation](autowalker-architecture.md#validation-evidence--2026-10-17).

For read-only dashboard/query access from Codex, see [Grafana access](grafana-access.md).
Deploy the backend's updated schemas before using the v2 metric events with uploads;
the backend continues to accept legacy v1 events. Automated regression tests remain offline.
