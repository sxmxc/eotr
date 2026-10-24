# Construct status modifiers — 2026-10-24

After committing BKL-043 as requested (`e8b5a2b`), fixed the separately reported
Weakened assertion. The construct scene had a ModifierHandler with no modifier
children; Weakened requires DMG_TAKEN. Added scene-authored DamageDealtModifier
and DamageTakenModifier instances using the existing shared Modifier scene and
normal enum types, matching other combatants. Each construct owns separate nodes.
No global status fallback or status immunity was introduced. Existing status
values, base damage, health, costs, targeting and presentation remain unchanged.

Added a real deployed-construct regression to the Synthforged suite. It checks
both damage slots and per-instance ownership, applies Weakened via StatusEffect,
verifies four incoming damage becomes six, expires the status through the normal
StatusHandler batch, verifies damage returns to four, and checks reapplication
and explicit removal. Another construct remains unaffected. The test restores
health before the existing repair and activation checks continue.

Validation used the original project and Godot 4.7.2, isolated saves, local/fake
telemetry and no backend contact. Evidence under `.qa-tmp/construct-modifiers/`:

- Before scene fix: `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --synthforged`
  exits 1 with the new missing-modifier assertion (`before.log`).
- After fix: same launcher with `--synthforged --capture-ui` exits 0, zero failures
  (`native.log`). Native state assertions, no rendered images inspected.
- Same launcher with `--status-lifecycle`: exit 0, zero failures (`status.log`).
- `python tools/check_scene_resources.py`: zero problems; `git diff --check` passes.
- Exact failing AutoWalker rerun:
  `python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --class synthforged --seed 27 --policy greedy --encounter res://resources/data/battles/tier_1_channelers_bulwark.tres --max-turns 30 --max-actions 160 --timeout 90 --telemetry-local --output .qa-tmp/construct-modifiers/walk`.
  Exit 0, victory in 12 turns/42 actions; zero script errors, invalid player
  actions, failures, aborts, timeouts or softlocks. Four AI invalid decisions
  remain recorded. Evidence: `walk/{godot.log,summary.json,simulation-27.json}`.

Updated authoritative combat/testing guides. Existing certificate-store error
and Void Spectre UID fallback warning remain. No visual-quality, human balance,
full campaign or export claim. The user subsequently authorized committing this
follow-up fix; no push or deployment performed.
