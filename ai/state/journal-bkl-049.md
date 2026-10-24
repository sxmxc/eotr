# BKL-049 - Battle-bound card queries, 2026-10-24

Read AGENTS.md, ai/README.md, development workflow, backlog and recent
construct-modifier/BKL-043/051/050 handoffs. Initial worktree was clean.
Selected the ready, unblocked dependency-coupling item for concrete lifecycle
and scene-reuse value. Higher-priority ready proposals need new mechanics,
balance decisions, music assets or visual direction; BKL-042 remains a broader
in-review resolver migration, not a prerequisite for this reduction.

Verified the old premise: TargetSelector already receives board/controller
references. The base Card and four overrides still rediscovered board/player
through global groups. CardUI also rediscovered actors, victory owner and HUD.

Added typed CardUI.get_battle_world using its existing injected controller.
All five candidate-query implementations now use that battle's board, player,
enemy handler and summons. Unbound/disposed bindings return no candidates.
CardUI pending-effect checks, victory checks and discard/exhaust destinations
use the same battle. Card resources store no battle references. No card costs,
effects, target predicates, movement rules, fog, RNG, signals, audio or visual
resources changed. Existing selector caches and live commitment remain intact.

This completes a reduction of coupling, not removal of every SceneTree use.
Legacy card resolution hooks, Effect nodes and CardResolver standalone context
discovery remain supported. The captured process-frame signal in CardUI is
intentional for asynchronous teardown safety. No parallel context framework or
editor assertion was introduced: detached previews safely return no candidates.

Added regression assertions for ordinary, movement, summon, relocation and
salvage previews: an unbound detached CardUI returns no cells; injecting the
controller permits queries without UI tree membership; removing global board
and player groups does not change the candidates. Existing combat/Synthforged
checks cover bound input, target parity, deployment, effects and teardown.
Updated architecture/testing guides and only this task's tracking.

Validation used the original project, Godot 4.7.2, disposable saves and offline
telemetry. Evidence under .qa-tmp/bkl-049/:

- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation --card-lifecycle-only`: zero failures (focused.log).
- Same command with `--capture-ui`: zero failures (native.log). Native state
  assertions only; no rendered images inspected or visual quality claim.
- Same launcher with `--synthforged`: zero failures (synthforged.log).
- First full `--combat-automation` run: one failure, current action completion
  advancing to next player round (combat.log). This run overlapped other engine
  checks; it is a failed run, not a pass.
- `python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --class synthforged --seed 27 --policy greedy --encounter res://resources/data/battles/tier_1_channelers_bulwark.tres --max-turns 30 --max-actions 160 --timeout 90 --telemetry-local --output .qa-tmp/bkl-049/walk`:
  victory in 12 turns/42 actions; zero failures, invalid player actions, aborts,
  timeouts or softlocks. Four AI invalid decisions remain recorded. Upload off.
- Isolated rerun of the same full `--combat-automation` command: launcher exit 0,
  zero failures (combat-isolated.log). The initial timing failure did not reproduce;
  concurrent load is a possible explanation, not a proven root cause. No pacing
  code or test deadlines were changed.
- `python tools/check_scene_resources.py`: zero problems.
- `git diff --check`: passes.

Known certificate-store diagnostic and Void Spectre UID fallback remain.
No human balance, continuous motion/audio, full campaign or export validation.
No backend contact, commit, push, deployment or release-version change.
