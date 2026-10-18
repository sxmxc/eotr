# Combat, content and art overhaul

Persistent delivery checklist (2026-10-18). Unchecked items are not complete.

- [x] Inspect repository, progression, combat, enemy actions, card UI and asset references.
- [x] Consolidate encounter definitions and selection; migrate consumers and remove pool.
- [x] Establish and validate original illustrated masters and production pipeline.
- [x] Integrate 8 base enemies, 12 behavioral variants and 20 encounters.
- [x] Replace battlefield, map and environmental placeholders; inspect footprints.
- [x] Replace all 29 card illustrations and inspect shared card presentation contexts.
- [x] Replace remaining UI placeholders; main menu and all three class backgrounds.
- [x] Run compatibility, actual combat automation and rendered visual checks.
- [x] Remove superseded assets and update documentation and inventories.

## Findings before implementation

There is no root AGENTS.md. Guidance is in ai/docs/agents.md. README, workflows,
combat-improvement, architecture audit, UI authoring, continuous improvement and
AutoWalker documentation describe the existing implementation. No separate world
bible was found: Riftwalker, fractured arenas, resource extraction, ruins, mana
wells, corruption and the active Obelisk are the concrete world references.

MapGenerator selects BattleStats using EncounterRegistry, with a second weighted
BattleStatsPool fallback. Registry dictionaries duplicate tier, elite, weight and
boss information. The pool mutates cumulative weights on shared definitions.
RegistryData can discover unregistered encounters through another scan. DataEditor
edits duplicated registry metadata. Bounties instantiate composition scenes just
to read enemies. These are concrete ownership/authoring costs.

The map has 15 floors: rows 0–2 use tier 0; later monster rooms use tier 1 and
promote elite compositions to elite nodes; row 8 is treasure, row 13 rest, and
row 14 selects the authored tier 2 boss pool. Preserve both tier 2 compositions.
Run loads the selected node's resource into GameWorld; the existing state
controller runs hand, enemy and collapse phases; stable victory triggers end of
combat relics, outcome presentation, rewards and map continuation. Existing
eliminate-hostiles victory and synchronous capped Obelisk summons are retained.

Combat already has authoritative card validation, damage counters, cancellation
generations and collapse escape actions. Do not rewrite these systems. Existing
enemy movement seeks melee positions even for ranged enemies; new ranged roles
need bounded range-aware destinations. Initial composition placement is random,
so authored placement constraints must run before adding enemies.

## Art direction and measured geometry

The TileSet uses pointy-top 32 × 32 hexes (vertices at 0,±16 and ±16,±8).
Battle sprites currently render 512-pixel icons at 0.05 scale. Preserve that
logical canvas and use a safe inner diamond/hex; silhouettes, outline and shadows
must remain inside the tile even during fly-idle and movement presentation.
CardArt was 148 × 66. It is now 148 × 99 inside a 180 × 280 card, using
592 × 396 illustrations. Shared CardVisuals serves hand, inspection, reward and deck.

Final art direction: high-resolution illustrated cel shading, smooth dark outlines,
organic silhouettes, dark slate ruins, warm ivory, restrained cyan, ochre and plum.
One fixed character master supplies each class's battlefield art, class background
and relevant card subjects. The Riftwalker always has teal sleeves, brown gloves
and boots, and an ivory mask. Characters are composited from that exact source;
they are not independently regenerated for each illustration. No pixel-art pass
or rejected vector/painterly alternative remains in the project.

## Final architecture and authoring

`MapNode.battle_stats` now references `EncounterDefinition`. The familiar property
name is retained; there is no legacy resource class or compatibility selector.
The definition owns ID/name, tier, category, tags, unlock, weight, composition,
dimensions, starting-tile constraint, player spawn distance, collapse frequency,
shape, corruption weight, objective and reward context. Runtime reward counters
are isolated by duplicating the selected definition at battle startup.

`EncounterRegistry.encounters` is a typed array of definitions. `select()` applies
eligibility and positive weights without mutating definitions; explicit IDs support
authored special-node overrides. Zero/empty pools do not select unrelated content.
Map generation avoids the previous two compositions when alternatives exist.
Tier 2 still contains both original authored final encounters and the new siege.
Normal/elite categories are selected together for later monster rooms; selected
elites promote the room's node type. Boss selection requires the boss category.
Special category resources can be referenced by explicit ID without joining normal
pools. No special encounter/objective mechanics were invented.

