# Battlefield presentation — 2026-10-18

## Center anchoring, route readability and spell identity

Unit roots, ground rings, hover markers and gate effects now share the exact hex
center. Utils.ground_sprite caches each illustration's opaque lower edge and
offsets the artwork so its feet rest on that origin. Idle bobbing remains relative
to it; movement traces copy the texture offset. Picking and spell-body anchors
were raised to match. Character scale and logical occupancy are unchanged.

The route screen has opaque, aligned hex faces, smaller consistent icons, solid
label backing and stronger current/available/locked states. A dark sidebar and
single-line title replace the wrapping title over the illustration; background
particles are disabled there. Route lines are trimmed at both ends and drawn
below node faces. Map layout, progression and encounter selection are unchanged.

Twenty-five cards now reference dedicated signature scenes. Six shader families
provide cuts/ticks/tethers, expanding pressure rings, ascending flame, creeping
corrosion, inward void shards/apertures and assembling/orbiting/rising support
effects. Selected families retain their illustrated animation layers. Arcane Bolt
and harvesting retain their existing distinct feedback. Overload uses a broad
jagged discharge, Sever Anchor a split gold tether, and Void Shard uses void
projectile artwork. Energy effects now play their configured visuals; otherwise
silent custom utility cards have an optional cosmetic cast effect. Playback is
bounded, releases its nodes and never gates authoritative outcomes.

Validation: full headless combat regression and a short AutoWalker encounter
passed. Focused native checks passed for exact artwork/ground contact, picking,
fog, camera, harvest and teleport behavior, signature cleanup, and the real
Overload/Sever/Void Shard card-resolution paths. Route checks passed for opaque
faces, trimmed endpoints, selection guards and current/available states. Reviewed
native battle and route captures plus a representative six-family comparison.
Art/resource checks and diff whitespace checks passed. The temporary QA workspace
is absent; existing source art was preserved.

## Presentation and interaction follow-up

This follow-up preserves the existing tile atlas and character illustrations.
It supersedes the initial scale/framing values below: player scale is 0.175,
ordinary enemies 0.16, Obelisk 0.205 and Spectre 0.13, with grounded vertical
offsets. Flying idle now keeps its full body scale instead of shrinking to half
size. Tall capsule picking regions cover the visible bodies. Persistent ink
outlines and restrained rim lighting survive per-unit hit flashes; ground rings
distinguish player, hostiles and objective. Hidden enemies stay hidden even when
their taller illustrations would extend outside a fog cell.

Phantom Camera remains authoritative. Tactical framing uses revealed terrain,
1.9–2.15 zoom and the actual HUD safe area; it follows only when movement would
take the player outside the inner combat region. Fog samples continuous world
coordinates, uses a dark restrained palette and retains the hex alpha mask.
Reveals fade the fog itself instead of growing an opaque stone sprite.

Spell strokes, particles and projectile silhouettes are larger and remain visible
longer, with dedicated contrast/glow shading. Authored SpellOrigin/ImpactAnchor
markers align launch and impact with the illustrations. Impacts and damage labels
use those body anchors. No full-screen bloom or extra particle-count inflation.
Rift gates have animated orbit/ribbon shaders, hidden by fog, and brief expanding
departure/arrival bursts on actual teleports.

Echo Harvest previously used its zero default config amount, never consumed the
deposit and treated hex coordinates as pixels for its effect. It now grants the
actual finite deposit, consumes it, updates the depleted atlas cell and HUD, and
positions feedback through TileMap conversion. Repeated harvesting cannot award
the same resources. Initially empty deposits also show depleted terrain; resource
restoration updates the same cell consistently. Ruin resource rewards retain
their mechanics and receive the coordinate correction only.

Validation: full headless combat regression passed with zero failures. Focused
native checks passed with real fog and the run HUD, body-anchor physics picking,
harvest payout/depletion/repeat protection, teleport destination, fog visibility,
grid round trips, tactical/overview bounds and outline retention after damage.
Reviewed fixed-name battle, harvest and Arcane Bolt captures. Art validation and
resource checks passed. One seven-turn headless AutoWalker encounter completed
with zero invalid actions, failures, softlocks or timeouts. Root certificate-store
diagnostic remains pre-existing. Temporary captures, logs, saves and isolated
projects were removed; prior QA data was preserved.

## Initial migration record

