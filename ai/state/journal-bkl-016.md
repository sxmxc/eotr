# 2026-10-20 - BKL-016 ruin activation feedback

Read agent guidance, UI authoring rules and visual discover/direct/implement/
critique workflows, style guide and VFX standards. Initial tree was clean.

Added a scene-authored broken-column echo in aged gold, animated by a node-bound
tween for 0.45 seconds. BoardOverlay owns placement; ProcGenTilemap keeps effect
authority and adds Ancient Ruin attribution to existing outcome descriptions.
No changes to rewards, weights, RNG consumption, repeatability, sound, camera or
turn scheduling. No addon files edited. Confidence: 8/10; native phase stills
support readability, but continuous motion/audio have not been inspected.

Added a development-only ruin scenario to the existing visual capture fixture.
It pauses policy decisions, selects the occupied tile and invokes the actual
apply_tile_effects API with block then empty resources. Matching native baseline
and revised captures live under .qa-tmp/visual/ruin-before and ruin-after.
Final observation, event sequence/timestamps, trace and render settings match.
Native phase PNGs inspected; art direction and honest coverage review are in
ai/visual/specs/ruin-activation.md and ai/visual/reviews/ruin-activation.md.

Validation: focused headless and native Forward+ card-lifecycle suites pass with
zero failures, including repeat activation, empty outcome, independent overlapping
echo cleanup and lethal movement-card resolution. Scene/resource guard passes
as part of each validation invocation. Formatting checked with git diff --check.
The full headless combat automation suite also passed with zero failures.

Known limits: FFmpeg absent on PATH, so capture.py records native AVI and the
fixture saves phase PNGs; standard extracted/side-by-side video unavailable.
Context7 was consulted in the proposal; its refresh failed automatic approval
review due to account usage limits. Earlier retrieved Godot 4.7 docs used.
Existing Windows certificate-store and terrain-depth UID fallback diagnostics
remain. Bounded visual captures retain baseline exit-resource warnings.

The main journal has invalid UTF-8 (byte 0x97 at offset 58517). Preserved it and
used this separate entry, consistent with recent BKL-044/045 records.

Follow-up: optional continuous-motion/audio review and separate investigation
of startup message competition. No implementation blocker remains.
