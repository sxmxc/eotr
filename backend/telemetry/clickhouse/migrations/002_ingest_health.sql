CREATE TABLE IF NOT EXISTS telemetry.ingest_health
(
    timestamp DateTime64(3, 'UTC'),
    requests UInt64,
    accepted UInt64,
    rejected UInt64,
    storage_failures UInt64,
    rate_limited UInt64
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(timestamp)
ORDER BY timestamp
TTL timestamp + INTERVAL 30 DAY DELETE;

CREATE ROLE IF NOT EXISTS telemetry_writer;
GRANT INSERT ON telemetry.events TO telemetry_writer;
GRANT INSERT ON telemetry.ingest_health TO telemetry_writer;
CREATE ROLE IF NOT EXISTS telemetry_reader;
GRANT SELECT ON telemetry.events_deduplicated TO telemetry_reader;
GRANT SELECT ON telemetry.ingest_health TO telemetry_reader;
