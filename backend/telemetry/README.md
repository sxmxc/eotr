# Telemetry backend (source package; not deployed)

Nothing in this initiative starts the API, ClickHouse, Grafana or containers.
The commands below describe later deployment by the infrastructure operator.

## Package and validate without services

Ship `backend/telemetry` together with `telemetry/schemas/events.json` at its existing
repository-relative path. Docker builds use the repository root as context; only the
ingest service and portable schemas are copied into the image. The Godot addon and
game source are not runtime dependencies of the server.

Run `python -m unittest discover -s backend/telemetry/ingest -p test_service.py -v`
and `python backend/telemetry/validate_artifacts.py`. Tests call pure handlers with
mocked storage; they do not open a socket. Compose configuration can be inspected
with `docker compose --env-file .env -f compose.yaml config` later; configuration
validation does not start services. SQL is reviewed statically, not executed here.

## Later deployment

1. Review/pin image versions and the ClickHouse Grafana plugin to tested digests.
   Copy `.env.example` to `.env` outside source control and set all four independent
   passwords. Prefer the deployment platform's secret store over a plaintext file.
2. Bind a TLS reverse proxy to the public hostname. Publish only `POST /v1/events`;
   enforce 1 MiB bodies, 10-second request deadlines, connection/concurrency limits,
   origin policy for web exports and global/per-client rate limits. Keep Grafana
   behind authenticated HTTPS. Never publish ClickHouse ports. Compose binds API
   and Grafana on host ports 8080 and 3000; restrict access using the host firewall
   or bind them to loopback when using a local reverse proxy. The database has no
   published ports.
3. Start only ClickHouse first on the deployment host. New volumes apply migrations
   in filename order. Existing volumes need explicit application of new migrations
   through the administrative ClickHouse client; init scripts do not rerun.
4. ClickHouse loads `clickhouse/users.d/telemetry.xml` on every startup, including
   existing volumes. This creates `telemetry_ingest` with INSERT grants and
   `grafana_reader` with SELECT grants using the same `.env` passwords supplied to
   ingestion and Grafana. The reader uses `readonly=1`, a 1 GB query memory limit,
   and a default 30-second timeout; the plugin may adjust it within 1–60 seconds.
   Accounts do not depend on first-run SQL initialization. The bootstrap account
   is for migrations only. No server credentials belong in exported Godot resources.
5. Build/start ingestion and Grafana on that deployment host. Provisioning installs
   the ClickHouse plugin and loads all five dashboards. Check `/health` (liveness,
   not storage readiness), send a known batch, verify acknowledgement and rows in
   `telemetry.events_deduplicated`, then check dashboards and internal `/metrics`.

## Repair Grafana authentication on an existing installation

An HTTP 403 / ClickHouse code 516 for `grafana_reader` means ClickHouse rejected
the datasource login. Earlier packages required manual creation of this account;
setting `.env` alone did not create it. The ingestion account had the same gap.
After pulling this update, run from `backend/telemetry` on your Docker host:

```sh
docker compose up -d --build --force-recreate clickhouse ingest grafana
```

This recreates the containers with the account configuration and current `.env`
passwords, retaining both named data volumes. Do not delete volumes to fix login.
Keep `CLICKHOUSE_READ_PASSWORD` identical for ClickHouse and Grafana; use single
quotes around `.env` passwords containing `$` to prevent Compose interpolation.
The datasource also uses Grafana's `$VAR` syntax to avoid double expansion.
If you previously created SQL-managed accounts with these same names, remove or
rename those accounts through an administrative session before using the
configuration-managed accounts; do not keep duplicate account definitions.

Open `http://docker01.voidmoose.local:3000`, then Connections → Data sources →
Telemetry ClickHouse → Save & test. Dashboards can show **No data** until matching
events arrive, but authentication errors should disappear. Send gameplay events
to `http://docker01.voidmoose.local:8080/v1/events`; `/health` only checks API
liveness. AutoWalker records local JSONL by default and does not upload its runs.

