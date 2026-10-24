# BKL-043 — Target predicate parity, 2026-10-24

Completed the unblocked P1 in-review continuation after reading repository and
development instructions, backlog, and recent BKL-051/046 and continuous-improvement
handoffs. Initial worktree was clean. Chosen over ready proposals needing new
mechanics, balance, music assets or visual direction.

Verified the old duplication premise against code: movement selector already
inherits TargetSelector and only enables its arc. CardInteractionController owns
picking, highlights and live commitment; TargetSelector caches broad candidate
cells and invalidates on world/state events. No new selector framework was needed.

Fixed remaining parity gaps: ally and tile highlights now apply the same live
card predicate as picking. Service Cycle excludes full-health constructs, Power
Tap excludes constructs below four block, and Quantum Rift excludes corrupted
cells from its broad candidate list. Construct stats changes invalidate previews
and clear an ineligible selection immediately. Picking validates its candidate
directly against cached cells, avoiding a full highlight recomputation per pick.
Tile highlights reuse one detached validation token per query and free it before
returning. Commitment still recomputes candidates and requires live owned targets.

Audited authored target types: aimed enemy/adjacent/tile/ally, two-stage
Redeployment, and drop-area self/all/surrounding/everyone/no-target paths remain.
Multiple-enemy, multiple-tile and everything enum values have no authored cards
or interactive multi-select implementation. Documented these contracts in
docs/architecture.md and coverage in docs/testing.md. No costs, effects, fog,
input gestures, turn authority, RNG, art, shaders, sounds or balance changed.

Validation on the original project, Godot 4.7.2, offline/disposable saves:

- New Service Cycle/Power Tap regression reproduced four failures before the
  fix (`.qa-tmp/bkl-043/before.log`).
- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation --card-lifecycle-only`:
  zero failures, exit 0 (`after.log`). Includes all Quantum Rift candidate cells,
  both ally predicates and immediate invalid-selection cleanup.
- Same lifecycle command with `--capture-ui`: zero failures, exit 0
  (`native.log`). Native node/state assertions only; no images inspected.
- Same launcher with `--synthforged`: zero failures, exit 0 (`synthforged.log`).
- Same launcher with `--combat-automation`: zero failures, exit 0 (`combat.log`).
- `python tools/check_scene_resources.py`: zero problems.
- `git diff --check`: passes.

Real sequence: `python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --class synthforged --seed 27 --policy greedy --encounter res://resources/data/battles/tier_1_channelers_bulwark.tres --max-turns 30 --max-actions 160 --timeout 90 --telemetry-local --output .qa-tmp/bkl-043/walk`.
Recorded victory, 12 turns/42 actions, zero invalid player actions, failures,
aborts, timeouts or softlocks; four AI invalid decisions. **Launcher exit 1**:
Channeler Weakened application asserts `No damage modifier on Construct`.
The unchanged construct scene has no authored DMG_TAKEN modifier and unchanged
WeakenedStatus requires one. This separate status/construct defect remains outside
targeting scope; the recorded victory is not a clean integration pass.
Evidence: `.qa-tmp/bkl-043/walk/{godot.log,summary.json,simulation-27.json}`.

Existing certificate-store diagnostic and Void Spectre UID fallback remain.
No rendered visual-quality, continuous-motion/audio, performance, human balance,
full campaign or export claim. No backend contact, commit, push or deployment.
