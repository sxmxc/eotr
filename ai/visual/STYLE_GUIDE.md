# Echoes of the Rift visual direction

Ground every decision in the current checkout, then inspect a native capture. The illustrated Riftwalker, creatures, card art under `assets/rift/`, and `assets/rift/terrain/hex_atlas.png` are the visual references; do not replace them with generic pixel art or uniform geometric glows.

## World and composition
The battlefield uses 64-pixel pointy hexes, illustrated stone, crystal sockets, mana pools and a dark rift atmosphere. Keep the terrain subdued behind combat silhouettes. Fog is spatial information, not decoration: never reveal hidden enemies with tall sprites or effects. Leave HUD safe areas clear. Phantom Camera owns framing; preserve its tactical zoom and impulse behavior. Inspect at the actual game resolution and at reduced scale.

## Shape and palette
Use the artwork's ink edges, textured interiors and concentrated luminous accents. Arcane energy reads cyan/white, void uses violet and inward motion, flame uses rising warm tongues, corrosion spreads through irregular stains, and wards assemble around their protected subject. These are observations of current assets, not mandatory categories: derive each event's silhouette and choreography from its own mechanics. Avoid covering every spell with the same expanding circle. Separate hue, value, silhouette and motion so color alone never carries identity.

## Animation and material
Give movement intent: a readable preparation, decisive change and economical settling. Acceleration, overshoot and secondary motion must support the event's weight. Heavy stone fragments fall and settle; flame rises and breaks apart; tethers connect their actual endpoints; void pulls inward. Preserve authored ground contact and flying idle scale. Do not move authoritative unit roots to fake anticipation. Use presentation children and body anchors.

## Combat hierarchy
Target selection precedes execution. Source, travel or transformation, contact, reaction and residual state must agree spatially and temporally. A hit needs a local value peak and target reaction, not merely more particles. Damage labels must remain legible over impact flashes. Quiet support actions still need a clear beneficiary and completion cue. Reserve large flashes and impulses for appropriate weight; avoid constant full-screen glare.

## Current integration references
`CardFxRunner` handles pre-effect sequencing; CardUI and CardResolver retain authority. `SpellOrigin` and `ImpactAnchor` align art with body contact; ground effects stay at hex origins. `ui/fx/spell_signature.gd` samples illustrated and shader layers and frees them on completion. `ui/world_ui/board_overlay.gd`, collapse outlines, tile shaders, fog and terrain depth contribute to the same composition. Review those together rather than judging an isolated effect on black.

## Art direction decisions
Record event-specific intent in specs/: what the player must understand, shape, motion, material, relative timing, focal point, references inspected and acceptance evidence. Prefer a small purposeful change to indiscriminate glow, scale or particle inflation. A clean build establishes technical validity only.
