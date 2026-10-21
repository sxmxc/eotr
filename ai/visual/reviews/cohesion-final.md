# Arcane Bolt in seeded tier-0 combat — cohesion-final

Status: accepted within the representative coverage below.

Evidence: `.qa-tmp/visual/cohesion-final`; 18 frames.
Expected event observed: True.

## Inspection
Opened frames 03 (1.450 s), 09 (2.733 s), 17 (11.833 s) against the same
intermediate capture timestamps. Also opened native final-battle battlefield,
final-ui shop/rewards, rooms-after consent/campfire/treasure, after menu/map,
and final-terrain shrunk screenshots. Native screenshots use the 1920×1080
viewport; validation included 1920×1080 and 1280×720 windows. No continuous
video or audio inspection; video PNGs exhibit compression in dark gradients.

## Findings
The final battlefield retains stone continuity, differentiated outer strata and
clear warning/target signals. Native large-board framing no longer forces the
top units behind the run HUD. Hand names are complete in inspected shop/combat
examples; long rail plans wrap instead of losing the armor clause. At 1.450 s,
Phase Step art and actor silhouettes remain readable. At 2.733 s, support art
remains concentrated around its beneficiary. At 11.833 s, impact and collapse
signals remain distinct. That capture exposed a pre-existing raw `%s` intent;
a subsequent display-only fallback and numeric-preservation regression pass
headlessly. Its correction is not reflected in the already-recorded video.

## Regression checks
Hit reactions/combat feedback: observed sampled flash, status and damage vignette.
Spell identity: Phase Step and support imagery observed; Arcane Bolt confirmed
in timing metadata; all 29 signature lifetimes pass native checks. Camera
impulses and continuous animation timing: not verified by sparse frames.
Targeting: actual TileMap alignment fixture passes. Tile edge sync and collapse:
two successive real shrinks pass cached-boundary and debris-release checks.
Atmosphere: illustrated void preserved; no new fullscreen effects or particles.

## Decision
Accept this bounded cohesion pass. Incremental comparison has matching setup,
all 10 actions identical, zero action-start drift and matching final observation.
This is not a pristine-before mechanical comparison or a full-campaign proof.
Original visual baseline is the native screenshots under cohesion/before and
terrain-before. Existing two hidden map-emitter assertion failures persist in
the broad UI fixture; focused room, transaction, terrain and battlefield checks
pass. Hardware performance, exports, ultrawide and continuous audio/motion remain
unverified. No new generated art, runtime dependencies or rendering architecture.
