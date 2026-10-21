# Arcane Bolt in seeded tier-0 combat — art-direction-final

Status: inspected; accepted within bounded coverage.

Evidence: `.qa-tmp/visual/art-direction-final`; 18 frames.
Expected event observed: True.

## Inspection
Opened frames 03 (1.450 s), 09 (2.733 s), 17 (11.833 s) against the prior
cohesion-final equivalents. Also opened before/final screenshots for all six
requested screens, card discovery and disabled shop, plus the progressed route.
Continuous video/audio were not inspected. Dark video gradients show compression.

## Findings
At 1.450 s: shorter turn guidance, quiet spoils, full hand and established Phase
Step/card-resolution silhouette remain. At 2.733 s: wait uses a compact glyph
instead of a wide label; the inspected enemy plan still has full wording. At
11.833 s: collapse fractures, damage vignette and local hit art remain visible;
an unresolved intent now says Attack rather than the prior raw template. Native
screens exposed and corrected a menu-preview pivot overlap, excessive logo/nav
gap and clipped long rules. The final rules-area adjustment was checked with a
focused native reward/transaction capture after the main final suite.

## Regression checks
Hit reactions and combat feedback: sampled flash, damage vignette and status
values observed. Spell identity: Phase Step and support art observed; expected
Arcane Bolt present in trace. Camera impulses/continuous animation timing: not
verified from sparse stills. Targeting: untouched; this capture did not isolate
legal-mask alignment. Tile edges/collapse cleanup: unchanged since previous
validated pass, not re-exercised by this short clip. Collapse warning: observed.
Atmosphere: existing illustrated void and contact silhouettes retained.

## Decision
Accept the screen composition and information-hierarchy pass. Native focused
checks pass; comparison reports matching setup, all ten actions with zero start
drift, and matching final state. No mechanics, terrain/camera system or combat
choreography changed. Full campaign, exports, continuous motion/audio and hardware
profiling remain outside the evidence. See docs/ui-authoring.md.
