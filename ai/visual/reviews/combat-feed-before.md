# combat-feed-before

Native Godot 4.7.2 Forward+ (D3D12), seed 1, tier_0_blobs,
1920x1080 viewport; offline AutoWalker still capture. Evidence:
`.qa-tmp/visual/combat-feed-before/` (scenario, commands, timing, logs, three PNGs).

Frame 03 inspected. Baseline shows a centered, outlined notification with internal Wasp1 naming.
The 12-second before/after captures share setup. The 28-second outcomes capture
extends gameplay and its log records repeated Obelisk and Wasp damage.

Additional controlled native evidence: `.qa-tmp/combat-feed/outcomes.png` and
`history.png`, inspected after the feed was bounded to avoid camera-help overlap.
Real Player/DamageEffect, status and ruin APIs were used; initial block/fog were
controlled. These are fixtures, not a natural combat replay. Fixture log records
zero failures. Window 1280x720, virtual viewport 1920x1080.

Observed: combat feed, floating damage values, battlefield/fog context.
Not assessed from sparse frames: continuous reactions, spell identity, camera
impulses, targeting highlights, collapse motion, environmental animation/audio.
No claim of continuous animation or every boss/layout scenario acceptance.
