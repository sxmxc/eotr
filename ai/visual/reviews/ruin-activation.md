# Ruin activation review

## Evidence inspected

Baseline .qa-tmp/visual/ruin-before: ruin-1-contact.png (1.133s),
ruin-2-rise.png (2.767s). Revised .qa-tmp/visual/ruin-after:
ruin-1-contact.png (1.133s), ruin-2-rise.png (2.767s),
ruin-1-recovery.png (1.8s). Read both timing records and revised comparison.json.
Native Godot 4.7.2 Forward+, 1920x1080, 30 fps, seed 1, identical fixture.
AVIs were recorded but not watched. Continuous motion, brief impulses and audio
are unverified. FFmpeg is absent; used capture.py plus native fixture PNGs rather
than run.py extraction/comparison encoding. No side-by-side video was produced.

## Findings

- At 1.133s, revised gold strokes echo the occupied tile's broken columns without
  obscuring the player's silhouette or block count. The localized footprint is
  subordinate to the character and avoids a generic spell circle.
- At 2.767s, the empty outcome identifies Ancient Ruin and wraps within the left
  message rail. The repeat echo remains on the occupied tile.
- At 1.8s, the first transient strokes have disappeared; original landmark ink
  remains. Focused native and headless tests also verify independent overlapping
  instances release after playback.
- Minor pre-existing issue at 1.133s: startup messages occupy the left rail and
  compete with the first outcome. Retain current routine priority and queue
  behavior; changing the shared message hierarchy is outside this task.
- Capture shutdown reports ObjectDB/resource warnings in both runs. No script
  errors occurred. These bounded captures terminate an active world; focused
  validation shuts down explicitly and passes. Existing certificate-store and
  terrain-depth UID fallback diagnostics remain.

## Regression checks

| Check | Result |
| --- | --- |
| Hit reactions | Not exercised by inspected fixture frames |
| Combat feedback | Observed: block number, unchanged final block and outcome message |
| Spell identity | Not exercised; no spell changes |
| Camera impulses | Not exercised; camera framing matches stills |
| Targeting highlights | Not exercised; policy paused |
| Tile edge synchronization | Observed static tile alignment only; dynamic shrink not exercised |
| Collapse presentation | Not exercised; no collapse changes |
| Environmental atmosphere | Observed: terrain/fog remain subdued; no hidden tile effect |
| Animation timing | Observed phase samples: contact, rise, recovery; continuous motion unverified |

## Mechanics and decision

Comparison reports equal final observation, trace, event sequence/timestamps,
scenario, engine, renderer and viewport. The fixture has no policy actions and
only two explicit real tile-effect activations, so this does not establish whole
combat determinism or RNG-state equality. Production adds no RNG calls.

Accept this bounded presentation change based on sampled native evidence and
focused runtime tests. Optional continuous-motion/audio review remains; no
collapse or campaign approval is implied. Implementation: proc-gen-tilemap.gd,
board_overlay.gd, ruin_activation.gd/.tscn. Fixture and scenario changes are
development-only and do not alter production effect execution.
