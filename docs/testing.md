# Testing and investigating failures

Choose the smallest check that exercises the behavior you changed. The Python
launchers run the real imported project, isolate saves in system temp, and use
Null/fake telemetry for regression validation. They do not create test copies of
the project or start a backend. Use Godot 4.7.2 and run from the repository root.

```powershell
$godot = 'D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe'
python tools/check_scene_resources.py
python tools/validate_project.py --godot "$godot"
```

The resource guard checks cache references, embedded data and UI authoring rules.
The default runtime scene loads first-party resources and exercises telemetry,
menu/sandbox, save/load, new-run and combat startup. It is a broad smoke check,
not proof of a complete campaign or good visual presentation.

## Select a focused check

Pass one focused suite at a time; the runner chooses scenes by precedence rather
than combining every flag into a larger suite. `--help` lists all current options.

| Change or question | Command after `python tools/validate_project.py --godot "$godot"` |
| --- | --- |
| Combat legality, action completion and teardown | `--combat-automation` |
| Lunge cancellation only | `--combat-automation --attack-cancellation-only` |
| Status expiration and modifier cleanup | `--status-lifecycle` |
| Occupancy/movement query checks and profiling | `--board-queries` |
| Watch pause/step/speed/stop | `--autowalker-controls` |
| Local/upload routing with fake transport, no server | `--autowalker-telemetry` |
| Reward/shop transactions | `--ui-transactions-only` |
| Event choices and affordability | `--event-room-only` |
| Map focus, routes and readability constraints | `--map-only` |
| Battlefield framing and grid | `--combat-automation --battlefield-only` |
| Native terrain/collapse breakup | `--combat-automation --terrain-only --capture-ui` |
| Native combat/collapse movie fixture | `--combat-automation --motion-review --capture-ui` |

Other targeted flags include `--card-lifecycle-only`, `--mana-wells-only`,
`--utility-review` and `--vfx-only`; inspect their owning test-scene branch before
using them as evidence. `--capture-ui` switches from headless to native offscreen
rendering. Its captures/logs live in the launcher's temporary directory and are
removed after exit. Use the persistent [visual pipeline](visual-production.md)
when a reviewer needs to inspect files afterward.

Campaign checks have a separate launcher:

```powershell
python tools/validate_campaign.py --godot "$godot"
# Narrow the same suite to boss checks:
python tools/validate_campaign.py --godot "$godot" --bosses-only
# Save-and-quit I/O failure recovery and successful return to menu:
python tools/validate_campaign.py --godot "$godot" --save-quit-only
# Reject missing deck/card resources without modifying the checkpoint:
python tools/validate_campaign.py --godot "$godot" --save-validation-only
# Require non-boss Obelisks and resume an old incomplete encounter composition:
python tools/validate_campaign.py --godot "$godot" --obelisk-encounters-only
```

`--capture` renders natively; logs/captures go to `.qa-tmp/bkl-031/campaign/`.
This suite covers lifecycle/mechanics with controlled fixtures, not natural human
progression. AutoWalker run mode exercises the real progression UI/actions.
A full campaign needs a larger cumulative turn budget than encounter defaults:

```powershell
python tools/run_autowalker.py --godot "$godot" --mode run --policy greedy --seed 2 --max-turns 500 --max-actions 2000 --timeout 300 --telemetry-local --output .qa-tmp/campaign-check
```

Do not run large encounter/seed sweeps for routine documentation or cosmetic edits.
Use [AutoWalker](autowalker.md) for choosing an encounter, loadout, limits, replay
and matched comparisons. A bot loss is a gameplay outcome; an action-limit abort
is a configured stop; neither is automatically a technical regression.

## Python and backend checks

These standard-library tests exercise launch/storage/comparison contracts without
Godot or network services. Run the one relevant to the change:

```powershell
python tools/test_run_autowalker.py
python tools/test_qa_data.py
python -m unittest discover -s tools -p test_compare_loadouts.py
```

The telemetry test requires Godot: `python tools/test_telemetry.py --godot "$godot"`.
It runs against the original project with disposable user data and local-only
telemetry. It does not create a second addon-only project.

Art validation requires Pillow: `python tools/validate_rift_art.py`. It checks
bindings, dimensions, alpha, footprints and unused/superseded asset references;
it does not approve artistic quality. It currently flags 12 intentionally
retained legacy WebP FX sheets plus `shuffle.svg` as unused; do not delete retained
art automatically to make this check green. `python tools/audit_visual_effects.py`
regenerates a source inventory and is a writing operation, not just a test.

If the backend submodule is present, from `backend/telemetry/` run
`python -m unittest discover -s ingest -p test_service.py -v` and
`python validate_artifacts.py`. Storage is mocked; these do not prove a deployment
or execute migrations. See [telemetry](telemetry.md) for operator checks.

## Read results before declaring success

`validate_project.py` requires a zero process status, its suite-specific zero-failure
marker and no unexpected ERROR lines. A script failure can occur even when Godot
returns zero. The runner permits a small explicit set of known engine diagnostics
(certificate store, one shader diagnostic and one retained-resource message).
Read the output: passing assertions are not a promise of clean engine shutdown.
`--verbose` can help identify retained objects.

The broad smoke check currently fails two assertions for hidden left/right map
emitter positions (`Preserve right emitter position: map/map` and its left-side
counterpart). When investigating another subsystem, report those failures and use
the relevant focused suite to isolate its result. Do not count a failing smoke run
as a pass because the unrelated checks succeeded.

For a failure, retain the exact command, engine/renderer, seed, encounter, policy,
limits, log and fresh report in a bounded `.qa-tmp/` folder. Check imports first,
then the earliest script/assertion error rather than its cascade. For a hang,
inspect the last action/phase and completion signals; raising limits cannot fix a
missing completion. AutoWalker reports action checkpoints and reason codes.

Native offscreen assertions validate renderer-dependent state; only opening
captures establishes what they look like. Sparse frames do not establish continuous
motion/audio, GPU performance, controller coverage, export correctness or human
balance. Report those limits with the result.