Deleted the old pool resource, pool script and old stats script. Migrated map,
bounties, sandbox, RegistryData, DataEditor, tests and existing composition resources.
RegistryData lists registry membership without discovering another encounter pool.
DataEditor saves standalone definitions before saving their registry references.
EnemyCatalog remains an inventory of definitions/scenes for lookup and sandbox use.
Composition setup transfers instantiated enemies rather than duplicating each node.

To author content: create/reuse EnemyStats and optional EnemyTactics, add it to an
authored composition scene, create an EncounterDefinition `.tres`, and reference
that resource in the registry. Obelisk spawn pools stay authored on their scene
instance. No encounter-specific code is needed in GameWorld.

## Roster

Existing roster: Bat (flying melee pressure), Blob (blocking melee), Horror (melee
damage), elite Horror (elite pressure), Wasp (flying ranged threat), Bulwark (armored
advance/cleave), Void Channeler (ally empowerment/weakening bolt), Void Spectre
(late boss pressure), and Obelisk (immobile ranged attacks/capped reinforcements).
Their action scenes and progression placement remain intact. All have illustrated
art; elite Horror also has a separate armor treatment. Obelisks remain one hex.

| New base | Tactical role and counterplay |
| --- | --- |
| Shard Hound | Three-step melee approach; block and use terrain before it closes. |
| Rift Needle | Four-hex engagement and retreat from close pressure; close its gap. |
| Ward Keeper | Wards one nearby ally; separate enemies or remove support first. |
| Echo Mender | Heals injured nearby allies; focus damage and deny healing targets. |
| Hollow Siphon | Two-hex strikes with self-healing; control engagement distance. |
| Glass Reaver | Alternates bracing and two-hit melee pressure; exploit its timing. |
| Ruin Scavenger | Consumes a resource on its tile to heal/block; contest resources. |
| Rift Hexer | Ranged weakening pressure; prioritize it or play around the debuff. |

| New variant | Behavioral difference |
| --- | --- |
| Pouncer Hound | Two-step movement with a two-hit attack. |
| Scatter Needle | Two-hex engagement, faster repositioning and split hits. |
| Anchor Keeper | Slower ward cadence, longer engagement, prioritizes largest ally. |
| Triage Mender | Three-turn cadence, faster approach and melee engagement. |
| Stalker Siphon | Three-step movement and melee leeching. |
| Patient Reaver | Three-turn brace cadence, slower approach and three hits. |
| Grazer Scavenger | Every-turn resource consumption and two-hex engagement. |
| Corrosive Hexer | Two-hit shorter-range attack applies existing Corroded. |
| Darter Bat | Two-hex ranged skirmishing and retreat from close pressure. |
| Warding Blob | Shields a nearby ally rather than focusing on its own block. |
| Reaper Horror | Alternates bracing and split-hit pressure. |
| Mending Channeler | Heals injured allies instead of empowering the swarm. |

Profiles reuse one action implementation and the existing authoritative effects.
Ranges, movement budgets, hit pattern, support target, timing and existing statuses
change decisions; variants are not HP/damage upgrades. All twenty profiles appear
in registered compositions and the sandbox catalog. Crests, asymmetric guards and
segmented wards visually distinguish variants from their base. Ranged movement
uses hex-distance engagement rings while retaining bounded BFS and collapse escape.

## New authored encounters

