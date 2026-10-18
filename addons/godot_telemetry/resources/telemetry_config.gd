extends Resource

@export var enabled := false
@export var consent_required := true
@export var game_id := ""
@export var environment := "development"
@export_enum("null", "jsonl", "http") var transport := "null"
@export var endpoint := ""
@export var output_path := "user://telemetry.jsonl"
@export_range(1, 1000) var batch_size := 50
@export_range(1, 10000) var queue_capacity := 1000
@export var flush_interval := 5.0
@export var request_timeout := 10.0
@export var max_retries := 5
@export var retry_base_seconds := 2.0
@export var max_file_bytes := 8388608
@export var max_event_bytes := 16384
@export var max_batch_bytes := 1048576
@export_enum("strict", "warn", "off") var validation := "strict"
@export_enum("production", "development", "qa") var profile := "production"
@export var excluded_events: PackedStringArray = []
@export var common_metadata: Dictionary = {}