The board, fog, movement highlights, atlas consumers, navigation and collision now
use 64 × 64 pointy hexes, preserving TileSet layout 5, atlas addresses, tile data,
generation and combat rules. ProcGenTilemap's cell_to_world/world_to_cell wrap the
authoritative TileMapLayer conversion; targeting and global occupancy use them.
Original character illustrations are unchanged. Their scene scales doubled,
including shadows, picking areas and the Spectre's smaller relative scale.

`assets/rift/terrain/hex_atlas.png` is a 256 × 128 atlas with the same eight cells:
resource crystal deposits, corrupted stone, rift fissure, mana pool, ancient
masonry, fog surface, depleted sockets and neutral highlight surface. Built-in
imagegen produced one atlas using the Riftwalker as a style reference. Prompt:
“Four by two equal square cells of pointy hexes; transparent exterior; overhead
ancient fractured slate paving; hand-illustrated fantasy outlines and restrained
shading; integrated ochre crystals, plum contamination, cyan-violet fissure, cyan
pool, ruined masonry, dark slate, depleted sockets and quiet plain stone; no
characters, text or giant gameplay symbols.” Packaging crops each cell's alpha
bounds, downsamples and clips to the established pointy-hex shape. Existing
terrain was replaced in place; no extra terrain textures or character variants.

Phantom Camera 0.11.0.3 and its host remain authoritative. WorldCamera's existing
script now supplies bounds, zoom and a follow marker. The competing MapCamera
script was detached from the production battle Camera2D (legacy developer sandbox
still uses its existing controls). WorldCamera priority 40 keeps ordinary
player/enemy transitions from repeatedly interrupting tactical framing. Enemy
spotlight waits only run when that Phantom Camera is active. Existing shakes
remain; no new smoothing or camera controller was introduced.

The existing 1920 × 1080 viewport/stretch reference remains. Linear filtering,
atlas padding and disabled pixel snapping suit illustrated art. HUD bounds come
from the actual left panels, round information, right intentions rail, hand and
energy controls. Tactical zoom stays at 1.65–1.9, centered on the board where it
fits and toward the player for larger boards, clamped to avoid unused space past
board edges. Large boards require inspection. Intro overview fits the full board,
then returns to tactical framing. Wheel zoom permits up to 1.5× tactical size;
middle drag pans in screen-consistent units; Home resets and F fits. Card aiming
locks camera input/reframing. Collapse reframes once after its batch, preserving
manual inspection. No hover-based camera motion.

Target shader normalization, collapse contours, atlas regions, character picking,
local particle spread/size, impact stamps, animated FX and projectile speed were
updated for the doubled geometry. Movement traces inherit the real sprite
transform. No shader rewrite, particle-count increase or gameplay change.

Validation: art validator passed (29 cards, 32 entities, 13 FX); resource checker
reported zero problems; five existing launcher lifecycle tests passed. The single
headless combat regression pass completed with only a new zoom assertion failing
because Vector2 stores single-precision values. Its tolerance was corrected;
focused native grid/camera/target-overlay reruns passed with zero failures.
Native 1920 × 1080 battle inspection confirmed terrain, character scale, target
contour and HUD framing. Additional focused captures corrected the discovered
competing camera and wasted edge space, reusing one filename. One headless
AutoWalker encounter (seed 42) finished in seven turns/27 actions with zero
invalid actions, softlocks, timeouts or simulation failures, exercising movement,
cards, collapse and a summon. The bot lost normally. No large batches were run.

Limits: other desktop resolutions retain the same 16:9 reference scaling but
were not separately rendered. Windows reports its existing root certificate
store diagnostic; validation used Null/local telemetry. The existing offset/cube
distance helper disagrees with TileMap adjacency in some cases; its rules were
left intact, with tests verifying unchanged adjacency and conversion round trips.

Historical task artifacts were removed after validation. The launcher and validator
now run the original project directly; duplicate project trees and junction workspaces
are prohibited. Disposable saves/logs use automatically cleaned system temp storage.
No pre-existing `qa/` data was deleted.
Only `qa/.gdignore` is tracked there. Candidate cleanup: generated `visual-*`,
`followup-*`, `rift-*`, `overhaul-*` logs/screenshots/source metadata and comparison
reports. Review/save any desired regression evidence before deleting. Treat
`*-userdata` as potentially useful saves and `*-project` as linked validation
projects; unlink junctions safely before any recursive cleanup. Actual regression
source remains in `scripts/tests/` and `tools/test_*.py`.
