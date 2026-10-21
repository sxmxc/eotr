# 2026-10-20 - BKL-045: board occupancy and movement query costs

## Scope and reasoning

- Followed ai/docs/agents.md and workflows.md; consulted Context7 Godot 4.7 documentation for typed dictionaries, timing and direct tile lookups.
- Plan: measure telemetry and local real-scene costs; implement only justified query improvements; verify lifecycle correctness and document results.
- Retained the current reverse BFS engagement scoring and BFS path helper. No shared A* graph or persistent path cache: neither is necessary for the measured improvement, and both add invalidation and traversal-policy complexity.
- Confidence: 8/10. Benchmarks support lower query costs, with focused runtime checks covering cache lifecycle. These are local debug measurements, not a claim about player frame rates or production latency.

## Telemetry evidence

Read-only Grafana queries used datasource telemetry-clickhouse and the deduplicated telemetry.events_deduplicated view. No dashboards, data or telemetry settings were changed.

- Window: the preceding 14 days as queried on 2026-10-20. Filters: game_id=echoes_of_the_rift, environment=qa, source_type=bot, build_version=0.2.1.0 (latest reporting build with enemy_action samples).
- 44,776 enemy_action samples: mean evaluation_us=632.37, p95=3,682, max=46,325.
- Per-enemy p95: Rift Needle=7,068 us (3,868 samples); Hollow Siphon=5,351 us (729); Obelisk=3,939 us (17,740).
- evaluation_us is measured in Enemy.do_turn before perform_action. It includes eligibility/reselection; it does not isolate occupancy, all movement calculations, animation time, or total turn latency. This is bot QA data, not human player performance.
- simulation_completed outcomes: 1,900 wins, 586 losses, one softlock. The softlock followed a TREASURE route action at floor 9 with no current encounter and reason 'No completed action or turn in 30 seconds'. No evidence ties it to occupancy.
- Queries aggregate count, avg, quantileExact(0.95) and max of JSONExtractFloat(properties,'evaluation_us'), grouped by build/source or enemy; failures are grouped by JSONExtractString(properties,'outcome'). Dashboard query reference: backend/telemetry/grafana/dashboards/enemy-ai.json.

## Implementation

- ProcGenTilemap indexes actors by logical cells, with a reverse index for bounded cleanup. Actor lists preserve overlap safety during cleanup. is_tile_free is now a dictionary lookup.
- Enemy registration happens before ready/intent evaluation, including summons. Enemy position changes update the index; player movement/teleport commit logical occupancy immediately.
- Moving enemies reserve source and destination. Cancellation releases the destination; completion releases the source. Death invalidates movement and clears occupancy before the cosmetic fade. Tree exit and regeneration also clear entries.
- Collapse queries only occupants of each removed cell and cancels movement reservations before erasing terrain.
- is_within_bounds uses TileMapLayer.get_cell_source_id instead of creating/scanning get_used_cells arrays. TileMap remains authoritative, including manually erased cells.
- Existing timings, sounds, VFX, card balance, traversal rules and path scoring remain in place. No addons or release version files changed.

## Measurements

Fixed seed 42, real GameWorld scenes, 79-cell generated boards, 100 full-board occupancy sweeps and 20 movement calculations per moving enemy. Separate local headless invocations; timing varies with load. Measurements are informational, with no flaky wall-clock assertions.

| Encounter | Enemies | Before occupancy us/query | Before movement us/calculation | After occupancy us/query | After movement us/calculation |
| --- | ---: | ---: | ---: | ---: | ---: |
| tier_0_blobs | 4 | 4.36 | 3504.02 | 0.52 | 1659.67 |
| tier_1_channelers_bulwark | 5 | 5.03 | 3615.95 | 0.46 | 1747.19 |
| tier_2_void_spectre | 2 | 3.46 | 2912.40 | 0.29 | 1397.00 |

Occupancy caching alone did not reliably reduce full movement calculation time; eliminating repeated terrain-array allocation/scans supplied the larger movement improvement. Combined samples show about 52% lower movement query cost. Native-renderer timings are not compared directly with headless baselines.

## Verification and limitations

