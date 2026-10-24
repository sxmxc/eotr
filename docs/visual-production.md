# Visual QA and asset production

The visual pipeline records actual combat through AutoWalker and Godot's native
renderer, then extracts a small evidence set for review. It connects scenario
selection, gameplay action traces, timing, native captures and before/after
comparison; it does not grade artwork or replace gameplay implementation.
Use it for spell timing, feedback, fog, camera, terrain/collapse and visual
regressions. Use focused runtime tests for state contracts and AutoWalker reports
for longer gameplay sequences.

## Capture and inspect a scenario

Requirements: imported Godot 4.7.2 project, Python 3.10+, a working graphics driver
and a full FFmpeg build with AVI demuxing, PNG encoding and hstack. No Python
packages are required for capture. Do not use `--headless` to judge particles or
rendered lifetime. On Linux without a desktop, use `xvfb-run -a` with working
Mesa/OpenGL. The capture launcher isolates saves in system temp and disables
network telemetry; it runs the original project.

```powershell
$godot = 'D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe'
$ffmpeg = 'ffmpeg'
python tools/visual_pipeline/run.py arcane-bolt --label bolt-before --godot "$godot" --ffmpeg "$ffmpeg"
# Inspect evidence and implement the intended change, then capture again:
python tools/visual_pipeline/run.py arcane-bolt --label bolt-after --baseline .qa-tmp/visual/bolt-before --godot "$godot" --ffmpeg "$ffmpeg"
```

`GODOT` and `FFMPEG` can supply executable paths instead. Every label must be new.
The CLI returns zero when capture/extraction succeeds and the expected card event
is present; it still creates a review marked **awaiting visual inspection**.
Open the images/movie, verify the intended event happened, inspect logs and complete
the review honestly. Successful extraction is not artistic acceptance.

| Output under `.qa-tmp/visual/<label>/` | Use |
| --- | --- |
| `capture.avi` | Native movie including game audio. |
| `scenario.json`, `command.json` | Exact setup and executable arguments. |
| `timing.json` | Events, action trace, boundaries, source hashes and commit context. |
| `console.log`, `godot.log`, local telemetry | Renderer/script diagnostics and gameplay evidence. |
| `frames.json`, up to 18 representative PNGs | Sparse samples with timestamps; inspect preparation, travel, contact and recovery. |
| `comparison.json`, `comparison.mp4` with `--baseline` | Action alignment, boundary drift and silent side-by-side movie. |

Movie Writer captures the project viewport (1920Ã—1080) despite the smaller window.
Short captures can use tens of MB. Generated evidence is temporary and ignored;
archive selected evidence separately if a persistent review depends on it.
The tool writes `ai/visual/reviews/<label>.md` and refuses to overwrite a review.
For a dependency/extraction failure before a review exists, rerun the same label
with `--evidence-only` to reuse its movie and recorded scenario. That mode still
requires FFmpeg and does not recapture gameplay. If a review already exists, use
a new label rather than expecting the retry to overwrite it.

## Scenarios, replays and controlled fixtures

Scenarios may select `player_class: "synthforged"` (default Riftwalker) and a
supported AutoWalker `loadout`. `stills_only: true` uses the native renderer and
saves PNGs without requiring FFmpeg; it cannot establish continuous motion/audio.
Run it through the same launcher:

```powershell
python tools/visual_pipeline/run.py synthforged-cards --label synthforged-review --godot "$godot"
```

The development-only `fixture: "synthforged"` supplies all 28 authored cards to
real CardUI, with high energy/hostile HP, revealed resource cells, repositioned
targets and fresh constructs. Shared runtime fixtures assert authorization,
costs, outcomes and piles; then exercise all four construct attacks, the actual
allied/enemy phase, Overclock and authoritative collapse. Each card records
before/contact/recovery stills. These are controlled initial conditions, not a
natural run. Fixture failures or missing completion fail the capture command.
Review actual PNGs and timing.json before acceptance. `--baseline` comparison
requires movie captures.

Reusable inputs live in `tools/visual_pipeline/scenarios/`. Copy a nearby JSON
and provide `event`, real encounter resource, seed, policy (`greedy`, `random` or
`stress`), duration greater than zero and at most 120 seconds, and fps from 1 to 60.
Pass its basename or JSON path. Optional `expect_card` matches the exact display
name; confirm it in timing.json, not just the scenario text. Non-card events omit
it and require explicit trace/frame confirmation. Optional `replay` points to an
AutoWalker simulation report and follows its recorded actions/checkpoints.

Make abilities available through actual card/resources/loadout or a replay. Do
not implement a second spell in a fixture. Action boundaries are not necessarily
impact times; current sampled offsets are estimates unless an event-specific
signal identifies the phase.

The supported `fixture: "ruin"` deliberately pauses policy decisions, changes the
occupied tile to a ruin, restricts its effect pool to block and then empty, and
calls the real `apply_tile_effects` API twice. Startup effects still run. This is
repeatable tile feedback, not a natural movement replay. Ruin timing/frame events
and six native phase PNGs support inspection without FFmpeg extraction; that
fixture fallback is not a general movie/extraction replacement.

