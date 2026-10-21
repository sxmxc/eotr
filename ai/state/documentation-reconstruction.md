# Documentation reconstruction — October 21, 2026

Developer documentation now lives in `docs/`; agent workflows/planning and visual
production instructions remain in `ai/`. README and a new root AGENTS entry point
link to those sources. The guides explain systems and procedures directly;
reconstruction history and acceptance questions are kept out of their introductions.

## Consolidation

Completed combat, Talo migration, architecture, UI, art, battlefield and cohesion
reports were replaced by current system/authoring/operator guides. Their useful
constraints survive: elimination victory, resource/save safety, scene/theme
ownership, anchors, fog/collapse authority, projectile/cancellation sequencing,
native evidence procedure, source provenance and known validation limits.

AutoWalker retains its detailed command/control/output/troubleshooting reference,
with corrected paths, consent, loadout clamping, policy/shop and campaign behavior.
Telemetry connects instrumentation, portable schemas, local/HTTP clients, backend
operation and read-only querying. The backend keeps its package-local operator
runbook; the addon README now correctly describes its host-project test launcher.
Visual workflows/specs/reviews and tool-consumed inventories were preserved.
Inventory locators in three Python tools were updated; no tool behavior changed.
One generated old bot-results JSON moved to ignored documentation-audit evidence.
No source assets, scenes, tests, fixtures, scenarios or intentional baselines were
removed. Existing backlog/progress statuses were preserved; path references changed.

## Validation performed

All checks used the original project and offline/disposable saves. No services,
migrations, uploads, dashboard writes, exports, commits or pushes were performed.

- Scene/resource guard: zero problems. CLI help verified for AutoWalker, visual
  capture, project validation and campaign validation.
- Active act resources/registries checked: 18/11/11 definitions, 30 normal,
  seven Elite and three boss encounters. Run/map/save/card/relic/boss behavior and
  telemetry/capture/configuration claims checked against implementation.
- AutoWalker tier-0 blobs, greedy seed 1: exit 0, win, eight turns, 28 actions,
  zero technical failures/invalid actions/timeouts/softlocks; local-only telemetry.
  Evidence: `.qa-tmp/documentation-audit/autowalker/`.
- Focused boss suite: exit 0, zero errors. Telemetry host-project test: exit 0,
  zero failures. Launcher tests: nine pass; QA-data tests: four pass; loadout
  comparison test via unittest discovery: one pass. Direct execution of that last
  test file does not discover its test, so the guide uses unittest discovery.
- Broad compatibility smoke: exit 1, two existing map emitter-position assertions
  reproduced. Log: `.qa-tmp/documentation-audit/smoke.log`.
- Art validator: flags 12 preserved legacy WebP FX sheets and shuffle.svg as unused.
  Active corrected PNG atlas definitions and preservation are explained in the
  visual guide; no art deleted to satisfy this check.
- Existing native capture implementation, nine-second stills-only scenario:
  exit 0, three 1920×1080 Forward+ PNGs, timing/command/trace/log evidence, seven
  actions. Opened frame-02.png to confirm readable native scene output. No
  continuous video/audio or full FFmpeg extraction claim. Evidence:
  `.qa-tmp/documentation-audit/native-stills/`.
- 96 local Markdown targets resolve. Source paths, retained JSON, script locator-only diffs
  and whitespace checked. Generated capture links may expire by design.

## Remaining questions

[Campaign review](../planning/campaign-review.md) retains the ongoing multi-act/boss
requirement and the discrepancy between integration completion labels and remaining
acceptance. Older Spectre rationale excluded healing/pollution, while current code
includes the Memory Anchor dependency; docs describe mechanics without inventing
approval. Human pacing/balance, broader branch/save-resume, continuous music/motion
and release exports still need their own review.

The main journal and older continuous-improvement notes have existing invalid
UTF-8; only literal byte-level path repairs were applied to those files. Certificate-store and Spectre UID fallback warnings
remain in engine logs. Current deployment health, public TLS delivery, dashboard
provisioning and backup/restore were not tested. FFmpeg is absent from PATH here.
