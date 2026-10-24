# Layered menu artwork v2

New companion artwork generated with built-in image_gen using the existing
`assets/rift/menus/main_menu.webp` as a style/composition reference. This is not
an exact separation of the original. The live main menu now composes these
textures through `scenes/menus/menu_environment.tscn`.

Stack the following full-canvas images from back to front with identical bounds:

1. `atmosphere.png`: opaque cloudy void with distant silhouettes; complete coverage
   behind the other layers, without embedded copies of their architecture.
2. `floating_ruins.png`: three separate floating ruined islands on real alpha.
3. `bridge_portal.png`: foreground stonework, bridge, portal, obelisk and right
   framing column. Keep this layer together to preserve the bridge perspective.

All three outputs are **1672 × 941**, despite the prompts requesting 1920 × 1080.
Use identical uniform scaling for all layers. Transparent files are RGBA with
alpha extrema 0–255; the background is RGB. Preserve alpha during import.

Exact generation prompts and filenames are recorded in `generation.json`.

## Review

Inspected each generated image and a three-layer native Godot 4.7.2 composite at
1920 × 1080, D3D12 Forward+ on NVIDIA GeForce RTX 2060. Evidence is retained in
`.qa-tmp/menu-parallax/layered-v2-preview.png`, with its capture script and log.
The preview uses project rendering/post-processing, so its appearance differs
from the raw PNGs. Generated shapes and palettes are similar to the original;
the central island is larger and the architecture is a new illustration.

The original asset-only preview predates integration. The scene now includes
additional scene-authored ruin placements, horizontal idle atmosphere drift,
vertical-only ruin pointer motion plus a gentle idle bob, and a locked bridge/tower.
The atmosphere never follows the pointer. A common cover
transform provides 3.5% overscan. Menu-local viewport setup allows subpixel
transforms and restores the previous pixel snapping setting on removal.
An eight-second AnimationPlayer loop eases atmospheric drift and portal energy
through matched endpoint values. See `docs/ui-authoring.md` for runtime ownership.
Do not repeat these non-tiling images. Runtime evidence and limits are recorded
under `.qa-tmp/menu-parallax/`.

The offline preview used isolated temporary saves and `--validation-local`.
Existing certificate-store and encounter-resource UID-fallback diagnostics were
observed. Direct image-loading warnings belong to the disposable preview script;
shipped scenes should consume imported Texture2D resources.
