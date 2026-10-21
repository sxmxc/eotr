# Presentation cohesion — 2026-10-20

Direction: illustrated slate and weathered masonry, restrained teal magic, ivory
type and selective aged gold. Preserve the floating island silhouette and void.
Existing card paintings, actor art, effects and authored collapse debris remain.

Native baseline: `.qa-tmp/cohesion/before/Godot/app_userdata/echoes_of_the_rift/`;
terrain baseline: `.qa-tmp/cohesion/terrain-before/` (same userdata suffix).
Inspected menu, combat, route, shop, rewards and event screenshots at 1920×1080.
Observed: inset outlined resource tiles dominate material; landmark symbols are
oversized; tall units clip against the run HUD; secondary camera help competes
with turn information; reward page loses the illustrated world; route sidebar
occupies nearly the entire screen height. Preserve experimental “The Rift” title
(hidden Echoes is intentional, confirmed by the developer).

Implementation stays in shared theme, existing scenes, cached terrain drawing
and PhantomCamera framing. Sidewalls must rebuild from surviving TileMap cells;
no independent tile nodes, gameplay RNG, alternate camera or new UI framework.
Keep target masks, intent badges, collapse fractures, contact anchors, spell
choreography and actual-art debris. Use native existing fixtures to check two
successive real shrinks and transient cleanup. Bound before/after review to one
main capture and a correction only for visible defects. Stills cannot establish
continuous animation or sound quality.

Baseline full UI fixture: two existing failures for positions of hidden route
particle emitters. Baseline native terrain fixture: zero failures.