For campaign encounters, use the same scenario format with the desired encounter
resource. `stills_only: true` saves native frames without FFmpeg. Use a new label
for each capture; encounter stills do not certify a full campaign or continuous
animation/audio.

## Compare and investigate

Match engine, renderer, resolution, seed/replay, speed and initial conditions.
Deterministic gameplay does not imply pixel-identical GPU particles, camera noise
or watchdog timing. Comparison reports trace alignment/final observation, not full
mechanics equivalence or visual quality. Silent comparison video cannot establish
audio quality; sparse stills miss brief impulses and continuous motion.

For missing imports, open the real project and finish import. For empty captures
or renderer failure, read console.log/godot.log and verify a native display. For
FFmpeg failures, use a full build and inspect supported demuxers/filters. If the
expected card is absent, choose a suitable seed/replay or longer scenario. A
bounded capture can end during an action and expose shutdown resource diagnostics;
separate these from script failures. Do not repeatedly rerun unchanged failures.

## Source art and integration contracts

Current references are the illustrated Riftwalker, creatures, card art and terrain
under `assets/rift/`. Approved direction uses dark ink contours, controlled cel
shading and slate/ivory with focused cyan, plum, gold/ochre accents. Preserve the
Riftwalker's teal sleeves, brown gloves/boots and ivory mask. Reference the approved
Arcane Bolt and original Riftwalker explicitly for related new raster assets;
compose each card from its own mechanics, not a repeated sprite collage.

| Asset | Current contract |
| --- | --- |
| Cards | 592Ã—396 illustrations, shown through the shared 148Ã—99 art viewport in CardVisuals. |
| Units | 512-square transparent sources, grounded using real alpha bounds; preserve scene scales, body/ground anchors and picking. |
| Terrain | 256Ã—128 atlas, four columns/two rows of 64px pointy hexes; retain alpha mask, cell addresses, navigation/collision and custom data. |
| Illustrated FX sheets | Four columns/two rows, packaged as 1024Ã—512 with eight 256px frames; real alpha and safe frame gutters. |

Art packaging/validation requires Pillow. `python tools/prepare_rift_art.py --help`
lists supported categories; `SOURCE KEY cards` preserves the full composition,
`SOURCE KEY entities` validates transparency/fits the silhouette, and `SOURCE KEY fx`
packages sheets/particle extracts. Packaging writes canonical assets: inspect the
selected source and output before invoking it. `--frame-inset` reserves sheet gutters.
Edit shipped SVG icons directly. Menu textures and enemy variants are authored
assets; the one-off scripts that originally generated them are retired.

Active animations reference original PNG sources under `assets/rift/fx/atlases/`
through explicit AtlasTexture rectangles and padded margins. Consuming sprites
compensate for source resolution. The packaging script’s nominal-cell output
does not reproduce these phase definitions. Legacy
WebP sheets remain deliberately preserved; the current art validator reports them
as unused, so its unused list is not authorization to delete them.

Maintained source manifests and per-ability direction are in
[ai/visual/reference/](../ai/visual/reference/README.md). Tool-consumed inventories
are preserved there. Some provenance entries record historical production and
external generator paths; they are not runtime dependencies or promises that old
captures remain available. The VFX inventory retains historical source coverage;
verify current consumers before using it. `python tools/validate_rift_art.py`
checks actual references, alpha,
dimensions, footprints and unused outputs.

## Preserve runtime authority

CardFxRunner owns pre-effect sequencing; SpellOrigin/ImpactAnchor align flight and
contact. Ground effects use hex origins. Spell signature/layer scenes own bounded
presentation, not damage or turn scheduling. Use per-instance materials where
uniforms animate. Keep projectile completion/timeout/cancellation guards and one
visual owner per contact. Cosmetic RNG must not consume gameplay RNG.

Phantom Camera owns framing, using revealed terrain and actual HUD safe areas.
Wheel zoom, middle drag, Home reset and F overview remain available; aiming locks
camera input. Tune framing through its scene settings. TerrainDepth follows
authoritative TileMap cells and explicit
presentation events; collapse samples visible art before erase and frees debris.
Never reveal fogged art through tall actors, effect layers or falling fragments.

Arcane Bolt uses `ui/fx/arcane_bolt_beam_fx.tscn`: a connected cyan/ivory
channel, not a separately flying missile. Arcane Blast retains its traveling effect.
Preserve its connected source/contact geometry when editing the effect.
The [phase review](../ai/visual/reviews/corrected-beam-block-frames.md)
provides timestamped examples and the matching mechanical comparison.

Phase Step phases the real player sprite and restores opacity on
cancellation. Eldritch Barrier is a brief translucent application cue; held block
is a stat, not a persistent dome. Real damage-driven block depletion has a separate
fracture cue. Keep hit reactions, impulse strengths, readable numbers, cleanup and
shared UI ownership consistent when changing an effect. Particle counts are
budgets, not performance measurements.

Agent production/critique procedures remain in [ai/visual/](../ai/README.md),
including event specs and explicit evidence gates. Human contributors use the
same capture commands and runtime contracts.
