# Void Channeler visibility

The Void Channeler must use its authored creature silhouette at the existing
moving-enemy scale. EnemyStats.board_icon feeds MovingEnemy/Enemy Sprite2D and
Utils.ground_sprite; the resource incorrectly referenced the 64px eye UI glyph.
Use the existing 512px assets/rift/entities/channeler.webp. Preserve fog,
selection, occupancy, AI, intent, damage, RNG and camera behavior.

Native controlled evidence: .qa-tmp/channeler-visibility/before.png and
capture.png, both inspected. Godot 4.7.2, D3D12 Forward+, 1280x720 window,
1920x1080 viewport, seed 42, tier_1_channelers_bulwark. Original project,
isolated temporary saves, offline validation. Fixture starts the real battle
and reveals fog through hide_fog for inspection; no combat is reimplemented.
Run with python .qa-tmp/channeler-visibility/launch.py while fixture is retained.

Before: two tiny eyes at the Channeler positions, despite visible enemy rows.
After: both grounded hooded Channeler illustrations are visible at unit scale.
Resource guard: zero problems. Existing certificate-store error and unrelated
stale encounter UID warning remain. This static binding check does not assess
combat animation, audio, collapse, or fog transitions.