| ID | Tier/category | Composition besides the active Obelisk |
| --- | --- | --- |
| shard_tracks | 0 normal | Shard Hound, Bat |
| needle_watch | 0 normal | Rift Needle, Blob |
| keepers_oath | 0 normal | Ward Keeper, Bat |
| ruin_foragers | 0 normal | Ruin Scavenger, Blob |
| darter_crossing | 0 normal | Darter Bat, Bat, Blob |
| warded_mire | 0 normal | Warding Blob, Horror |
| triage_procession | 1 normal | Echo Mender, Shard Hound, Blob |
| hollow_orbit | 1 normal | Hollow Siphon, Rift Needle |
| glass_ambush | 1 normal | Glass Reaver, Pouncer Hound |
| hexer_screen | 1 normal | Rift Hexer, Ward Keeper |
| scatter_lanes | 1 normal | Scatter Needle, Darter Bat, Blob |
| anchor_guard | 1 normal | Anchor Keeper, Rift Needle, Shard Hound |
| menders_retreat | 1 normal | Triage Mender, Reaper Horror |
| stalker_rift | 1 normal | Stalker Siphon, Rift Hexer |
| patient_blades | 1 normal | Patient Reaver, Mending Channeler |
| grazing_ground | 1 normal | Grazer Scavenger, Ruin Scavenger, Bat |
| corrosive_vigil | 1 normal | Corrosive Hexer, Bulwark |
| fractured_convoy | 1 elite | Ward Keeper, Echo Mender, Glass Reaver |
| hunters_convergence | 1 elite | Pouncer Hound, Stalker Siphon, Reaper Horror |
| prismatic_siege | 2 boss | Rift Needle, Anchor Keeper, Patient Reaver, Corrosive Hexer |

Dimensions, corruption, minimum opening distance and collapse frequency are
authored per definition. These are curated pools with bounded placement variation,
not random enemy-count generators. All seven original encounters are retained.

## Final assets and reproducibility

All final artwork lives under `assets/rift/`:

| Category | Count / contract |
| --- | --- |
| Entity/class sprites | 32 × 512² WebP; true alpha, body inside animated hex bounds |
| Shadow | One 512² transparent WebP |
| Card illustrations | 29 × 592 × 396 WebP |
| UI/map/status/relic icons | 32 original 64² SVGs, shared semantic family |
| Terrain/object atlas | One 128 × 64 PNG matching existing 32px TileSet cells |
| Main menu / class backgrounds | Four 1920 × 1080 WebP |
| Retained compositor masters | Five source images actually used by the builders |

104 final image files, about 5.5 MB of image sources, replacing 88 obsolete sources
totaling about 16.9 MB. The Godot scaffold application icon is also replaced. There
are no alternate `painted/` or pixel-art directories. Sources and import metadata
are removed only after reference and Godot checks. UI icons with no consumers are
not retained. Third-party input glyphs, particles, audio, fonts, addons and original
Voidmoose branding remain for their legitimate uses and retain attribution.

The complete old-asset → usage → replacement → status mapping and all 29 card rows
are in [rift-asset-inventory.json](rift-asset-inventory.json). Additional generated
enemy/variant resources and encounter parameters are in [rift-content.json](rift-content.json).

Built-in image generation produced the illustrated character/creature and arena
masters, using the Riftwalker master as the common style reference. Prompt direction:
high-resolution smooth dark ink contours, organic silhouettes, broad cel shading,
restrained slate/teal/ivory/ochre/plum, compact full-body three-quarter view, genuine
alpha, no text, no checkerboard, no pedestal. Subjects are the named roster's actual
silhouettes and tactical roles above. The Riftwalker master explicitly fixes both
teal sleeves, brown gloves/boots and ivory mask. Menu generation uses quiet text
space and the same fractured-ruin/Obelisk world. No CLI/API generation fallback used.

`tools/prepare_rift_art.py` rejects opaque backgrounds, fits real alpha to safe hex
bounds and preserves useful class portrait masters. `tools/build_rift_cards.py`
deterministically composes every card, variant equipment and menu/class background.
`tools/build_rift_icons.py` rebuilds the used SVG family and illustrated tile atlas.
Builders write atomically so an open editor cannot import half-written textures.
They overwrite canonical outputs without accumulating alternatives. Pillow is the
only tooling dependency. `tools/validate_rift_art.py` checks dimensions, references,
true alpha, animated footprint bounds, old sources and unused final outputs.

## Verification and limits

- Asset validator: 29 card bindings, 32 unit sprites, true transparency, animated
  hex bounds, zero missing references, zero unused final outputs, zero superseded
  sources remaining. Source/import audit passed; scene resource guard passed.
- Offline Godot 4.7.2 combat automation: zero failed assertions. Includes registry
  IDs/categories/tiers/repeat avoidance/overrides, all registered compositions and
  twenty playable profiles, all loaded card textures/resolutions, existing Obelisk
  elimination victory, movement legality and enemy lifecycle regression checks.
