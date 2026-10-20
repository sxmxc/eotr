# Final direction supersedes the dome proposal below

The developer rejected the persistent dome. Final implementation restores a brief translucent illustrated application cue, with no persistent world object; the block stat communicates held protection. Application uses only assembly phases, without the source sheet's pre-painted hit. A separate brief illustrated fracture plays only on real damage-driven block depletion, including block granted by Nano Shield. See `ai/visual/reviews/corrected-beam-block-frames.md` for final evidence and limitations.

---

# Eldritch Barrier â€” a shelter that actually catches the blow

## Discovery and choice
Inspected Phase Step, Mana Leech, Echo, Nano Shield and Eldritch Barrier source. Selected Barrier after a fresh real-combat capture, not from source alone. Reference: assets/rift/cards/eldritch_barrier.webp (opened): the Riftwalker is readable inside a curved cyan shelter with a concentrated edge response where the attack touches it.

Gameplay: resources/data/cards/riftwalker/eldritch_barrier.gd creates CardEffectConfig.for_block(10); cost 1; BlockEffect adds block synchronously, plays blessing3.wav and instantiates this ability's VisualFX under the player. CardUI, CardResolver, block consumption, player hit feedback and PhantomCamera retain authority. Name in the resource is misspelled Eldricth Barrier; the scenario uses that actual name for event confirmation. The effect is cosmetic and must never write Stats, unit transforms, Engine.time_scale or RNG.

## Baseline evidence and diagnosis
.qa-tmp/visual/barrier-before: Movie Writer, seed 1, greedy, tier_0_blobs, 10s at 30fps, native 1920x1080 Forward+. Card event 8.1s, polled action start 8.133s; allow one frame uncertainty. Opened full 8.4s frame and twelve chronological crops from 8.1s through 9.2s at 0.1s spacing. Continuous video/audio cannot be inspected with the available viewer.

Observed: 8.2â€“8.5s the pointed flat ward occupies the torso and lower face; the center mesh dilutes the illustrated character's silhouette. 8.4s the animation includes a white star-shaped collision on its upper left before the Obelisk bolt enters the later samples. At roughly 8.7s the ward is gone during the actual blocked strike; a generic cyan puff and white reaction remain. HUD block is 10 before, 4 after; protection exists mechanically after its picture disappears. These are specific choreography and state-readability failures, not complaints about particle count.

## Direction
A small curved shelter closes upward from the Riftwalker's own ground contact. Ink-edged cyan flanks and a sparse crown frame the body rather than cover it; transparent interior leaves the cloak/face readable. Brass clasp details borrow the character's existing costume accent, not a new color family. Grounded elliptical contact supplies depth without implying a multi-hex area or a shield icon pasted on the torso.

Choreography: two side membranes rise in a short stagger, resolve into a coherent arch, then settle to a quieter held state. No baked-in impact flash at cast. Read the live block value; a reduction during a real Player damage presentation makes the shell flex and its rim briefly brighten. Keep the original player flash, damage numeral, audio and camera impulse intact. Reduce the ward's strength after absorption, and release on block expiry/next player turn/owner removal. Recasting refreshes the existing cosmetic ward instead of stacking opaque shells.

Use native CanvasItem drawing for curved silhouettes, faceted side membranes and inlaid strokes. No new images, particles, global shader, camera or combat hooks. Geometry has fixed deterministic parameters and owns no gameplay RNG. Draw back membrane below Sprite2D and front accents above it. Child-local coordinates preserve movement and grounded position.

## Acceptance and bounded validation
Same scenario before/after; compare full action dictionaries/checkpoints, action boundaries, setup and final observation. Inspect ordered close frames through casting (8.1â€“8.6), real absorption (8.6â€“9.3) and held state (9.3+), plus full battlefield frames for composition. Verify the character remains readable, no pre-hit strike appears, the real attack meets visible protection, and block UI still changes 10 to 4 without health loss. Inspect one revised capture; make one correction if significant defects remain, then one final capture. Explicitly distinguish sampled temporal evidence from real-time motion or audio judgments. Check reuse/expiry/cleanup with a focused native test if not exercised by the capture.
