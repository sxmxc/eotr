# Implement workflow

1. Follow the event spec and preserve the discovery invariants. Inspect existing presentation hooks before editing. Keep mechanics in the existing execution path.
2. Choose native Godot techniques for the intended material and motion: authored sprites, animation, particles, local shaders, Tweens or existing camera hooks. Respect body/ground anchors and avoid material sharing bugs. Do not create a parallel combat simulator.
3. Keep the fixture development-only and telemetry local. New scenario fields need explicit validation and documented interpretation. The scenario selects a real encounter/policy/replay, never an assumed projectile/beam/teleport category.
4. Run bounded relevant validation and one revised capture with the baseline settings. Check errors, desired event presence, action comparison and final state; investigate mismatches before visual attribution.
5. Hand critique the spec, actual changed files, baseline/revised videos, frame indexes, timing, comparison and known limitations. Do not call the change visually successful merely because it parses or tests pass.
