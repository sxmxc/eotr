# BKL-046 — Shared hex geometry and sight, 2026-10-24

Completed shared cell distance, disk/ring and player sight APIs on ProcGenTilemap.
The first partial handoff is superseded: the coordinate discrepancy was resolved,
not deferred. The authored TileSet uses TILE_LAYOUT_DIAMOND_DOWN (5), with engine
neighbors (1,-1), (1,0), (0,1), (-1,1), (-1,0), (0,-1) at both sampled anchors.
The old odd-q conversion was incorrect. Historical conversion method names remain,
but cells now map to cube (x,y,-x-y). Negative coordinates and translated cube
footprints follow the same convention. No authored range, damage or cost changed.

Cards use shared rings for adjacent targeting/resolution. Construct distance,
boss range/ram and AI distance weights use cell_distance; SummonHandler.distance
remains a compatibility wrapper. Player fog sight is shared by enemy visible
footprints, selector picking and card preview cells: source and target must exist,
and target must be persistently revealed. There is no terrain/unit ray occlusion
in current mechanics; AI does not use player fog. Existing live target authority,
input, effects and presentation paths remain in place.

Audited bounded get_surrounding_tiles_in_radius callers (moving enemies, tactics,
Obelisk spawn, Synthforged deployment and bat/wasp/spectre movement). These retain
neighbor traversal and its ordering/center behavior because a geometric disk
would cross missing terrain and change gameplay. Documented the distinction in
docs/architecture.md and docs/combat.md rather than silently replacing reachability.

Validation on original project, Godot 4.7.2, offline/disposable saves:
- tools/validate_project.py --board-queries: 0 failures, exit 0. Positive/negative
  coordinate round trips, six engine neighbors, disk/ring counts, symmetry,
  uniqueness, boundary membership, zero/negative radii and sight fog/bounds checks;
  three encounter occupancy/movement/collapse lifecycle fixtures also pass.
- --combat-automation: 0 failures, exit 0.
- --combat-automation --card-lifecycle-only: 0 failures, exit 0 after selector edit.
- --synthforged: 0 failures, exit 0.
- tools/validate_campaign.py --bosses-only: 0 errors/failures, exit 0.
- tools/check_scene_resources.py: 0 problems; git diff --check passes.
All validation commands used --godot
D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe.

Real sequence: tools/run_autowalker.py with seed 27, greedy/default tier_1,
encounter res://resources/data/battles/tier_1_channelers_bulwark.tres,
--max-turns 30 --max-actions 160 --timeout 90 --telemetry-local
--output .qa-tmp/bkl-046-walk: win, 9 turns, 38 actions, zero invalid player
actions/failures/aborts/timeouts/softlocks. One AI intent revalidation recorded.
Evidence: .qa-tmp/bkl-046-walk/{summary.json,simulation-27.json,godot.log}.

Existing certificate-store diagnostic and Void Spectre UID fallback remain.
No rendered review, human balance, full campaign or packaged export claim.
Corrected geometry can change range decisions/footprints that previously used the
wrong convention; bounded suites and one battle do not establish campaign balance.
No backend contact, commit, push, deployment or release-version change.
