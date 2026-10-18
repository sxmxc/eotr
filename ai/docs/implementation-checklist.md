# Implementation checklist — 2026-10-17

Status vocabulary: not started, in progress, blocked, complete. A complete item
requires implemented behavior and recorded validation, not a proposal or scaffolding.
All five deliverables are mandatory. No scope has been deferred or removed.

## Sequence and dependencies

Audit → standalone telemetry JSONL/schema vertical slice → AutoWalker real combat
interface and baseline → combat corrections → Watch/policies/replay/batches → Talo
migration/instrumentation → backend source/package → integrated validation.
AutoWalker uses the addon from its first simulation; replay artifacts are independent
QA records, not a replacement telemetry implementation. Backend and game consume the
same portable event schemas. No backend service or container may be started.

## 1. Combat and enemy AI — in progress

Files: scenes/game_world/{game_world,battle_state_controller}.gd,
scripts/nodes/enemy_handler.gd, scenes/enemy/**, scripts/resources/battle_stats.gd,
ui/card_ui/card_ui.gd, scripts/nodes/proc-gen-tilemap.gd.

- [ ] Enemy-elimination default victory; explicit special objective retained.
- [ ] Destroyed Obelisk stops attacks/summons; existing enemies survive.
- [ ] Stable victory/death/turn/spawn/teardown boundaries, no duplicate completion.
- [ ] Feasible weighted actions, bounded movement/pathing, useful fallback.
- [ ] Collapse/occupancy awareness and readable existing enemy roles/intents.
- [ ] Focused combat checks and real bot encounter results recorded.

## 2. AutoWalker — in progress

Files: scripts/autowalker/**, scenes/developer/autowalker/**,
tools/run_autowalker.py, ai/docs/autowalker-architecture.md.

- [ ] Shared observable-state/legal-action interface revalidates actual game actions.
- [ ] Random, greedy, stress policies with decision scores and bounded actions.
- [ ] Sequential headless batch runner: seeds, encounter, limits, timeout, reports.
- [ ] Actual GameWorld Watch Mode with start/stop/pause/action/turn/speed controls.
- [ ] Seed/configuration/policy versions/action trace/checkpoints/failure artifacts.
- [ ] Watch replay detects divergence and supports pause/step/inspection.
- [ ] Supported progression/reward/run automation, limitations explicitly documented.
- [ ] Local reports distinguish bot outcomes; regression comparison supported.
- [ ] Watch/headless/replay/batch validation evidence recorded.

## 3. Standalone telemetry addon — in progress

Files: addons/godot_telemetry/{core,resources,transports}/**, plugin.cfg,
plugin.gd, README.md, scripts/tests/telemetry_test.gd.

- [x] Game-independent code and Resource configuration authored.
- [x] Portable schema validator, event envelope and context API authored.
- [x] HTTP/JSONL/Null transport abstraction and implementations authored.
- [x] Bounded queue, batching, backoff, timeout, stable IDs authored.
- [x] Consent/enablement/filter/profile/HTTPS controls authored.
- [x] Runtime schema + JSONL vertical slice verified before AutoWalker.
- [ ] Failure/retry/limits/disabled/withdrawal/shutdown tests passing.
- [ ] Independent installation and privacy/reliability limits documented.

Authored boxes above do not establish runtime correctness or completion.

## 4. Talo migration — in progress

Files: scripts/autoloads/telemetry_manager.gd, telemetry/{schemas,config}/**,
existing game instrumentation in scenes/scripts/ui,
ai/docs/telemetry-migration.md, ai/docs/telemetry-architecture.md.

- [x] Existing event/stat/identity gates audited in combat-improvement.md.
- [ ] TelemetryManager delegates delivery to addon; no Talo telemetry dependency.
- [ ] Unrelated Talo identity functionality preserved.
- [ ] Authoritative lifecycle events and numeric JSON properties.
- [ ] Portable shared schemas cover game, simulation, lifecycle and diagnostics.
- [ ] Production/development/QA profiles, backend-free default, consent validated.
- [ ] Compatibility tests updated to migrated behavior.

## 5. Analytics backend — in progress

Files: backend/telemetry/ingest/**, clickhouse/migrations/**,
grafana/{dashboards,provisioning}/**, compose.yaml, .env.example, README.md.

- [ ] Batch ingestion, shared schema/envelope validation, bounded payloads/rates.
- [ ] Acknowledgements, retryable/permanent failures, deduplication semantics.
- [ ] ClickHouse versioned migration, retention, deduplicated reporting view.
- [ ] Five provisioned dashboards with game/environment/build/time/source filters.
- [ ] Dockerfile, Compose, persistent volumes, health checks, secret templates.
- [ ] Isolated mocked ingestion tests, JSON/config/static SQL validation.
- [ ] Deployment/backup/upgrade/rollback/HTTPS/later integration procedures.
- [ ] Confirm no services started or deployed.

## Evidence log

- Initial repository inspection: clean git status; no root AGENTS.md; followed
  ai/docs/agents.md and ui-authoring.md; queried Godot 4.7 Context7 docs.
- Architecture audit written before implementation: combat-improvement.md.
- Godot executable available: D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe.
- Backend startup prohibition active for the entire initiative.
- Standalone telemetry test: zero assertions failed in Godot 4.7.2. Existing
  certificate/history/shutdown diagnostics remain; not a clean process shutdown.
- First real AutoWalker slice played two arcane bolts and resolved enemy actions.
  Full encounter/replay/batch verification is still pending.
- Backend ingestion unit tests: six passing, all dependencies mocked, no server
  socket or service started. Database/dashboard integration remains unverified.
