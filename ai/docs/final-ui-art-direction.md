# The Rift — final UI presentation pass

Correction after developer visual feedback: removed the route atlas texture,
underpaint and sidewall decoration. The atlas mapping produced distracting
patchwork rather than convincing stone. Nodes now use opaque subdued fills;
encounter accents, current marker, progression and keyboard navigation remain.
Updated native evidence: `.qa-tmp/art-direction/node-fix/`.

Implemented on 2026-10-20, continuing the previous cohesion pass. The existing
illustrations, experimental title, combat feedback and gameplay remain authoritative.

## Composition decisions

**Pause.** A left composition under directional dark shading replaces the gray
wash, particles and oversized sans heading. Serif typography and a prominent
Resume action preserve the world's atmosphere without a decorative panel.
Focus enters Resume and returns to the previously focused control when available.
The existing checkpoint/save handler is unchanged.

**Main menu.** The title has restrained shadows and a clearer small-The/large-Rift
hierarchy. Navigation now belongs to that title column; workshop links and build
information move to separate quiet footers. New Run is primary on a fresh save;
Continue receives the primary role when a saved expedition exists. Artwork and
the intentionally hidden Echoes label are preserved.

**Route.** Existing atlas stone, shallow broken sidewalls and an opaque underpaint
give nodes a material relationship to the floating world. Encounter glyphs have
selective accents. Gold/current diamond, reachable teal and subdued future paths
communicate progress. Repeated Battle labels yield to glyphs; focus reveals the
encounter/state. The route begins lower, exposing more upcoming choices. Legend
chrome is lighter. Native focus buttons add keyboard access to available nodes
through the existing select_route function; mouse collision/navigation is retained.

**Shop.** Existing shared cards render at 1.25× (56% more artwork area), with a
measuring frame that reserves their actual scaled bounds. They sit on open shelves
rather than nested panels. Smaller purchase controls give attention back to art,
names and prices; relic identities/descriptions remain alongside compact actions.
Unavailable prices and disabled controls remain clear. Purchase confirmations use
the existing footer and all currency/transaction behavior is retained.

**Rewards.** Currency rows are compact; card/relic discovery receives a larger
surface and explanatory secondary line. The card choice display uses 1.3× shared
cards and a focused presentation with stronger heading. Inspection is also larger.
Routine collection has no added delay; existing claim/skip/confirmation remains.

**Combat.** Movement and wait glyphs replace repetitive world labels; numeric and
consequential intentions remain. Full wording stays in the enemy rail/tooltips.
Removing the empty inspection reservation lets more enemies fit without scrolling.
Short turn prompts, on-demand camera help and quieter battle-spoils information
reduce competition with the battlefield and hand. Existing camera behavior,
tile targeting, character art, statuses and effects are retained.

Independently found and fixed a scaled-card pivot overlap and clipped long rules.
Static menu previews scale from their top-left inside their own measured frame.
Shared typography roles select a smaller rules size only when shaped text needs
it; Corroding Shot copy is shorter while preserving damage, target, stacks and
end-of-turn true-damage/block-shred information. Its values and effects are unchanged.

## Before and after

Native screenshots from production scenes in the original project, not mockups.
Before/final suites use 1920×1080 windows. The first revised suite and focused
transaction/route checks use 1280×720 windows. The project keeps its intended
1920×1080 reference viewport and viewport stretch at both window sizes.

| Screen | Before | Final |
| --- | --- | --- |
| Pause | [before](../../.qa-tmp/art-direction/before/Godot/app_userdata/echoes_of_the_rift/overhaul-pause.png) | [final](../../.qa-tmp/art-direction/final/Godot/app_userdata/echoes_of_the_rift/overhaul-pause.png) |
| Main menu | [before](../../.qa-tmp/art-direction/before/Godot/app_userdata/echoes_of_the_rift/overhaul-menu.png) | [final](../../.qa-tmp/art-direction/final/Godot/app_userdata/echoes_of_the_rift/overhaul-menu.png) |
| Route | [before](../../.qa-tmp/art-direction/before/Godot/app_userdata/echoes_of_the_rift/overhaul-map.png) | [final](../../.qa-tmp/art-direction/final/Godot/app_userdata/echoes_of_the_rift/overhaul-map.png) |
| Shop | [before](../../.qa-tmp/art-direction/before/Godot/app_userdata/echoes_of_the_rift/overhaul-shop.png) | [final](../../.qa-tmp/art-direction/final/Godot/app_userdata/echoes_of_the_rift/overhaul-shop.png) |
| Rewards | [before](../../.qa-tmp/art-direction/before/Godot/app_userdata/echoes_of_the_rift/overhaul-rewards.png) | [final](../../.qa-tmp/art-direction/final/Godot/app_userdata/echoes_of_the_rift/overhaul-rewards.png) |
| Card discovery | [before](../../.qa-tmp/art-direction/before/Godot/app_userdata/echoes_of_the_rift/overhaul-reward-selection.png) | [final](../../.qa-tmp/art-direction/final/Godot/app_userdata/echoes_of_the_rift/overhaul-reward-selection.png) |
| Combat | [before](../../.qa-tmp/art-direction/before/Godot/app_userdata/echoes_of_the_rift/overhaul-combat.png) | [final](../../.qa-tmp/art-direction/final/Godot/app_userdata/echoes_of_the_rift/overhaul-combat.png) |

Also inspected final shop-unaffordable, reward-confirm, and the progressed route
under `.qa-tmp/art-direction/route-check/`. Prototype captures were removed.
Latest transaction captures include the final rules-space adjustment; the other
final-suite screenshots precede that nine-pixel text-area refinement. The saved-
Continue styling branch was added after the fresh-save menu capture; fresh-save
appearance is unchanged, saved-state styling has not been separately captured.

## Validation and limits

- Scene/resource/style guard: zero problems. Whitespace check passes.
- Native before, first revision and final presentation suite: zero failures.
  Exercises pause/Resume, focus, route focus, camera-help toggle, card inspection,
  reward choice/confirmation/skip and one-time card/relic purchases.
- Native route checks: zero failures, including real keyboard activation,
  unavailable/duplicate selection protection, connector endpoints and progressed
  current/reachable states. Mouse input continues through existing Area2D logic.
- Headless card layout checks: zero failures for wide/narrow flow, selection,
  shared-style isolation, hover restoration and long-description fit. Native reward
  transaction check additionally asserts actual reward text stays within the face.
- Full headless combat automation: zero failures during this pass. Combat rules,
  animations, TileMap and PhantomCamera implementations were not changed here.
- Existing visual pipeline: 12-second native 30 fps capture in
  `.qa-tmp/visual/art-direction-final`, compared to prior cohesion-final. All ten
  actions match with zero start drift; setup and final observation match.
  Inspected frames at 1.450, 2.733 and 11.833 seconds. See its persistent review.
- The earlier full-suite hidden-route-particle position assertions remain an
  existing issue; this task used focused UI/layout/route checks, not a new broad
  particle audit.

No additional bitmap assets, dependencies, shaders, UI framework or production
capture tooling. Continuous video/audio, ultrawide, exports, full campaign and
hardware performance were not reviewed. Large combat boards retain the existing
tactical framing tradeoff and full-board overview control. The static menu scale
property is set before adding the preview to its container; live rescaling of an
already-mounted preview is not a supported interaction.
