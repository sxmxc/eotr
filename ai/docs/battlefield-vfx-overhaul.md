# Battlefield and VFX corrective pass - 2026-10-18

This continues the existing overhaul. The first implementation was insufficient:
compiled effects and isolated captures did not establish visual quality. This
report supersedes its earlier claims. Card values, targeting, movement, collapse
state transitions, deterministic RNG, illustrations and Phantom Camera authority
remain in the existing systems.

## Regressions found and restored

- The first pass reduced local impacts from 10/14/20 to 2/4/7, attenuated explicit
  card camera strengths, suppressed light camera responses and weakened player
  hits. Original impact profiles, camera overrides and player-hit responses are
  restored. Existing hitstop and damage callback timing remain intact.
- Restore the player-hit veil to 50%, retaining the new eased dissipation.
- Restore card-play trail density from the weak 36-particle proposal to 96
  (original 128), preserving its 0.35-second life and ownership.
- Damage numbers now have a decisive 1.6 pop, settle and readable hold, followed
  by rise/fade. Intent and HUD pulses cancel their own overlapping tweens and
  return to their authored resting scales.
- Keep useful fixes: fully blocked hits use a cool tint; six enemy lunges and
  movement squash animate visual children rather than collision/gameplay roots;
  conflicting flying-idle position animation pauses during the lunge and resumes.

## Battlefield integration

`TerrainDepth` caches drawing geometry from actual BaseLayer cells. Relying only
on TileMapLayer.changed left stale rims during cell erasure. It now also consumes
ProcGenTilemap.presentation_changed and map_generated, coalescing rebuilds. It
owns no occupancy registry or gameplay processing loop. Two successive real
shrinks are checked against every surviving boundary and exposed neighbor.

Highlights now sample the canonical texture's alpha silhouette. The prior
vertex-derived UV treatment failed for batched TileMapLayer geometry. Movement,
legal target and hover scenes share the same teal mask and 64px dimensions;
materials are isolated where cursor colors change. No targeting calculation,
TileSet geometry, atlas addressing, movement/pathfinding or collision was changed.
Amber broken outlines and cracks remain distinct collapse warnings.

The selected illustrated ashlar atlas retains the original alpha mask byte for
byte. An older-looking capture prompted explicit source/import verification.
The cache was refreshed as a precaution and the engine-loaded image inspected
against the selected source; timestamps alone do not establish stale content.
The shared terrain material adds only broad low-amplitude pigment variation.

Collapse samples the actual visible tile before the existing authoritative erase.
Five irregular textured pieces expose undersides, separate, accelerate downward,
rotate slightly, shrink into depth and darken/fade. Short illustrated dust follows.
Debris frees at 0.76 seconds. Fogged cells never reveal hidden artwork. The
mechanical 0.1-second per-cell shrink cadence and damage checks are unchanged.

The old gradient/star field is replaced by an illustrated ink-blue/plum void:
quiet central abyss, distant suspended ruins and a peripheral rift scar. One
aspect-correct texture sample drifts very slowly; obsolete star layers are hidden.
Background exposure is restrained so characters, targeting and UI remain legible.
No screen-reading shader, renderer change or competing camera system was added.

## Ability direction

The [per-ability direction](battlefield-ability-direction.json) records actual
behavior and the chosen treatment for every card, plus healing/release/contact.
The [source inventory](battlefield-vfx-inventory.json) records each source locator,
assessment, disposition, ten review dimensions, dependencies, animation tracks,
emitter/material configuration and presentation method. Regenerate it with
`python tools/audit_visual_effects.py`. Vendor/demo sources are included in source
coverage and retained; they are not individually rendered approval claims.

The primary spell visuals now use authored illustrated frame sequences.
`spell_signature.gd` owns lifetime; `spell_layer.gd` samples independent
scene-authored frame ranges, delays, drift, scale and rotation. It does not select
an artistic family or schedule gameplay. The older procedural surfaces remain
low-opacity secondary accents. The same source sheets are composed differently
where the underlying material is related; distinct actions have distinct staging.

Examples:

- Arcane Bolt: pointed ivory core inside a filled cyan energy body, source release,
  accelerating flight, short actual-motion wake, separate painted contact/sparks.
  Default speed is 1550 world px/s with a 75-260ms travel window. Wake is bounded
  to 54 world pixels and fades in 90ms. It no longer uses a connecting line.
- Arcane Blast: heavier projectile and wider asymmetric contact. Overload retains
  a jagged violet discharge; Sever retains a split ochre tether, steep cut and
  collapsing anchor-remnant. They use the existing discharge infrastructure.
- Chrono Jab: compact cut and displaced echo at each of its two actual hits;
  existing 0.3-second damage interval remains authoritative. Phase Slash is a
  broad diagonal sweep. Jab is a compact physical contact.
