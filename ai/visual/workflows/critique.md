# Critique workflow

1. Open the baseline and revised videos if your tools support video inspection. Otherwise open representative PNGs from frames.json and use timing.json; explicitly state that continuous motion, audio and brief impulses remain unverified. Do not fabricate observations.
2. Compare the same action and relative phase using comparison.json. comparison.mp4 is synchronized by capture start, so action drift requires manual phase alignment. Check scenario/engine/render settings and final state before interpreting differences.
3. Evaluate focal clarity, silhouette, value peaks, material motion, source/contact alignment, anticipation, recovery and environmental integration against the spec. Find defects the developer did not name. Separate observed defects from code-based risks.
4. Complete the generated ai/visual/reviews/<label>.md: evidence actually inspected, timestamped observations, severity, intended behavior, correction, all nine regression checks, mechanics comparison and accept/revise decision. Mark absent coverage not exercised; do not silently pass it.
5. Recommend concrete edits with priority. Perform one bounded refinement when justified and authorized; capture again only if the edit changes the evidence needed. Record remaining limits instead of entering an endless screenshot loop. No similarity score can replace artistic judgment.
