# Arcane Bolt in seeded tier-0 combat — cohesion-combat

Status: inspected; superseded by cohesion-final.

Evidence: `.qa-tmp/visual/cohesion-combat`; 18 frames.
Expected event observed: True.

## Inspection
Opened frames 03 (1.450 s), 09 (2.733 s), 17 (11.833 s), plus native
UI/terrain screenshots. Continuous video and audio were not inspected.

## Findings
Terrain reads as continuous stone without the pale inset resource hexes. At
1.450 s, the card resolution pose, actor silhouettes and ground accents remain.
At 2.733 s, the support effect stays local to the player. At 11.833 s, hit flash,
warning fractures and screen-edge damage feedback remain visible. Found truncated
card names and a raw `%s` intent during resolution; corrected in the final pass.
Large-board native screenshot still cropped behind cards: reduced the existing
PhantomCamera tactical minimum and retained manual zoom/pan.

## Regression checks
Hit reactions and combat feedback: observed in sampled frame 17. Spell identity:
existing support/phase silhouettes observed; Arcane Bolt confirmed in metadata,
not isolated in these three frames. Camera impulses and continuous timing: not
verified from stills. Targeting: native target-alignment fixture. Edge sync and
collapse: native terrain fixture, two shrinks, zero failures. Atmosphere: observed
in all three frames. No spell choreography was replaced.

## Decision
Revise for composition/readability; see cohesion-final. This is an intermediate
capture after the first edits, not the pristine checkout baseline. Original
before evidence is in `.qa-tmp/cohesion/before` and `terrain-before`.
