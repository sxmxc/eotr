# Arcane Bolt — revised capture critique

Decision: accept the limited contact-layer reduction; broader presentation still needs refinement. This is not blanket visual approval.

## Evidence inspected
Baseline and revised frames 02-0.687.png and 03-0.917.png under .qa-tmp/visual/bolt-baseline and bolt-revised were opened directly. timing.json and comparison.json were inspected. Both capture.avi recordings and revised/comparison.mp4 exist. Continuous video and audio were not inspected with the available image viewer; judgments below concern sampled phases only.

## Direction and change
See ai/visual/specs/arcane-bolt.md. Reduced the shared arcane_hit_signature Illustration scale from 0.30 to 0.21. Shader surface, 0.32-second duration, sparks, damage, targeting, camera config and execution code remain unchanged.

## Findings
- Improved, 0.687s: the revised spiral is concentrated over the head rather than extending across nearly the whole body. More of the Blob's outline is visible while cyan/white contact remains clear. The target hex stays readable.
- Medium residual defect, 0.687s: the white hit reaction still removes interior creature detail. A future direction should shorten the solid-white reaction peak or retain ink contours in its shader, with an isolated reaction capture before changing shared enemy feedback. The scale reduction alone does not solve this.
- Low existing defect, 0.687s: damage numeral 6 overlaps the target's face while the earlier player damage numeral 5 is farther left. Evaluate a stable damage-label lane above ImpactAnchor to separate silhouette and typography, preserving attribution.
- Inspection risk, 0.917s: framing changes substantially between the contact and recovery samples, while some sidebar text appears visually crowded. Compare continuous camera/label motion before attributing this to the impulse; do not change camera strength based on two stills.

## Gameplay and timing
Both captures: same encounter/seed, ten identical recorded actions, zero start-boundary delta, equal 12.0333-second capture duration, equal final observation. First Arcane Bolt records at 0.5333s; action polling records its start at 0.5667s. Polling has one-frame uncertainty and is not a precise impact marker. Terminal observation equality is a bounded diagnostic, not proof of every internal invariant. No SCRIPT ERROR occurred in either rendered capture. Native certificate-store and exit-resource warnings remain; the duration cutoff can interrupt live actions.

## Required regression checks
| Check | Evidence / status |
| --- | --- |
| Hit reactions | Observed white contact flash and restored creature detail at recovery; continuous recoil unverified. |
| Combat feedback | Observed damage numerals, health 5/11 and energy 2/3; audio unverified. |
| Spell identity | Observed concentrated cyan/white arcane spiral; continuous launch path unverified. |
| Camera impulses | Not verified from sparse stills; config unchanged and framing movement visible. |
| Targeting highlights | Observed cyan selected hex at contact, hostile ring at recovery. |
| Tile edge synchronization | No apparent local contact-frame misalignment; animated synchronization not verified. |
| Collapse presentation | Not inspected; no approval implied for collapse. |
| Environmental atmosphere | Observed dark illustrated cliffs/fog and terrain hierarchy retained in matched frames. |
| Animation timing | Recorded action boundaries match; fine motion/easing not verified. |

## Follow-up
Prioritize the white-flash contour problem and inspect camera motion before further cosmetic edits. Review other consumers of the shared hit signature before treating it as fully covered. One baseline/revised capture pair completes this bounded demonstration; no endless refinement loop was performed.
