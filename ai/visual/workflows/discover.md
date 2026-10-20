# Discover workflow

1. Read STYLE_GUIDE.md and VFX_STANDARDS.md. Check git status and preserve existing work.
2. Find the event's resource, caller and execution path with rg. Follow CardUI -> resolver/config -> CardFxRunner -> effect -> recipient reaction, or the corresponding real movement/enemy/terrain path. List affected entities, anchors, camera, sound, targeting, terrain, UI and cleanup dependencies.
3. Record mechanics that must remain invariant: target legality, costs, damage/statuses, waits, turn transitions and RNG. Inspect actual artwork and current shaders/scenes; cite paths and separate code inference from visual observation.
4. Select a minimal reproducible encounter/seed in tools/visual_pipeline/scenarios/. For a rare/new event, use a real AutoWalker replay trace or extend the development fixture through existing setup/execution APIs; never implement the ability again. Identify the exact action expected and any setup limitations.
5. Run the baseline command in run.py --help. Verify the desired event is actually present in timing.json, inspect representative frames and record the baseline location in ai/visual/specs/<event>.md. If absent, change seed/encounter/replay before proceeding.
6. Hand direction a concrete discovery record: implementation links, sequence, timing evidence, target relationships, dependencies, invariant list and unexplored risks.