References: [ClickHouse user configuration](https://github.com/ClickHouse/ClickHouse/blob/master/programs/server/users.xml),
[Grafana reader permissions](https://grafana.com/docs/plugins/grafana-clickhouse-datasource/latest/configure/),
[Grafana password substitution](https://grafana.com/docs/grafana/latest/administration/provisioning/#use-of-the-special-character-).

## Contract, deduplication and limits

`POST /v1/events`, JSON `{ "events": [envelope, ...] }`, 1–100 events, at most 1 MiB
per request and 16 KiB per event. The canonical schema file is shared with the game.
Unknown names/versions/games and malformed envelopes reject the **whole batch** with
400. Non-JSON/unsupported transfer framing gets 415; oversized bodies get 413.
429 and 503 are retryable; acknowledgement 200 contains `accepted` equal to the
submitted count. Delivery acknowledges only after ClickHouse's synchronous insert.
The API does not claim exactly-once delivery or transactional uniqueness.

Stable client IDs deduplicate identical retries. Within-batch duplicates collapse;
ReplacingMergeTree removes repeated `(game_id,event_id)` keys eventually. Every
dashboard reads the `events_deduplicated` FINAL view for immediate query semantics.
Retries must preserve envelope IDs and timestamps. Timestamp validation accepts seven
days in either direction; offline events older than this are permanently rejected.
The event table retains 90 days; ingestion health retains 30. Keep health snapshots
as cumulative per-process counters: use increases with reset handling, not sums.
No insert-triggered aggregate views are used because they would count retries twice.

The bounded in-memory limiter allows 120 requests/address/minute. Behind a proxy it
sees the proxy address: configure proxy-side per-client limits; this service ignores
untrusted forwarded headers. The reverse proxy must bound concurrent connections
and hide `/metrics`. Metrics contain no client addresses; app logs omit IPs.

Public clients can forge IDs, build labels, human/bot labels and payloads. Game IDs
are allowlists, not authentication. Validate distributions and gate suspicious
traffic at the proxy; never use this dataset for payments, competitive authority or
security decisions. Legacy migration schemas allow extra fields; tighten/version
them before enabling high-volume public ingestion. New critical events have typed
properties. Client consent deletion purges local queues/files; remote erasure needs
an operator-managed deletion workflow and a supplied session ID, not host identity.

## Dashboards and operational validation later

Gameplay Overview, Combat Balance, Enemy AI, AutoWalker QA and Telemetry Health have
game/environment/build/source/time filters. Human/bot defaults are explicit and may
be changed only deliberately. Missing production events produce empty panels rather
than fake data. API health snapshots are operational server totals (not game-filtered).

Later integration procedure: post valid/invalid batches, retry the same batch twice,
verify FINAL counts once, disconnect storage and verify 503/backoff with stable IDs,
exercise rate/body limits and schema mismatch, test HTTPS from a Godot export, and
inspect all five provisioned dashboards. None of these service-level integration
checks was performed during authoring.

## Backup, upgrades and rollback

Back up the ClickHouse data volume with a consistent ClickHouse BACKUP/snapshot
procedure to separate encrypted storage; save schema migrations, users/grants and
Grafana volume/provisioning. Test a restore before release. TTL is eventual physical
cleanup, not a precise deletion SLA. Watch disk usage and set host volume quotas.
Back up before upgrades, apply versioned additive migrations, deploy the API/schema
pair together, then update dashboards. Keep the previous image/schema package.
Rollback application images first; do not reverse/drop populated tables casually.
Restore into a separate volume for incompatible storage changes. Pin infrastructure
versions after the later integration test and review security updates regularly.

Design references: [ClickHouse FINAL and deduplication](https://clickhouse.com/resources/engineering/clickhouse-optimize-table-final),
[Grafana ClickHouse configuration](https://grafana.com/docs/plugins/grafana-clickhouse-datasource/latest/configure/),
[Grafana provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/).
