# Production and regression standards

Use actual combat execution and current presentation systems. Never duplicate damage, costs, targeting, statuses, collapse rules or turn scheduling in a visual fixture. Configure an encounter/seed or replay; add event-specific setup only through real project APIs and document any changed initial conditions.

## Timing and spatial contracts
Preserve projectile completion and CardFxRunner waits. Contact, hit flash, sound, damage text and camera impulse must correspond to the same event. Measure using captured action boundaries; a card_played signal is not automatically an impact marker. Annotate inferred phases as estimates. Keep tile borders, warnings and collapse geometry synchronized with the same TileMap conversion and round. Preserve terrain/caster/target relationships and source/impact anchors under transformed parents.

## Shaders and particles
Use local materials for per-instance animated uniforms. Test overlapping instances for cross-talk. Shape alpha and edges deliberately; a rectangular gradient canvas must not show its bounds. Check HDR and captured color before diagnosing washed-out art. Avoid unbounded shader loops, fullscreen overdraw and indiscriminate additive white. Give particle bursts intentional emission direction, velocity spread, lifetime and fade; counts are a budget, not a quality score. Keep GPUParticles visibility bounds large enough for trails, seed them when reproducibility matters, and verify restart and cleanup. Headless GPU completion cannot validate rendered lifetime.

## Animation and lifecycle
Use native Tween, AnimationPlayer, AnimatedSprite2D, shaders and particles as appropriate. Bound every transient and release interrupted effects. Distinguish gameplay RNG determinism from GPU particle determinism. Do not alter gameplay RNG consumption for cosmetic variation. Preserve hit reactions, idle motion, death/collapse presentation and presentation_speed behavior. Camera motion must remain subordinate to readability.

## Evidence gate
Capture baseline before edits and revised after edits with matching engine, renderer, resolution, seed/replay and speed. Save scenario, command, logs, action trace and timing alongside video. Sample preparation, motion, contact estimate and recovery rather than hundreds of identical images. Compare action sequences and final state as well as visible feedback. If events diverge, explain alignment limits before attributing differences to an effect.

Every review must mark each as observed, failed or not exercised: hit reactions; combat feedback; spell identity; camera impulses; targeting highlights; tile edge synchronization; collapse presentation; environmental atmosphere; animation timing. Unexercised collapse needs a dedicated longer scenario before approving collapse changes. Identify additional defects independently. Findings need a timestamp/frame, visible evidence, consequence and actionable correction. Pixel metrics cannot approve art. Never report unseen video or frames as inspected.
