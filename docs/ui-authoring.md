# UI authoring

UI is built from authored scenes and one shared theme. Scenes define structure
and layout; scripts bind game data and interaction. This lets a contributor inspect
the interface in Godot's editor and change a shared style without chasing runtime
construction code.

## Layout and shared styling

Edit shared fonts, colors, spacing, surfaces and state styles in
`resources/themes/rift_ui.tres`, the project theme. Use named type variations such
as CardFace and its hover/modified states, CardCostUnavailable, EnemyQueueEntry,
ObjectiveQueueEntry, PriceUnavailable and CollapseDanger. The theme also supplies
map icons, rarity colors and intent accents. Keep styleboxes shared and immutable;
select a variation for a state instead of modifying a resource used by other controls.

Put fixed structure in `.tscn` scenes. Containers arrange content, anchors position
screen regions, and minimum sizes describe intrinsic art/icon bounds. Use
HFlowContainer for collections that wrap. A scaled card preview needs a measuring
frame that reserves its full drawn size, otherwise containers can overlap the
purchase or confirmation controls. Shared menu previews use CardMenuUI; gameplay
CardUI retains its hand/aim pivot.

Scripts can update text/visibility, select theme variations, instantiate repeated
scene instances and handle interaction. Dynamic hand geometry, cursor aiming,
world-to-screen positions, content-dependent scroll heights and state transitions
also belong in code. Expose motion tuning on the owning scene. Avoid rebuilding
fixed panels or constructing styleboxes in `_ready()`.

Card faces share `ui/card_ui/card_visuals.tscn` across hand, inspection, rewards
and deck views. Edit that scene and the theme for card layout; a separate renderer
for each screen will drift. Check long names and modified descriptions at actual
rendered size, including unaffordable cards. Smaller rules typography should be
selected from shared roles based on measured content, not a per-card local override.

## Component ownership and input

Each component owns its children: StatsUI owns StatusHandler, CardPileButton owns
its counter, and CardPopup owns confirmation actions. The parent composition root
binds player, board, camera and presentation through public properties/signals.
Avoid injecting controls into another instance's private hierarchy or using
editable children to wire gameplay dependencies.

Run composes its HUD, map legend, pause menu and tutorial. GameWorld composes its
battle HUD and tutorial. EnemyHandler receives the typed enemy rail from that
composition root. This makes binding and teardown explicit instead of depending
on whichever UI is first in a global group.

Use native button disabled, hover, pressed and focus states. Keep keyboard
activation and visible focus. Card hit areas belong to their interactive container;
decorative children should not swallow input. Unaffordable cards remain inspectable.
Pause should focus Resume and return focus to the previous control when available.
Aim/drag should dismiss competing inspection surfaces without hiding legal targets.

## Presentation and transitions

Use restrained slate surfaces, ivory text and aged-gold headings/energy with clear
teal action states. Screens share materials but have different compositions: a
left title/navigation column, calm pause shading, a readable route, open shop
shelves and a distinct card-discovery view. Route nodes use subdued opaque fills
with encounter/state accents. Keep routine currency rewards compact and consent
choices equally weighted.

Author shader parameters in material resources; give animated per-instance
uniforms local material state. Fullscreen effects must multiply incoming COLOR so
CanvasItem modulation actually fades them. Keep fullscreen geometry stationary
and animate dialog content around its own pivot. Advance on animation completion;
transient battle presentation must finish even while a tutorial pauses gameplay.
Detach an outgoing view before attaching its replacement.

Combat composition leaves the field, hand, intentions and turn/collapse information
readable together. Enemy details belong in the screen-space rail and follow fog
visibility. Movement/wait glyphs can defer wording to the rail; consequential
numeric intentions must remain readable. Phantom Camera uses the actual HUD safe
area; avoid solving a layout issue with a competing camera controller.

## Validate the interaction

Run the [scene/resource guard](testing.md) after editing scenes/themes. It rejects
local theme overrides, LabelSettings assignments, legacy scene themes and runtime
Control/style construction in first-party code; disposable test fixtures are excluded.

Use focused reward/shop, event, map or combat checks from [testing](testing.md),
then inspect the relevant native interaction. Check hover/focus, disabled state,
aim/cancel, card inspection, affordability and confirmation as appropriate. Test
long content and both the 1920×1080 reference viewport and smaller windows.
Headless checks establish behavior, not visual readability.

`python tools/validate_project.py --godot "$godot" --capture-ui` exercises the
native renderer with disposable captures in system temp, removed after exit.
Use [visual QA](visual-production.md) when evidence must remain available for
review. Report renderer/window settings and the states actually inspected.