- Offline native rendered compatibility: zero failed assertions. Captured main
  menu, all three class screens, map/legend, combat/fog/targeting, enemy inspection,
  hand/hover, rewards, deck views and selection contexts. Main menu contrast and
  3:2 card framing were inspected in the actual scenes. The class variants remain
  locked by the original progression; QA switches them directly to inspect art.
- AutoWalker: 24 authored-encounter runs plus three final siege seeds, using real
  runtime and local telemetry. 19 wins, 8 losses; zero invalid actions, AI-invalid
  decisions, softlocks, timeouts or runtime failures. Final siege: two wins and one
  loss in 13/9/15 turns, with actual capped summons. Full per-encounter results are
  in [rift-validation-results.json](rift-validation-results.json).
- Additional final checks: rendered Hunters Convergence completed in 10 turns
  with a win and one summon; run mode exercised startup, map progression and
  combat before a five-turn loss after one climbed floor. Both reported zero
  invalid actions, softlocks, timeouts and runtime failures. This does not
  establish a complete campaign playthrough.
- Existing Windows certificate-store/headless shader diagnostics remain. No
  backend services were accessed or started. A packaged export and complete
  fifteen-floor human campaign were not performed. Bot wins/losses are limited
  evidence of correctness and tactical function, not a human balance benchmark.
- Shared character poses and environment are intentional identity reuse. Every
  card has a separate effect composition; this is not a character animation set.
  Multi-hex occupancy was not introduced. Final artistic approval remains the
  user's judgment; passing technical checks is not a claim of commercial approval.

## Generation prompt contract

Built-in image generation; no CLI/API fallback. Final saved paths are the assets
listed in the inventory under `assets/rift/`. Original generator outputs are not
runtime dependencies. The exact character-master prompt was:

> One production game character sprite, NOT a card illustration. High-resolution stylized hand-drawn 2D illustration with smooth clean ink contours and broad organic shapes, two-tone cel shading, 512px-quality rendering; NOT pixel art, not 3D or photorealistic. Echoes of the Rift Riftwalker: small masked traveler in a dark TEAL hood and short dark TEAL cloak, both arms in matching TEAL cloth sleeves, brown gloves and brown boots, simple warm IVORY oval face mask with two narrow dark eye openings. Ivory appears on mask ONLY, no white armor or white sleeves. Slightly exaggerated readable proportions, no intricate decoration. Full body, three-quarter elevated view, standing ready, facing right, both feet and both hands visible. Restrained muted palette dark navy contours, slate teal cloth highlights, warm tan leather, ivory mask, one tiny pale cyan magical accent on right hand. Genuine transparent alpha background; no ground plane, no pedestal, no shadow, no glow cloud, no backdrop, no checkerboard pattern or drawn transparency grid. Character fills almost the full canvas vertically while leaving all edges intact. Silhouette compact with hands close to body so fits one hex. No text, logos, frame or watermark. Exactly one character, one consistent costume.

The common enemy-master prompt (followed by each named creature's subject and role)
was:

> Create ONE full-body enemy unit sprite for Echoes of the Rift. Input image is STYLE REFERENCE ONLY: match the smooth dark ink contour, clean high-resolution hand-drawn cel shading, broad confident shapes, restrained rich teal/ivory/ochre/plum palette and dimensional organic form. NOT pixel art, NOT realistic rendering, no tiny noisy detail, no flat geometric icon. Three-quarter elevated view facing lower right, compact strong silhouette, full subject completely visible. Real transparent alpha background with transparent corners, no drawn checkerboard or backdrop, no floor or pedestal, no distant cast shadow, no broad aura. Small effects stay within silhouette. No text, UI or watermark. This is a different creature from the reference traveler; do not reuse the humanoid body. Subject: 

The common environment prompt (followed by the arena or menu composition) was:

> Generate one finished high-resolution environment illustration used as the shared background behind card subjects. Match the supplied reference's clean hand-drawn cel-shaded fantasy style, confident smooth contours, restrained navy, slate teal, muted ochre and dusty plum palette; no pixel art, no photorealism, no neon filigree. Canvas 3:2 landscape. No characters or monsters, no hands, no text or lettering, no watermark, no UI or frame. Large quiet central space reserved for composited characters and effects. Subject: 

Final card/class composition does not use further character generation. It copies
the fixed master files through `build_rift_cards.py`; source poses, sleeve colors,
mask, gloves and boots therefore remain identical across those uses.

