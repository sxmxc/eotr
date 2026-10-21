# BKL-031 / BKL-019 - 2026-10-21

Implemented 0.3.0.0: three acts, 45 floors, 40 campaign encounters, distinct
bosses, checkpointed transitions, rewards/refinement, boss HUD, persistent
telemetry context and corrected Void art. See docs/campaign.md.
The main journal's existing invalid UTF-8 was preserved; this entry is separate.

## Verification

- Final focused campaign suite: zero failures. Covers transition save/resume,
  legacy migration, rewards, actual shop transactions, boss counterplay,
  preview modifiers, collapse, Weaver safety and Debt Eater intentions.
- Real AutoWalker: .qa-tmp/bkl-031/run-release/simulation-2.json; seed 2,
  policy 2.1.0, 45 floors, victory, 78 turns, 474 actions, zero simulation
  failures or invalid actions, 1628 telemetry events delivered. This run
  preceded the last preview modifier, registry canonicalization and relay
  placement changes; final focused tests cover those adjustments.
- Combat automation, status lifecycle, board queries and telemetry pass.
  Python QA: four tests pass. Telemetry ingest: eight tests pass.
- Compatibility smoke retains two pre-existing left/right map emitter position
  failures. The baseline is not fully green.
- Native 1920x1080 Forward+ captures exist for normal, Elite and boss rooms
  across all acts in .qa-tmp/bkl-031/visual/. Final boss stills were inspected,
  including final-unmaking-placement/frame-02.png. Backgrounds remain quiet
  behind the independently rendered hex battlefield.
- Accelerated structural traversal and real AutoWalker completion are separate
  evidence. Neither proves human balance. Continuous audio/video and release
  exports were not verified; FFmpeg was unavailable.

## Suggested commit

Implement three-act runs and distinctive Rift bosses

## Draft PR comment

Summary: Extend runs to three acts with distinct bosses and persistent act
transitions, preserving the ordinary combat lifecycle.

Key changes: Act-specific pools; optional Elites; rewards and refinement;
Bulwark ram/recovery, Spectre chorus and Prismatic relay mechanics; aggregate
boss HUD; deployed-schema-compatible telemetry; Void artwork replaced in place.

Tests: Campaign, combat, status, board, telemetry and backend checks pass;
real 45-floor AutoWalker victory and native act captures. Two existing emitter
smoke failures remain. Human balance, continuous audio and exports remain unverified.

## Follow-up actions

1. Human playtest pacing and difficulty across all three acts.
2. Review continuous animation/music and release exports.
3. Resolve the separately documented map emitter smoke failures.
