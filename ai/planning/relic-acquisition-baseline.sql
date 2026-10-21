SELECT environment,source_type,build_version,session_id,run_id,event_id,toString(timestamp) AS time,event_name,properties,metadata
FROM telemetry.events_deduplicated
WHERE game_id='echoes_of_the_rift'
  AND event_name IN ('run_started','run_completed','floor_started','floor_completed','relic_prize_taken','relic_bought_in_shop','treasure_room_exited','simulation_started','simulation_completed','encounter_completed','shop_left_empty_handed','console_command_used')
  AND timestamp <= toDateTime64('2026-10-21 02:03:38',3,'UTC')
  AND ingested_at <= toDateTime64('2026-10-21 02:03:38',3,'UTC')
ORDER BY timestamp,event_id
LIMIT 20000;
