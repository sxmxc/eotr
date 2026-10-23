# BKL-048: shared card-play authorization

## 2026-10-22

Selected the ready, unblocked P2 interaction task as a bounded integration change
without new mechanics or balance decisions. Verified current code first: CardUI
already owned live play checks and pending-effect waits; release duplicated a
subset of targeting checks, dereferencing Enemy targets before validity checks.
The existing TargetSelector and state machine remain in use.

Added a scene-authored, battle-owned CardInteractionController. GameWorld injects
it into PlayerHand, which passes it to both ordinary and spotlight draws. It owns
live authorization and the resolving-card lock. CardUI.can_execute and play both
use it, so mouse release and AutoWalker share the boundary. Invalid/freed/queued
targets and foreign enemy/board targets are rejected before card-specific checks.
Only the card that acquired the lock can release it. CardUI copies the accepted
target array before asynchronous resolution and retains existing effect waits,
lethal-movement teardown, hand release, victory checks and burn feedback.

Removed release's duplicate validation. Failed release still reports the existing
message and returns to hand. No layout, artwork, sound, timing, card cost, fog,
target range, phase or effect rules were redesigned. Updated architecture, combat
and testing guides plus this task's backlog/progress tracking.

Validation on the original project with Godot 4.7.2, offline:

- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation --card-lifecycle-only`: exit 0,
  zero failures. New assertions cover stale phase/cost, foreign board, freed
  target release, duplicate authorization and lock ownership. Existing repeated
  ruin feedback and detached lethal movement checks pass. Initial fixture runs
  failed three assertions because the first candidate was a corrupted start cell;
  the fixture now chooses a valid visible cell and waits for deferred hand setup.
- Full `--combat-automation`: exit 0, zero failures, including lifecycle,
  cancellation, cost/modifier, card commit and victory checks.
- `python tools/check_scene_resources.py`: zero problems. `git diff --check`: pass.
- `python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --encounter res://resources/data/battles/tier_0_blobs.tres --seed 1 --policy greedy --max-turns 20 --max-actions 100 --timeout 90 --telemetry-local --output .qa-tmp/bkl-048/autowalker`:
  exit 0, win in 8 turns / 28 actions, one summon and Obelisk destruction; zero
  failures, invalid actions/AI decisions, softlocks, timeouts or aborts. Upload
  disabled. Reports and logs retained in that output directory.

Limits and continuation: BKL-048 remains in progress. Drag/aim input, selector
highlight/tooltip context and cancellation ownership still span existing state
scripts and Events. This implements the play boundary, not the full interaction
controller. No rendered inspection, human interaction review, campaign sweep or
export validation. Existing Windows certificate-store diagnostic and Void Spectre
UID fallback warning remain. No commit, push, deployment or version change.
