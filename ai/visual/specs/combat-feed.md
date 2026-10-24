# Combat event feed

The player must understand the cause and actual HP loss after enemy resolution.
Trace: enemy action or status/ruin -> DamageEffect -> Player.take_damage callback
-> Stats application -> HP delta -> existing world_message_requested -> authored
WorldMessageContainer/WorldMessage scenes. Collapse calls Player directly with
an explicit cause. EnemyStats supplies display names; board fog, not camera
position, controls identity disclosure. There is no remembered identity model.

Keep damage, modifiers, block bypass, costs, RNG, turn scheduling, visibility,
targeting and PhantomCamera ownership unchanged. Existing reaction, sound and
block-fracture feedback remain; floating player numbers use actual HP loss.
The feed has slate contrast, left alignment, no rounded frame, and a restrained
outcome edge. Four rows and forty history entries bound data; native scrolling
bounds geometry. History replaces live rows while expanded.

Baseline: `.qa-tmp/visual/combat-feed-before/frame-03.png` visibly contains
"Wasp1 flys closer to player" in a centered bordered panel. Revised matched
stills: `.qa-tmp/visual/combat-feed-after/`. Extended real action log:
`.qa-tmp/visual/combat-feed-outcomes/`. Settled controlled outcomes/history:
`.qa-tmp/combat-feed/`. Reviews record observed and unexercised areas. Sparse
stills do not establish continuous timing, audio, or exhaustive encounter coverage.
