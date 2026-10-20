# Final corrections: beam, transient block cues, frame extraction

Implementation complete; sampled visual review performed. Artistic acceptance belongs to the developer. The persistent dome was explicitly rejected and is removed.

## Evidence actually inspected
`.qa-tmp/visual/corrected-beam-block-frames/`: `beam-sequence.png` (eight consecutive 30fps frames, 0.533–0.767s), `barrier-sequence.png` (twelve frames at 1/15s, 8.100–8.833s), `break-sequence.png` (eight consecutive 30fps native fixture frames, 1.767–2.000s), and all three `frame-preview-after-*.png` native atlas contact sheets. Original and revised native projectile rows in `projectile-frames-before-after.png` were opened. Original baseline full frame and 0.1s barrier sequence were inspected earlier. Continuous video playback and audio are unavailable; these are ordered sampled observations, not claims of evaluating continuous motion, flicker, sound or subjective real-time feel.

## Final behavior and observations
- Arcane Bolt: at 0.533 and 0.567 the source and recipient are visibly joined by the complete cyan/ivory channel. At 0.600–0.733 the connected core and folded side ribbons remain through the existing contact reaction and then recede; at 0.767 the channel is gone. There is no independent flying body or wake. The scene is exclusive to Arcane Bolt; Arcane Blast retains its existing traveling effect. Contact completion retains the previous distance/1550 timing clamped to 0.075–0.26s.
- Barrier: preserves the illustrated translucent cast the developer preferred. At 8.100–8.300 it assembles, at 8.367–8.500 it resolves, and by 8.567 it has cleared. No dome is held while block remains, and the cast never plays the sheet's later pre-painted collision frame. Nano Shield also has one brief ward, instead of the three overlapping ward icons and grid observed in its earlier 2.6s fixture sample; its separate energy feedback is retained.
- Break: the real Player damage callback creates a three-piece illustrated fracture only when positive block reaches zero. In the ordered fixture frames it opens into separated pieces and clears by the end of the short sequence. Partial absorption, direct/bypass damage and a turn reset create no fracture. Existing white hit reaction, labels, sound and camera impulses remain; their temporary overlap still obscures some body detail and was deliberately not redesigned.
- Frame audit: the old arcane row visibly has a clipped long flight frame and a detached ivory tip at the following impact. Corrected native frames show the complete flight silhouette and an uncontaminated impact. Travel-frame leading points align to their pivots. All fourteen frame sets now use explicit original-source rectangles and padded native AtlasTexture margins, rather than blindly cutting nominal cells. Original PNGs are copied unchanged into `assets/rift/fx/atlases/`; no new artwork or new image generator was used. Consuming sprites compensate for original source resolution. Other sheets were inspected as complete native contact sheets; this establishes extraction/pose coverage, not full in-combat motion approval for every effect.

## Mechanical and technical validation
Same 1920x1080 Forward+ renderer, 30fps, seed 1, tier_0_blobs, greedy policy and 10.0333s duration as the baseline. All nine action dictionaries, all recorded checkpoints and gameplay RNG states, action boundaries and final observation match. `comparison.json` confirms matching setup/final state with zero boundary drift. Native block checks pass application amounts (10 / 6 block), Nano energy gain (+3), cast cleanup, partial absorption, exact depletion, fracture cleanup, bypass/reset behavior, occupancy and gameplay RNG. Native atlas preview loads every used texture with a non-null atlas; rectangle/margin checks cover all 112 authored phase definitions (Arcane Projectile's two start frames remain unused as locally edited). Scene resource audit reports zero problems. No script or polygon errors occur in the final combat or block verification logs. The existing Windows certificate-store diagnostic remains.

## Regression checks
| Check | Assessment |
| --- | --- |
| Hit reactions | Visible existing white flash and recovery retained; continuous recoil not evaluated. |
| Combat feedback | Labels, health/block transitions and contact visible; audio not evaluated. |
| Spell identity | Connected Arcane Bolt channel, traveling Blast and transient protective casts have distinct visible forms. |
| Camera impulses | Code/config untouched; continuous camera behavior not evaluated. |
| Targeting highlights | Selected cyan target hex remains visible in beam frames. |
| Tile edge synchronization | Static tile/highlight alignment retained in samples; animation synchronization not fully exercised. |
| Collapse presentation | Not evaluated by the short final sequence. |
| Environmental atmosphere | Existing dark battlefield, fog and terrain hierarchy retained in samples. |
| Animation timing | Nine real action boundaries and checkpoints identical; closely spaced frames show application/clear and fracture/clear phases. Real-time smoothness remains unverified. |

## Remaining limits
This run verifies the requested corrections, not blanket artistic approval. Larger original atlases increase texture storage/memory versus the prior downsampled sheets. Legacy WebP sheets remain for preservation; active SpriteFrames reference the corrected PNG atlases. Standalone particle textures are separate assets and were not part of the animated-atlas extraction repair. Review videos directly for continuous feel and audio before approving those qualities.