- Corrosion: wet dark stain, olive capillaries and separate droplets; wider ground
  spread for the all-enemy Wave. Its initial tiny droplets proved too weak at
  tactical scale, so it begins at the contact frame and has a broader silhouette.
- Flame: painted upward tongues and ivory inner planes. Void Surge: tall inward
  torn mouth and crossing blood echo. Void Shard: fast plum pointed missile.
- Void Fracture: an opening at the caster releases three separate shard shapes,
  alongside actual card spotlight creation. Quantum Rift opens and closes a
  standing tear. Phase Step now phases the actual player illustration out during
  travel and back in at arrival, with two dissolving snapshots of the real artwork
  along the traveled path. The rejected floor slash has been removed. Cancellation
  restores original sprite opacity without changing board/collision/move timing.
- Eldritch Barrier: one upright translucent shield (42% opacity). Nano Shield:
  three separately assembled translucent plates (40%), with its independently
  configured energy effect. Legacy shield shine is also translucent. Mana Leech draws
  staggered stolen-mana wisps toward the actual player's impact anchor.
- Echo reads the actual previous discard artwork for its spectral thumbnail.
  Focus compresses one rising wisp; Rift Knowledge converges three wisps; healing
  uses paired green rising strokes. Existing status icons remain restrained.

Newer enemy tactics previously applied some outcomes silently: strike, mend,
ward and curse now consume the existing effect scenes at the real application.
Obelisk's obsolete (-4,-30) sprite offset was removed to align its visible base,
ground ring and occupied cell. These are improvements beyond the named defects.

## Lifecycle and performance

Animated flight is shared by existing small/heavy/Obelisk scene references.
Impacts remain projectile-owned until arrival, then transfer to a live target.
Weak references, cancellation cleanup and finite wake lifetime prevent detached
impacts or orphaned trails. Native transformed-parent/arrival checks cover this.

Six ambient emitters drop from 6000 to 48 slow, fading motes; pause reuses that
scene instead of duplicating six dense emitters. Aiming trail is 28 particles with
0.28-second life; mana buff has ten slower motes. Rare reward bursts and useful
existing illustrated status/death/hover/burn/relic feedback remain. Spark cleanup
is finite in both native and headless modes. No persistent per-status emitters,
bloom stack, expensive screen distortion or new global VFX manager was added.
No hardware frame-rate improvement or broad GPU benchmark is claimed.

## Validation record and limits

Godot 4.7.2, native D3D12 Forward+ on RTX 2060; isolated saves and Null/local
telemetry. The bounded initial plan ran baseline, terrain, combat, gameplay and
regression. User-reported failures justified a focused corrective pass.

- Initial baseline loaded 620 resources. Initial native/headless combat checks,
  harvest/gates, transitions, six real enemy lunges and AutoWalker completed.
- Initial native Watch seed 42: loss, 4 turns/13 actions, zero invalid actions,
  failures, softlocks or timeouts. Headless: loss, 7 turns/27 actions/one summon,
  zero invalid actions, AI-invalid decisions, failures, softlocks or timeouts.
- Corrective real two-shrink boundary/lifetime/RNG checks passed. Canonical mask,
  TileMap/world conversion, contact/picking, camera and occupied target alignment
  are checked without modifying production mechanics.
- Corrective native movie review recorded complete action sequences at 60fps,
  including projectile motion, cuts, flame, corrosion, shields, utility, overlapping
  29 signature lifetimes and real collapse. Ordered frames were inspected across
  the complete motion. A fixture that skipped Arcane Blast's normal configuration
  step was corrected before the final review; it was not a gameplay-code fix.
- Final native combat checks passed: exact occupied target alignment, transformed
  projectile origin/orientation, movement before arrival, finite wake cleanup,
  real resolver paths and 29 overlapping signature lifetimes. Native two-shrink
  integration passed again after the selector dependency fix.
- Final native regression loaded 640 first-party resources and passed shader
  alpha, ambient budgets, transition isolation and six actual enemy attack
  sequences. Full headless combat passed. Final headless AutoWalker seed 42
  matched seven turns/27 actions/one summon, with zero invalid actions, failures,
  AI-invalid decisions, softlocks or timeouts. Art validation passed 29 cards,
  32 entities and 19 FX textures; resource checks and diff whitespace checks pass.
- Follow-up: Arcane Bolt's UID and card dependency were probed in a fresh engine
  process: both load the animated projectile, with no connecting-line child.
  The user subsequently confirmed the editor showed the changed bolt; no broad
  cache deletion was needed. Phase Step was redesigned again to phase the real
  player out/in, and shield layers made translucent. A focused 60fps native clip
  and runtime checks cover mid-move opacity, real traveled afterimages, arrival,
  cancellation restoration, shield opacity and cleanup. These checks pass.

