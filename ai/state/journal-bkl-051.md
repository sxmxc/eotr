# BKL-051 — Projectile migration verification, 2026-10-24

Closed the unblocked P2 in-review continuation after reading the workflow,
backlog and recent BKL-046/048/050 handoffs. Initial worktree was clean.
Selected this bounded completion over ready proposals requiring new gameplay,
balance, music assets or visual direction. BKL-049 remains separate work.

Verified the old migration premise against code: all five resources declaring
projectile_fx are Arcane Bolt, Arcane Blast, Void Shard, Sever Anchor and
Overload Shot. The first three use synced configs/base Card resolution;
Sever Anchor and Overload Shot compute their conditional damage and call
CardResolver. No card scripts instance projectiles, own projectile timeouts or
shake the camera directly. CardFxRunner owns pre-hit projectile sequencing and
timeouts; CardResolver applies camera impact from configs/profiles. Legacy
non-projectile effects and cosmetic cast_fx remain supported.

Added a source-pattern guard to tools/check_scene_resources.py for direct
ProjectileFX use, projectile_fx instancing, direct projectile scene
load-and-instance expressions and force-completion wiring in card scripts.
Two offline unittest cases exercise allowed configuration/comments and five
rejected lifecycle patterns, including multiline instancing. This is a bounded
architectural guard, not a GDScript parser or proof against aliased code paths.
Updated authoritative content-authoring/testing guides and task tracking.
No gameplay, presentation, costs, assets, dependencies or release versions changed.

Validation against the original project, Godot 4.7.2, offline/disposable saves:

- `python tools/test_card_projectile_authoring.py`: two tests pass.
- `python tools/check_scene_resources.py`: zero problems.
- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation --card-lifecycle-only --capture-ui`:
  exit 0, zero failures. Existing real resolution assertions cover all five
  projectile cards, one contact/one damage, conditional Obelisk and energy
  damage, serialized configuration ownership and lifecycle teardown.
  Log: `.qa-tmp/bkl-051/native.log`.
- Same Godot launcher with `--combat-automation`: exit 0, zero failures.
  Log: `.qa-tmp/bkl-051/combat.log`.
- `git diff --check`: passes.

Native assertions do not establish inspected visual quality, continuous motion,
audio or human feel. No gameplay change required a new AutoWalker sequence;
no campaign sweep or export review. Existing Windows certificate-store diagnostic
and Void Spectre UID fallback remain. No backend contact, commit, push or deployment.
