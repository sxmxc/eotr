# All 28 Synthforged cards through real CardUI — synthforged-reviewed

Status: inspected; accepted for the observed still-frame coverage.

Evidence: `.qa-tmp/visual/synthforged-reviewed`; 95 frames.
Expected event observed: True.

## Inspection
Native Godot 4.7.2, seed 27. All 28 card contact frames were
inspected in four labeled contact sheets, now retained in `synthforged-reviewed`.
After corrections, inspected raw `synthforged-reviewed` frames for Threat
Assessment, Vector Boost, Siege deployment recovery, Pike/Bastion/Siege attacks,
enemy-to-construct contact and collapse preparation. Overclock's +2 feedback and
5/3 energy were inspected; the collapse supplement retains those visible values.
Redundant intermediate captures were removed after inspection.

This corrected capture records 28 unique card plays and fixture completion with
zero failures. The fixture deliberately supplies excess energy, enemy health and
visibility to exercise effects; those values are not class balance. FFmpeg is
unavailable: these are native PNGs, not continuous-motion or audio evidence.

## Findings
- Fixed: Pike and Siege resource textures had become placeholder resources;
  actual texture bindings now load and distinct mechanical bodies appear in
  deployment/attack frames. Runtime assertions require each bound texture.
- Fixed: oversized construct labels obscured the battlefield. Shared badges now
  provide small health, block and attack indicators anchored to the unit.
- Fixed: Threat Assessment drew diagnostic locks on the player. Its self effect
  now closes armor segments; Analyze locks appear on hostile recipients.
- Observed: short weapon contacts, red diagnostics, armor pieces and repair tools
  retain separate identities. Damage labels, hit flashes, fog and target highlights
  remain readable in the sampled frames.
- Limited: collapse mechanics pass; the initial lifecycle framing placed the
  doomed unit near the edge of the camera. A separate final capture reframes the
  real battlefield before collapse; see `synthforged-collapse-reviewed.md`.

## Regression checks
Observed: hit reactions, damage/energy feedback, spell identity, legal destination
highlights, static terrain edges and fog/atmosphere. Construct attacks at
25.8–27.4 seconds and enemy contact at 29.2 seconds have visible recipients.
Collapse state changes are asserted through the real board shrink operation.
Continuous tile-edge synchronization, camera impulses, audio and animation
smoothness are not established by sparse frames. Contact/recovery sampling
establishes bounded disappearance only, not a complete timing review.

## Decision
Accept the inspected artwork and native effect identities. Human balance,
continuous animation/camera review and audio review remain playtest work.
