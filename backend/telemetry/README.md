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
   and Grafana to loopback only; the internal analytics network has no published DB.
3. Start only ClickHouse first on the deployment host. New volumes apply migrations
   in filename order. Existing volumes need explicit application of new migrations
   through the administrative ClickHouse client; init scripts do not rerun.
4. Using a secured administrative session, create `telemetry_ingest` and
   `grafana_reader` with the corresponding server-side passwords. Grant
   `telemetry_writer` to the former and `telemetry_reader` to the latter. Set the
   reader's `readonly=1` and enforce query time/memory limits. The bootstrap account
   is for migrations only, never the API or dashboard. No credentials belong in
   exported Godot resources. Do not put passwords in shell history.
5. Build/start ingestion and Grafana on that deployment host. Provisioning installs
   the ClickHouse plugin and loads all five dashboards. Check `/health` (liveness,
   not storage readiness), send a known batch, verify acknowledgement and rows in
   `telemetry.events_deduplicated`, then check dashboards and internal `/metrics`.

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
