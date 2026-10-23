# BKL-050: shared card visual defaults

## 2026-10-22

Selected the actionable P2 continuation after reading repository/workflow docs,
the backlog and recent BKL-047/048 and continuous-improvement handoffs. Other
ready P2 proposals require new mechanics, balance decisions or visual direction.
The in-review task's premise was partly stale: CardEffectConfigHelper existed,
but only Sever Anchor used it. The initial worktree was clean.

Replaced repeated default visual/sound/projectile assignments across 18
Riftwalker config builders with the helper. Retained explicit secondary energy
feedback, legacy Effect-node APIs, gameplay amounts, targeting, hit/status
sequencing, camera settings and projectile modes. Sync still owns gameplay
configuration; the helper owns default sourcing and contact ownership only.

The helper now clears the unused effect contact field when selecting projectile
ownership, matching its existing clearing of projectile contact for effect
ownership. Explicit overrides on the selected owner and sound survive. Reused
Void Shard configs are normalized after loading: its serialized config previously
enabled both projectile and effect contact. Arcane Bolt and Void Shard resources
now declare the same single contact owner as runtime sync. No artwork, layout,
audio resources, costs, balance or dependency changes.

Validation against the original project with Godot 4.7.2, offline:

- New headless ownership assertions reproduced three baseline failures: unused
  effect contact field, loaded Arcane Bolt normalization and loaded Void Shard
  dual ownership. Baseline log: `.qa-tmp/bkl-050/baseline.log`.
- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation --card-lifecycle-only`:
  zero failures after implementation (`focused.log`).
- Same command with `--capture-ui`: zero failures, native D3D12 Forward+ / RTX
  2060 (`native-final.log`). Actual resolution paths for Arcane Bolt, Arcane
  Blast, Void Shard, Sever Anchor and Overload Shot each attach one contact
  visual and apply expected damage once, including the Obelisk bonus and energy
  amount. A first native fixture iteration failed five health assertions because
  it checked before pending damage completed; the fixture now waits for the
  existing pending-damage boundary with a two-second budget. That earlier run is
  retained as `native.log`.
- Full `--combat-automation`: zero failures (`combat.log`), including authorization,
  teardown, multi-hit/status configuration and cost/action checks.
- `python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --encounter res://resources/data/battles/tier_0_blobs.tres --seed 1 --policy greedy --max-turns 20 --max-actions 100 --timeout 90 --telemetry-local --output .qa-tmp/bkl-050/autowalker`:
  victory in 8 turns / 28 actions, one summon and Obelisk destruction; zero
  failures, invalid actions/AI decisions, softlocks, timeouts or configured
  aborts. Upload disabled. Fresh report, trace and logs retained there.
- `python tools/check_scene_resources.py`: zero problems. `git diff --check`:
  no whitespace errors.

Updated content-authoring/testing guides and this task's todo/progress tracking.
BKL-050 is complete. BKL-042/051 and legacy custom Effect hooks remain separate
work; they were not marked complete.

Limits: native node counts establish runtime ownership, not inspected rendered
quality, continuous animation/audio or human feel. No movie/frame comparison
(FFmpeg unavailable on PATH), campaign sweep or export checks. Existing Windows
certificate-store diagnostic and Void Spectre UID fallback warning remain. No
commit, push, deployment or release-version change.
