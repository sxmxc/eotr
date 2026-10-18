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

## 1. Combat and enemy AI — complete

Files: scenes/game_world/{game_world,battle_state_controller}.gd,
scripts/nodes/enemy_handler.gd, scenes/enemy/**, scripts/resources/battle_stats.gd,
ui/card_ui/card_ui.gd, scripts/nodes/proc-gen-tilemap.gd.

- [x] Enemy-elimination default victory; explicit special objective retained.
- [x] Destroyed Obelisk stops attacks/summons; existing enemies survive.
- [x] Stable victory/death/turn/spawn/teardown boundaries, no duplicate completion.
- [x] Feasible weighted actions, bounded movement/pathing, useful fallback.
- [x] Collapse/occupancy awareness and readable existing enemy roles/intents.
- [x] Focused combat checks and real bot encounter results recorded.

## 2. AutoWalker — complete

Files: scripts/autowalker/**, scenes/developer/autowalker/**,
tools/run_autowalker.py, ai/docs/autowalker-architecture.md.

- [x] Shared observable-state/legal-action interface revalidates actual game actions.
- [x] Random, greedy, stress policies with decision scores and bounded actions.
- [x] Sequential headless batch runner: seeds, encounter, limits, timeout, reports.
- [x] Actual GameWorld Watch Mode with start/stop/pause/action/turn/speed controls.
- [x] Seed/configuration/policy versions/action trace/checkpoints/failure artifacts.
- [x] Watch replay detects divergence and supports pause/step/inspection.
- [x] Supported progression/reward/run automation, limitations explicitly documented.
- [x] Local reports distinguish bot outcomes; regression comparison supported.
- [x] Honor configured HTTP backend for QA/bot uploads alongside independent local
  JSONL; expose upload health, preserve consent, provide explicit local-only mode,
  and drain multiple asynchronous batches before headless exit/Watch close.
- [x] Watch/headless/replay/batch validation evidence recorded.

## 3. Standalone telemetry addon — complete

Files: addons/godot_telemetry/{core,resources,transports}/**, plugin.cfg,
plugin.gd, README.md, scripts/tests/telemetry_test.gd.

- [x] Game-independent code and Resource configuration authored.
- [x] Portable schema validator, event envelope and context API authored.
- [x] HTTP/JSONL/Null transport abstraction and implementations authored.
- [x] Bounded queue, batching, backoff, timeout, stable IDs authored.
- [x] Consent/enablement/filter/profile/HTTPS controls authored.
- [x] Runtime schema + JSONL vertical slice verified before AutoWalker.
- [x] Failure/retry/limits/disabled/withdrawal/shutdown tests passing.
- [x] Independent installation and privacy/reliability limits documented.

Runtime evidence and explicit validation limits follow below. Completion refers to
implemented, locally validated source deliverables; live infrastructure testing is excluded.

## 4. Talo migration — complete

Files: scripts/autoloads/telemetry_manager.gd, telemetry/{schemas,config}/**,
existing game instrumentation in scenes/scripts/ui,
ai/docs/telemetry-migration.md, ai/docs/telemetry-architecture.md.

- [x] Existing event/stat/identity gates audited in combat-improvement.md.
- [x] TelemetryManager delegates delivery to addon; no Talo telemetry dependency.
- [x] Follow-up request: remove remaining Talo identity UI, compatibility methods,
  consent cleanup, sandbox settings, export references and test dependencies.
- [x] Authoritative lifecycle events and numeric JSON properties.
- [x] Portable shared schemas cover game, simulation, lifecycle and diagnostics.
- [x] Production/development/QA profiles, backend-free default, consent validated.
- [x] Compatibility tests updated to migrated behavior.

## 5. Analytics backend — complete

Files: backend/telemetry/ingest/**, clickhouse/migrations/**,
grafana/{dashboards,provisioning}/**, compose.yaml, .env.example, README.md.

- [x] Batch ingestion, shared schema/envelope validation, bounded payloads/rates.
- [x] Acknowledgements, retryable/permanent failures, deduplication semantics.
- [x] ClickHouse versioned migration, retention, deduplicated reporting view.
- [x] Five provisioned dashboards with game/environment/build/time/source filters.
- [x] Dockerfile, Compose, persistent volumes, health checks, secret templates.
- [x] Backend remains a Git submodule and builds from an independent checkout:
  local Docker context, bundled versioned schemas, local test paths and restricted
  build context. Backend-only temporary source copy passes ingestion and artifact
  checks. Docker CLI is unavailable locally, so image build remains host validation.
- [x] Follow-up: provision ingestion/reader accounts on every ClickHouse startup
  from `.env`, bound reader permissions and timeout settings, and preserve `$` passwords
  in Grafana provisioning. Static validation covers account/password/grant wiring;
  live verification remains for the operator's deployment.
- [x] Isolated mocked ingestion tests, JSON/config/static SQL validation.
- [x] Deployment/backup/upgrade/rollback/HTTPS/later integration procedures.
- [x] Confirm no services started or deployed.

## Evidence log

- Initial repository inspection: clean git status; no root AGENTS.md; followed
  ai/docs/agents.md and ui-authoring.md; queried Godot 4.7 Context7 docs.
- Architecture audit written before implementation: combat-improvement.md.
- Godot executable available: D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe.
- Backend startup prohibition active for the entire initiative.
- Standalone telemetry test: zero assertions failed in Godot 4.7.2. Existing
  certificate/history/shutdown diagnostics remain; not a clean process shutdown.
- First real AutoWalker slice played two arcane bolts and resolved enemy actions.
  Subsequent encounter/replay/batch verification is recorded below.
- Backend ingestion unit tests: six passing, all dependencies mocked, no server
  socket or service started. Database/dashboard integration remains unverified.

## Final acceptance evidence

- Standalone addon copied into a separate Godot project with no game code: schema
  JSON loading/version normalization, JSONL, queue limits, backoff/recovery, HTTP
  serialization/acknowledgements, consent/disabled/shutdown checks: zero failures.
- Combat assertions pass, including Sever Anchor cost/event/pile semantics and
  detachment from the hand before animation, alongside Obelisk/elimination checks.
- Control assertions pass for pause/action step/turn step/speed/stop. Full compatibility
  smoke loads 530 first-party resources and reports zero failed assertions.
- Greedy tier-0 seeds 1–3: 3 wins, 6/5/8 turns, 24/20/31 actions; no runner failures.
- Random tier-1 seeds 1–2: 2 losses; stress: 1 loss, 1 configured-limit abort.
  No runner failures, softlocks, timeouts or invalid player actions in those batches.
- Native renderer replay matches 12 actions/3 turns, and a winning replay matches
  20 actions/5 turns through victory. Captures are under qa/autowalker-*-watch/.
- Run mode plays 76 real actions including routes, battle continuation, rewards and
  a chrono_jab draft, then defeat. All 307 captured QA JSONL events pass the actual
  backend validator with no service running.
- Backend: 7 mocked ingestion tests pass; all five dashboards/provisioning YAML,
  Compose structure and SQL migration features pass static checks. No API server,
  ClickHouse, Grafana, container or external infrastructure was started or deployed.
- Scene resource guard and diff whitespace checks pass. Build version: 0.0.7.0;
  longer balance/replay baselines above were recorded immediately before version bump.

## Limits and later validation (not deferred implementation deliverables)

- Existing Windows certificate, headless shader and intermittent resource-retention
  diagnostics remain. Assertion success is not a claim of clean engine shutdown.
- No complete 15-floor campaign victory, every optional room branch, large statistical
  balance study, release export or renderer benchmark was verified. Run mode can
  exercise supported progression but its shop policy deliberately leaves the shop.
- Greedy is a heuristic baseline, not a full status/combination forecast. Legacy v1
  damage_taken is net health loss; v2 separates health damage, healing and net loss.
  Read the AutoWalker documentation before interpreting
  comparisons or human/bot win rates.
- No physical projectile occluder terrain exists in the current rules; range and legal
  hex traversal are validated rather than inventing wall/cover rules.
- HTTP uses bounded in-memory retries. JSONL is bounded offline collection; an on-disk
  HTTP retry spool is not implemented (optional in the request). Shutdown is bounded,
  best effort. Consent cannot retract an already accepted remote batch.
- Live HTTP/TLS, ClickHouse migration execution/deduplication, Grafana rendered queries,
  container builds and deployment integration must be validated on the later host.
  The backend README contains the exact operator procedure and security/backup guidance.