Source coverage is exhaustive; rendered coverage is representative, not full
campaign/boss/export/resolution coverage. Native/headless AutoWalker policy traces
previously diverged after matching initial checkpoints; cross-renderer replay
parity is not claimed. That pre-existing action-boundary/deferred-outcome concern
was left outside this presentation scope. The Windows root-certificate diagnostic
also remains. Movies, captures, saves, logs and isolated-project junctions are
confined to `.qa-tmp/` and cleaned after review; user QA is preserved.

## New artwork provenance

Built-in imagegen mode was used, with Riftwalker artwork as a style-only reference.
No API/CLI fallback. Original generated sources remain in the generator output
folder; only packaged production textures are added to the repository. New assets:

| Asset | Direction |
| --- | --- |
| `assets/rift/fx/arcane_projectile.webp` | Eight phases, pointed ivory energy core, filled cyan tapering body, ink underside and torn backward wakes. |
| `assets/rift/fx/arcane_impact.webp` | Asymmetric cyan pressure burst, ivory core, recoil crescent and stone sparks. |
| `assets/rift/fx/phase_cut.webp` | Broad ivory/teal scythe cut with ink underside and broken energy edge. |
| `assets/rift/fx/rift_implosion.webp` | Obsidian shards drawn inward around a torn plum aperture. |
| `assets/rift/fx/ward_assembly.webp` | Faceted illustrated shield, substantial stone/metal frame, assembly, glancing contact and dissipation. |
| `assets/rift/fx/corrosion_bloom.webp` | Wet plum stain, olive capillaries, heavy droplets and vapor. |
| `assets/rift/fx/flame_crown.webp` | Broad upward warm flame tongues, ivory inner planes and dark ink edges. |
| `assets/rift/environment/rift_void.webp` | Wide quiet ink-blue/plum abyss, peripheral suspended ruined architecture and restrained rift scar. |

FX sources use four equal columns by two rows, genuine transparent backgrounds,
consistent centers, no text or characters. Packaging downsamples to 1024x512;
eight 256px frames remain editable through normal SpriteFrames resources. The
projectile and cyan contact sheets reserve eight transparent pixels per frame
after boundary validation caught insufficient gutters in their first pack.
The background is bounded to 2048x1152. These are art-direction briefs, not a claim
that the final motion is determined by the source sheets alone.

## Terrain asset provenance

Built-in **imagegen** generated the selected bitmap; no API/CLI fallback was used.
Final project asset: `assets/rift/terrain/hex_atlas.png`. Packaging only crops each
cell, downsamples it and restores the original canonical alpha mask. Character
reference: `assets/rift/entities/riftwalker.webp`, used for style only.

Final prompt:

> Use case stylized-concept. Reference image: STYLE ONLY, illustrated ink silhouette and muted palette. NO characters in output. Create ONE game tile atlas, FOUR equal columns by TWO equal rows, aspect ratio 2:1, transparent outside eight hexes. Eight pointy-top hexagonal terrain faces from EXACT VERTICAL overhead orthographic view; zero isometric perspective, zero side walls or extrusion. All hex faces same exact size, fill equal square cells, top/bottom points touch square edges. New art direction: ancient shattered architecture made of LONG RECTANGULAR CHISELED ASHLAR SLABS in offset linear courses, broad plane faces and straight joints, NOT rounded cobblestones or circular paving arrangements. Each cell has DIFFERENT slab arrangements, some large plates span most of cell with one long diagonal geological fracture, others narrow rectangular broken courses. Broken pieces, eroded nicks, subtle scraped pale edges, deep charcoal ink fractures, dusty desaturated slate blue and warm dark grey. Flat shaded hand illustration matching reference, not realistic or noisy. Quiet surface with about 3-6 major slabs per hex; no dense rubble borders, no bright outline, no decorative gold markings. Top row cells left to right: 1 ancient rectangular slate paving with a small cluster of amber crystals tucked into a short crack off-center; 2 broad rectangular fractured slate with fine branched PLUM-magenta corruption seams; 3 large stone plates split by one narrow jagged dark fissure with cyan-violet edges; 4 worn paving with a small irregular cyan pool recessed in one corner, no circular border. Bottom row cells left to right: 5 broken ASHLAR floor, a remnant shallow carved linear relief in ONE corner, no stairs or raised structures; 6 very dark quiet slate plates for fog; 7 two broad stone plates with sparse tiny EMPTY TRIANGULAR crystal holes, NO CIRCLES OR RINGS; 8 plain quiet grey slate plates for selection overlay. Shared light upper left, major dark cracks but reserved detail; terrain must stay darker than character art. No circles, no rounded stones, no tokens, no floating islands, no background, no text, no room scenery. Production tile-sheet art intended for downsample to 64px faces.
