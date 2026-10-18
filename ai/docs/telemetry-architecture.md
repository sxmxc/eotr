# Telemetry architecture and operation

The standalone addon lives in `addons/godot_telemetry`; its README describes independent
installation and its API. The game-specific autoload `TelemetryManager` loads the
canonical portable `telemetry/schemas/events.json` and delegates all event/stat delivery
to the addon. No game event name, Talo call or ClickHouse assumption lives in addon code.

`telemetry/config/production.tres` selects local JSONL delivery in the current checkout;
Null is available for collection-free delivery and no HTTP endpoint is configured.
Consent follows the existing
player telemetry setting. To collect locally, duplicate that Resource, choose JSONL,
set a `user://` path and select development/QA profile; set the project setting
`telemetry/config_path` to that Resource. To use a deployed server later, select HTTP,
set the HTTPS endpoint ending `/v1/events`, and retain consent requirements. Resources
are public client configuration and contain no secret. AutoWalker explicitly configures
QA JSONL under its output directory and marks source_type=bot.

Production suppresses diagnostic schemas (enemy actions, detailed simulation actions,
turns and console diagnostics). New lifecycle/combat/simulation events have typed
properties; legacy shop/reward/run payloads retain permissive extra fields for migration
compatibility. Numeric gameplay data now remains numeric where the caller supplies
numbers. Some legacy run/floor properties are still strings; dashboards should use
the new encounter events for balance measures. Do not infer human win rates from QA.

JSON schemas are shared directly with the backend Docker image, not copied by hand.
Export presets include the schema JSON and exclude developer automation/backend tools.
No backend is needed for gameplay or local reports. HTTP is not configured by default.
Delivery reliability, consent purge and offline-persistence limitations are explicit
in the addon README. Backend source, security/deployment/retention/rollback instructions
and deferred integration tests live in `backend/telemetry/README.md`.
