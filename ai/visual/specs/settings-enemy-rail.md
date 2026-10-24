# Settings and enemy rail

2026-10-23. Implementation: `scenes/menus/settings_menu.*`,
`scripts/autoloads/game_settings.gd`, `scenes/run/pause_menu.*`,
`ui/enemy_ui/enemy_queue_entry.*`, shared `resources/themes/rift_ui.tres`.

Baseline: `.qa-tmp/settings-rail/before-settings.png` and `before-combat.png`,
Godot 4.7.2, D3D12 Forward+, RTX 2060, 1920×1080, seed 472001,
`tier_1_channelers_bulwark`. Those initial images omit HDR encoding; use them
for layout comparisons only. Final `verified-*.png` captures encode HDR correctly.
`verified-native.log` records the offline native suite.

Observed baseline problems: one nonfunctional resolution choice; inconsistent
fullscreen preview/save; absent Music/UI controls; dense Button text mixing
health, name and long plans. Final settings have staged Apply/Cancel, audio
preview/rollback, window sizes, VSync, defaults and pause access. Queue scenes
separate health, name, block and a two-line plan. Content measurement prevents
overlap. Existing artwork and rail/camera safe areas remain in use.

Inspected final captures: settings-edited, settings-720p, rail-fog, rail-revealed,
rail-inspected and rail-siphon. Fog placeholders disclose presence only and
cannot select/highlight actors; actual inspector and targeting remain fog-bound.
The Siphon fixture reuses its catalog resource/action with controlled positioning.
Gameplay damage, turn transitions, costs, targeting and RNG are unchanged.

Focused native suite: zero failures, including persistence, bad/partial config,
failed-save recovery, cancellation, defaults, pause focus, native window/VSync,
fog conceal/reveal, death, block/health and two-line containment. Card lifecycle
suite: zero failures. AutoWalker Hollow Orbit, greedy seed 1: win, 12 turns,
51 actions, zero invalid actions/softlocks. Fullscreen/multiple monitors and
continuous animation/audio were not exercised. Known certificate-store error
and pre-existing void-spectre UID warning remain outside scope.
