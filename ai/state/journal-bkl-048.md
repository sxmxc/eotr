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

## 2026-10-22 continuation: gesture input coordination

Selected the actionable, unblocked continuation of this P2 integration task after
reviewing the latest handoffs and ready backlog. Other ready P2 items introduce
new mechanics or require visual/design work. Verified that clicked/drag/aim states
still decided input transitions themselves and discovered board/selector groups.

Moved their motion, confirm and cancel decisions into CardInteractionController.
GameWorld exposes its authored TargetSelector; the controller uses that selector's
cache for highlights, and drag reparenting uses its owning battle UI. Right-click
cancellation now clears targets for clicked/drag states as it already did for aim.
Removed an unused drag-threshold timer (its flag was never read). Existing state
presentation hooks, feedback signals, aim scan sound, animation parameters,
selector activation, hand restoration and live release authorization remain.
Updated architecture, combat and testing guides plus this task's tracking.

Validation on the original project with Godot 4.7.2, offline:

- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation --card-lifecycle-only`:
  exit 0, zero failures. New assertions cover clicked/drag/aim cancellation,
  drag-to-aim selector/sibling state, hand order restoration, bottom cancel zone,
  both confirm edges without a target, non-single-target dragging and unchanged
  energy/action lock. Initial fixture failures came from headless cursor coordinates
  and deferred card re-enablement; the fixture now derives its cancel boundary
  from the cursor and waits one frame after returning to hand.
- Full `--combat-automation`: exit 0, zero failures.
- `python tools/check_scene_resources.py`: zero problems; `git diff --check`: pass.
- `python tools/run_autowalker.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --encounter res://resources/data/battles/tier_0_blobs.tres --seed 1 --policy greedy --max-turns 20 --max-actions 100 --timeout 90 --telemetry-local --output .qa-tmp/bkl-048/gesture-autowalker`:
  exit 0, win in 8 turns / 28 actions, one summon and Obelisk destruction; zero
  failures, invalid actions/AI decisions, softlocks, timeouts or configured aborts.
  Upload disabled; fresh reports and log retained in that output directory.

Limits: BKL-048 remains in progress. Active-gesture lifetime, phase/teardown
cancellation and unified highlight/tooltip context remain future work. State
enter/exit still own presentation/feedback signals, and TargetSelector still
consumes them. Synthetic input checks and bot gameplay do not establish rendered
quality or human interaction feel. No native visual inspection, campaign sweep
or export checks. Existing certificate-store and Void Spectre UID diagnostics
remain. No commit, push, deployment, release version or balance changes.

## 2026-10-22 completion

Completed the remaining implementation rather than leaving another partial slice.
CardInteractionController now owns the exclusive selected/dragged/aimed card,
state transitions, sibling locks, cancellation and play authorization/resolution
ownership. CardStateMachine/state scripts retain presentation hooks. Feedback
signals remain for camera, hints and enemy inspection; CardUI sibling locks and
TargetSelector activation no longer subscribe to them as authority.

Phase changes synchronously return an active dragged/aimed card to the logical
hand before cleanup. Hand-readiness/affordability changes cancel invalid gestures;
card removal and world teardown clear ownership, selector and tooltip state and
balance feedback. Weak registrations reconcile after reparenting rather than
mistaking a normal tree exit for destruction. Computed locks preserve disabled
cards across deferred hand restoration and prevent another card stealing a
gesture. Spotlight cards share injection and wait for logical hand ownership.

Selector picking and tooltip enemy modifiers use the controller's active-card
target predicate and cached cells. Fog, board presentation, enemy lifecycle and
player-stat changes invalidate the context. Hidden/dying targets disappear from
selection, highlights and tooltip modifiers together. Empty target sets cannot
act as wildcards. Self/area cards retain the authored CardDropArea through
controller-owned overlap updates; accepted tile targets survive cache resets
until their real effects complete and are then freed. Cost/effect/RNG paths,
artwork, layouts, animations, input gestures and campaign rules are preserved.

Final validation against the original project, Godot 4.7.2, offline:

- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation`: exit 0, zero failures.
- `--combat-automation --card-lifecycle-only`: exit 0, zero failures during
  implementation. Expanded coverage includes all gesture/phase boundaries,
  destroyed gesture owners, unavailable hands, exclusive selection, shared
  fog/death/tooltip invalidation, spotlight handoff and actual world teardown.
- Final `--combat-automation --card-lifecycle-only --capture-ui`: native D3D12
  Forward+ / RTX 2060, exit 0, zero failures. Successful mouse-release assertions
  use the authored drop area and real block/gather effects, test duplicate release,
  exact live cost, committed tile-target lifetime and resolution-lock release.
- `python tools/check_scene_resources.py`: zero problems; `git diff --check`: pass.
- Bounded offline AutoWalker: same tier_0_blobs / seed 1 / greedy / 20 turns /
  100 actions / 90-second timeout as above, output
  `.qa-tmp/bkl-048/completed-autowalker`. Exit 0, victory in 8 turns / 28 actions,
  one summon, zero failures, invalid actions/AI decisions, softlocks, timeouts or
  configured aborts; upload disabled. This run's `enemy_died`/stat events record
  the Obelisk death, but the summary reports zero `obelisk_destructions`: the
  existing GameWorld callback ignores the later tree-exit notification once
  battle_over_handled is set. That telemetry ordering defect is outside this task;
  do not interpret that summary counter as a surviving Obelisk.

Initial expanded-test iterations exposed fixture problems (same-frame deferred
re-enablement, fog represented by dictionary absence, wrong restored atlas source,
and initial pending effects before teardown setup). A temporary occupied-cell
filter in the implementation also rejected harvesting the player's resource
cell; it was corrected to use board bounds and card legality rather than movement
occupancy. The final mouse/drop-area tests protect that presentation/gameplay
contract. One test parse failure from inferred weakref typing was corrected and
its bounded runner interrupted before rerunning.

BKL-048 is complete in todo/progress tracking. Architecture, combat and testing
guides describe the final ownership. Native assertions establish runtime state,
not inspected visual quality or continuous audio/motion. No human interaction,
full campaign or export review. Existing certificate-store and Void Spectre UID
diagnostics remain. No commit, push, deployment, balance or release changes.
