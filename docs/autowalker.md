# Using AutoWalker

AutoWalker plays the game for you so you can watch decisions, repeat a battle, or
check several seeds after a gameplay change. It uses the real combat and run scenes.

Start with [your first battle](#1-watch-your-first-battle). Once that works, try
[headless batches](#3-test-several-seeds-without-a-window),
[replays](#4-replay-a-recorded-battle), or [run mode](#5-test-run-progression).
Implementation details are in [the internals guide](autowalker-internals.md).
For choosing between automation, focused assertions and visual captures, see
[testing](testing.md) and [visual QA](visual-production.md).

## 1. Watch your first battle

You need Python available as `python` and Godot 4.7.2. Open this project in the
Godot editor once and let its import finish before using the launcher. The launcher runs the original project and uses its existing import caches; it cannot start from an unimported checkout.

Open PowerShell **in the repository root** (the folder containing `project.godot`).
Set the path to your Godot executable, replacing this example with your installation:

```powershell
$godot = 'D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe'
```

Run one visible battle against the tier-0 blobs:

```powershell
python tools/run_autowalker.py --godot "$godot" --watch --encounter res://resources/data/battles/tier_0_blobs.tres --telemetry-local --output .qa-tmp/qa-first
```

The game window opens and the bot starts playing automatically with the `greedy`
policy and seed `1`. The developer panel shows its current state, chosen action,
reason, and alternative scores. The window stays open after the battle finishes;
close it when you are done.

You can also press **Ctrl+C** in the launcher's terminal. The launcher asks Godot
to stop at an action boundary and flush telemetry, waiting up to 20 seconds before
forcing termination. It returns exit code `130` without a Python traceback and
preserves completed reports. An unfinished battle does not get a completed report.

After the battle completes, open `.qa-tmp/qa-first/simulation-1.json` to see the
outcome and recorded actions. The same folder contains `godot.log` and local
telemetry in `events.jsonl`. Regular Watch mode does **not** write `summary.json`.
Stopping or closing an unfinished battle does not produce a completed simulation report.

The examples use `--telemetry-local` for offline QA. To exercise configured HTTP
delivery, replace it with `--telemetry-upload` for explicit per-launch consent.
Disposable saves default to consent off; this upload choice does not change
normal player settings.
The launcher runs the original project directly and does not start backend services.
Disposable saves use automatically cleaned system temp storage, separate from
normal game saves. Never create duplicate project trees or junction workspaces.

Keep generated QA files under the existing `.qa-tmp/` directory. Do not create a
separate `qa/` directory. `build/` holds packaged game exports.

| Location | Contents |
| --- | --- |
| `.qa-tmp/autowalker/` | Reports, telemetry and logs when you omit `--output`. |
| System temp directory | Disposable saves/settings, automatically removed after execution. |
| Your `--output` directory | `simulation-<seed>.json`, `events.jsonl`, `godot.log`, and, for headless/rendered checks, `summary.json`. |

Generated files under `.qa-tmp/` are ignored by Git and Godot imports and excluded from
release exports. The launcher requires custom output directories to be under `.qa-tmp/`
and refuses `.qa-tmp/` itself as an output. Retention covers only the selected
output directory; sibling captures and investigations are left alone.

Local data is temporary: each launch starts a fresh `events.jsonl` session (capped
at 8 MiB), keeps at most 32 simulation reports per directory, and limits a replay
trace to 16 MiB. Watch also caps report storage at 64 MiB per output directory.
The Python QA tools prune generated artifacts older than 14 days and trim the
oldest artifacts to a 256 MiB budget within the selected output directory. During an AutoWalker launch this runs
every five seconds, with active files and the replay input protected; the active
Godot log reaching 8 MiB ends the launch with exit code 2 and a
`launcher_storage_limit` artifact; the file is trimmed only after Godot closes.
Small temporary overshoots between checks are
possible. Scratch caches, game saves, linked source assets and unrelated files are
excluded from pruning. Copy evidence you want to keep outside `.qa-tmp/`.

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
| Speed | Changes supported animation timing and the delay between decisions (0.5xâ€“4x). |
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
python tools/run_autowalker.py --godot "$godot" --seed 1 --count 3 --policy greedy --encounter res://resources/data/battles/tier_0_blobs.tres --telemetry-local --output .qa-tmp/qa-baseline
```

Read the batch totals:

```powershell
Get-Content .qa-tmp/qa-baseline/summary.json
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

### Run every encounter

Use `--all-encounters` to discover every encounter resource (including legacy and
non-campaign definitions, not only active act pools) and run the same seed
range against each one, in filename order:

```powershell
python tools/run_autowalker.py --godot "$godot" --all-encounters --policy greedy --seed 1 --count 100 --telemetry-upload --output .qa-tmp/all-greedy
```

Repeat with `--policy stress --output .qa-tmp/all-stress` for matched coverage.
`--count` is the number of seeds **per encounter**. This is headless encounter
mode only; it cannot be combined with Watch, rendered verification, run mode or replay.
Each encounter gets its own subfolder, reports and session; the root `summary.json`
aggregates outcomes and retains each encounter's exit code and summary. Compare
matching encounter subfolders with the comparison tool.

### Choose encounter loadouts

Use `--class synthforged` for Synthforged encounter or run mode. The default
remains `--class riftwalker`; existing Riftwalker preset fingerprints and replay
defaults are preserved. Synthforged starter uses its 11 cards and Overclock Core.
Its tier_1 adds Deploy Pike, Precision Shot, Wideband Scan and Field Repairs;
tier_2 also adds Rail Lance, Fire Command, Deploy Siege Platform and Combat Network.
These are controlled test builds, not balance claims. Class identity is recorded
in Synthforged reports/replays. Observations include constructs, Analyze and the
Overclock cycle; legal actions include ally support and both Redeployment targets.

Encounter mode now defaults to `--loadout tier`, selected from the encounter's
`battle_tier`, clamped to 0–2: tiers 3–8 currently use `tier_2`. It does not
provide distinct Act II/III arrival builds. These are fixed, attainable Riftwalker test builds, **not measured
player averages or a substitute for full-run balance tests**:

| Preset | Deck | Relics |
| --- | --- | --- |
| `tier_0` / `starter` | 11 starter cards | Phase Key |
| `tier_1` | Starter + Nano Shield, Phase Slash, Arcane Explosion, Focus | Phase Key, Feedback Circuit |
| `tier_2` | Tier 1 + Void Fracture, Mana Leech, Rift Knowledge, Adrenaline Rush | Tier 1 + Temporal Conduit |
| `legacy` | 11 starter cards | None, reproducing the old harness |

All additions are existing draftable cards/reward relics. Presets keep normal
maximum HP, energy and draw; they do not invent card upgrades. Starting health is
full unless `--health-percent 75` (or another integer 1â€“100) is selected. A health
sweep can expose attrition sensitivity without claiming to model actual arrival HP.

```powershell
python tools/run_autowalker.py --godot "$godot" --all-encounters --policy greedy --count 100 --loadout tier --telemetry-upload --output .qa-tmp/tier-greedy
python tools/run_autowalker.py --godot "$godot" --all-encounters --policy stress --count 100 --loadout tier --telemetry-upload --output .qa-tmp/tier-stress
```

Use a new output folder. Reports, summaries and start/completion event metadata
include the resolved preset, version, exact initial deck/relic IDs, health and a
fingerprint. The comparison tool refuses to match different fingerprints. The
dashboard source adds an **Encounter outcomes by loadout** table; historical
events display `legacy_unspecified`. Provision the source to expose that panel.
Old replay reports select the legacy setup automatically; newer replays reject
a changed preset fingerprint. Run mode continues to acquire its build through
normal progression and rejects encounter loadout/health overrides. Policy 2.1.0
supports actual shop purchases and act transitions. Bot results remain distinct
from human balance evidence.

### Completion diagnostics

Every `simulation_completed` event retains v2 gameplay metrics in `properties`.
Its `metadata` contains `reason_code`, `reason`, encounter identity, policy version,
action counts, configured turn/action/per-turn/time limits, final health, last action,
and validation/warning counts. This uses the backend's existing metadata contract;
no schema or table migration is required. The AutoWalker QA dashboard's
**Aborts and technical failures â€” reasons and limits** table exposes the details
after the updated dashboard source is provisioned. Older events show `legacy_unknown`.

Abort reason codes are `turn_limit`, `action_limit`, `per_turn_action_limit`, and
`trace_limit`. The cumulative turn budget applies across the whole run.
`--max-actions-per-turn` defaults to 100 and can be raised for a diagnostic rerun.
An explicit upload launch might look like:

```powershell
python tools/run_autowalker.py --godot "$godot" --mode run --policy stress --seed 33 --max-turns 200 --max-actions 2000 --max-actions-per-turn 300 --timeout 300 --telemetry-upload --output .qa-tmp/retry-stress-33
```

## 4. Replay a recorded battle

Pass a `simulation-<seed>.json` report, rather than a summary or telemetry file.
Use a different output folder so you keep the original recording:

```powershell
python tools/run_autowalker.py --godot "$godot" --watch --replay .qa-tmp/qa-baseline/simulation-1.json --telemetry-local --output .qa-tmp/qa-replay
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
python tools/run_autowalker.py --godot "$godot" --mode run --policy greedy --max-turns 500 --max-actions 2000 --timeout 300 --telemetry-local --output .qa-tmp/qa-run
```

Add `--watch` to see it play. The encounter selection is unused in run mode. The
campaign spans three 15-floor acts. Allow 500 cumulative turns and a 300-second
timeout for campaign QA. See [campaign progression](campaign.md) for room selection,
transitions and checkpoint behavior.

## 6. Compare before and after a change

1. Run the headless batch from section 3 into `.qa-tmp/qa-baseline` before the change.
2. Make the gameplay change, then run the same command with
   `--output .qa-tmp/qa-candidate`. Keep the seed range, encounter, policy, and mode the same.
3. Compare the reports:

```powershell
python tools/compare_autowalker.py .qa-tmp/qa-baseline .qa-tmp/qa-candidate --output .qa-tmp/qa-comparison.json
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
launcherâ€™s own option list with `python tools/run_autowalker.py --help`.

| Option | Default | Use |
| --- | --- | --- |
| `--godot PATH` | Required | Godot executable to launch. Quote paths containing spaces. |
| `--watch` | Off | Visible interactive session; stays open after completion. |
| `--verify-watch` | Off | Rendered check with capture and automatic exit. Use instead of `--watch`. |
| `--telemetry-local` | Off | Keep telemetry local without contacting the configured backend. |
| `--mode encounter\|run` | `encounter` | One battle or run progression. |
| `--loadout tier\|starter\|tier_0\|tier_1\|tier_2\|legacy` | `tier` | Encounter build. `tier` selects the preset matching the encounter's tier; `starter` is equivalent to `tier_0`; `legacy` uses the old starter deck without relics. Explicit overrides require encounter mode. See [Choose encounter loadouts](#choose-encounter-loadouts) for preset contents. |
| `--health-percent N` | `100` | Starting encounter health as an integer percentage of maximum, from 1 to 100. Overrides require encounter mode. |
| `--encounter PATH` | `res://resources/data/battles/tier_1_channelers_bulwark.tres` | EncounterDefinition resource for encounter mode. The introductory examples use the easier tier-0 blobs instead. |
| `--policy greedy\|random\|stress` | `greedy` | Greedy scores useful actions; random ranks legal actions randomly; stress favors movement and board edges. |
| `--seed N` | `1` | Starting simulation seed. |
| `--count N` | `1` | Number of sequential simulations in headless mode, incrementing the seed each time. With `--all-encounters`, this is the number of seeds per encounter. |
| `--max-turns N` | `50` | Cumulative player-turn limit across the simulation. |
| `--max-actions N` | `500` | Maximum completed bot actions per simulation. |
| `--max-actions-per-turn N` | `100` | Guard against bot cycling within one turn/progression step. |
| `--all-encounters` | Off | Run the seed range for every encounter in separate subfolders. |
| `--telemetry-upload` | Off | Explicitly consent to QA uploads for this launch. Mutually exclusive with `--telemetry-local`. |
| `--timeout SECONDS` | `120` | Simulation time limit. Longer visible runs may need a larger value. |
| `--output PATH` | `.qa-tmp/autowalker` | Report directory inside `.qa-tmp/`, relative to the repository root or absolute. |
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
engine diagnostics, see [testing](testing.md) and [internals](autowalker-internals.md).

For read-only dashboard/query access from Codex, see [telemetry querying and access](telemetry.md#query-gameplay-and-qa-evidence).
Deploy the backend's updated schemas before using the v2 metric events with uploads;
the backend continues to accept legacy v1 events. Automated regression tests remain offline.
