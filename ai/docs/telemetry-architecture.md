# Telemetry architecture and operation

The standalone addon lives in `addons/godot_telemetry`; its README describes independent
installation and its API. The game-specific autoload `TelemetryManager` loads the
canonical portable `telemetry/schemas/events.json` and delegates all event/stat delivery
to the addon. No game event name, Talo call or ClickHouse assumption lives in addon code.

`telemetry/config/production.tres` currently enables HTTP to the local development
host's `/v1/events` endpoint. Consent follows the existing player telemetry setting.
AutoWalker uses that enabled backend by default and also writes bounded QA JSONL;
`--telemetry-local` explicitly selects offline collection. Regression validation uses
Null/fake transports and never depends on a backend. To change delivery, select a
JSONL/HTTP/Null Resource through `telemetry/config_path`; use HTTPS for an external
production endpoint. Resources contain public client configuration, never secrets.

Production suppresses diagnostic schemas (enemy actions, detailed simulation actions,
turns and console diagnostics). New lifecycle/combat/simulation events have typed
properties; legacy shop/reward/run payloads retain permissive extra fields for migration
compatibility. Numeric gameplay data now remains numeric where the caller supplies
numbers. Some legacy run/floor properties are still strings; dashboards should use
the new encounter events for balance measures. Do not infer human win rates from QA.

The backend submodule bundles its own `schemas/events.json` contract so it can build
without the game checkout. It matches the current game schema; introduce new event
versions in the backend first, then update the game's schema before emitting them.
Export presets include the schema JSON and exclude developer automation/backend tools.
No backend is needed for gameplay or local reports.
Delivery reliability, consent purge and offline-persistence limitations are explicit
in the addon README. Backend source, security/deployment/retention/rollback instructions
and deferred integration tests live in `backend/telemetry/README.md`.

AutoWalker assigns a unique run ID before creating a Run or GameWorld. The run's
`run_started` event keeps that identity; queued events retain their original context.
Session lifecycle events can have an empty run ID. Reports include both session
and run IDs, and comparisons ignore stale reports from another summary session.

`encounter_completed` and `simulation_completed` v2 separate actual post-block
health damage (clamped to remaining HP), effective healing and net health loss.
Simulation turns now count player turns across battles, with final battle turn and
floors reported separately. V1 retains its original semantics for older clients.
Deploy the backend schema update before the new game emits v2; restart/rebuild
ingestion and reprovision Grafana. Combat queries use v2, and simulation queries
separate metric versions/modes. No table migration is required.

Local QA storage is bounded by fresh per-launch JSONL (8 MiB), 32 reports and 64 MiB
of reports per output directory, and a 16 MiB compact trace budget per simulation.
The Python tools also enforce a 14-day/256 MiB generated-artifact retention policy
under `qa/`. AutoWalker checks every five seconds and after shutdown, protects the
active report/log/session/replay input. A log above 8 MiB requests bounded shutdown
and is trimmed after the writer exits; this returns a storage-limit failure. Active files
can temporarily exceed the global target between checks; scratch caches, isolated
saves, links and unrelated files are excluded. The launcher confines output to `qa/`.

See [the user guide](autowalker.md) and [read-only Grafana access](grafana-access.md).

AutoWalker completion events also carry bounded per-event `metadata`: stop reason
and reason code, encounter and policy identity, action counts and configured limits,
final health, last action, and warning/validation counts. These diagnostic fields
use the existing envelope metadata contract (4096-byte maximum), preserving v2
gameplay metric semantics and compatibility with the deployed ingestion schema.
The QA dashboard includes an abort/technical-failure table reading these fields;
provision its updated JSON to expose that table. Historical events without metadata
remain queryable, with the reason displayed as `legacy_unknown`.
`--telemetry-upload` explicitly opts disposable QA saves into uploads for one launch;
otherwise the existing player consent setting applies. `--all-encounters` runs a
separate session/output subfolder per encounter, using the same seed range.