- python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --board-queries
- Same command with --capture-ui runs the real native renderer offscreen. Checks cover spawn parity, movement reservation/completion/cancellation, stale deferred completion, player movement/teleport, overlapping cleanup, tree exit, death during movement, collapse, summons and regeneration.
- Full --combat-automation suite: 0 failures.
- AutoWalker greedy seeds 1-3 for tier_0_blobs, tier_1_channelers_bulwark and tier_2_void_spectre: nine completed battles, three wins/six losses, zero reported simulation failures, invalid player actions, softlocks or timeouts. QA telemetry kept local.
- Before the status fix, the blob launcher exited successfully but channeler/spectre launchers rejected status teardown script errors: StatusHandler._release_status called remove_status with a previously freed owner. Those initial runs were not clean test passes. The errors are resolved below; both batches now exit cleanly.
- To verify attribution, temporarily applied the original HEAD versions of the four modified runtime scripts to the actual project using apply_patch, ran the same channeler seeds, then restored all changes using apply_patch after checking for concurrent edits. No project clone, checkout/reset or addon edits. Baseline reproduces the same status teardown errors. Baseline/changed summaries match wins/losses, turn_counts=[7,4,13], damage_taken=[35,35,6], summons=3, invalid_actions=0, ai_invalid_decisions=3. The last metric records existing rejected AI intents, not invalid player actions.
- Original evidence: .qa-tmp/bkl-045/bkl-045-blobs/, .qa-tmp/bkl-045/bkl-045-channelers/, .qa-tmp/bkl-045/bkl-045-spectre/, .qa-tmp/bkl-045/bkl-045-baseline-channelers/. Moved this task's four output directories out of the mistakenly created qa/ folder and removed that empty directory. Fixed-run reports are in .qa-tmp/bkl-045/channelers-fixed/ and spectre-fixed/. The launcher now defaults to .qa-tmp/autowalker and restricts custom output to .qa-tmp subdirectories. Retention covers the selected output only, preserving sibling investigations/captures. Nine launcher regressions pass, including path confinement and retention scope. Updated ai/docs/autowalker.md accordingly.
- Windows root certificate store error is already allowlisted by validation; backend-free checks continue successfully.
- Expanded successive-collapse fixture initially let the player die before a second shrink, causing invalid-player access. Moved the fixture player to safe interior cells before each shrink; the final focused tests pass, including cancellation of a reserved collapsing destination.
- Unexpected external workspace change during validation: project.godot config/build changed from 3029179 to 8045fc6. Left intact; this task does not edit build/version settings.
- Main ai/state/journal.md contains invalid UTF-8 (byte 0x97 at offset 58517), so this sidecar records the work without rewriting unrelated journal contents.

## Follow-ups

1. Manually review battle movement, teleport and death presentation. Native automated checks execute the renderer but do not replace a visual playthrough.
2. Profile larger boards/enemy populations before considering shared A* or persistent paths. Existing evidence does not justify that complexity.

## BKL-052 - resolve the status teardown errors in this change

The user required these errors to be resolved rather than deferred. Reproducing them on the pre-occupancy runtime established attribution, not permission to leave failing checks.

- Godot rejects a freed Object passed to a typed Node parameter before the callee's is_instance_valid guard can execute. StatusHandler now passes null when the owner has already been destroyed, allowing cleanup to run.
- Strength and Attunement retain their exact bound status_changed callback so removal can disconnect it even when the owner argument is null. They no longer attempt to reconstruct the callback with a different target. Modifier cleanup on surviving owners stays intact.
- Status application cancels its tween when the owner is gone instead of passing a freed object into another typed call.
- Expanded status_lifecycle_test.gd to destroy the owner before an independent UI handler, retain all four status resources, test explicit removal and handler teardown, mutate resources afterward, and reject queued applications to the freed owner. Existing handler-first modifier/signal cleanup tests remain.
- Focused status lifecycle validation: 0 failures. Channeler and spectre greedy seeds 1-3 were rerun using the actual launcher under .qa-tmp; both launchers exit 0 with zero script errors, zero simulation failures, zero invalid player actions, softlocks or timeouts. Both batches retain the same wins/losses, turn counts and damage totals as before the status fix.
- BKL-045 and BKL-052 are complete. No unresolved code/test blockers remain for these changes. The main journal encoding issue and external project.godot build hash change are recorded above.
