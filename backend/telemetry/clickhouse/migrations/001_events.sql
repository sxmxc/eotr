CREATE DATABASE IF NOT EXISTS telemetry;
CREATE TABLE IF NOT EXISTS telemetry.events
(
    event_id FixedString(32),
    event_name LowCardinality(String),
    schema_version UInt16,
    timestamp DateTime64(3, 'UTC'),
    ingested_at DateTime64(3, 'UTC') DEFAULT now64(3),
    game_id LowCardinality(String),
    environment LowCardinality(String),
    build_version LowCardinality(String),
    session_id String,
    run_id String,
    source_type LowCardinality(String),
    metadata String,
    properties String
)
ENGINE = ReplacingMergeTree(ingested_at)
PARTITION BY toYYYYMM(timestamp)
ORDER BY (game_id, event_id)
TTL timestamp + INTERVAL 90 DAY DELETE;

-- Every report must read this view, never raw events. Merges alone are eventual.
CREATE VIEW IF NOT EXISTS telemetry.events_deduplicated AS
SELECT * FROM telemetry.events FINAL;
