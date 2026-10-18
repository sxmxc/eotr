extends Node

const Config = preload("res://addons/godot_telemetry/resources/telemetry_config.gd")
const Schema = preload("res://addons/godot_telemetry/core/schema.gd")
var config = Config.new()
var consent := false
var schemas: Dictionary = {}
var context: Dictionary = {"run_id": "", "source_type": "human", "build_version": "unknown"}
var session_id := ""
var queue: Array = []
var diagnostics := {"recorded": 0, "dropped": 0, "rejected": 0, "delivered": 0, "last_error": ""}
var transport: Node
var busy := false
var elapsed := 0.0
var retries := 0
var retry_at := 0.0
var generation := 0

func configure(settings: Resource) -> void:
	generation += 1
	queue.clear()
	if is_instance_valid(transport):
		transport.purge()
		transport.queue_free()
	config = settings
	config.queue_capacity = clampi(config.queue_capacity, 1, 10000)
	config.batch_size = clampi(config.batch_size, 1, mini(config.queue_capacity, 100))
	config.flush_interval = maxf(0.1, config.flush_interval)
	config.request_timeout = clampf(config.request_timeout, 0.1, 60.0)
	var script_path := "res://addons/godot_telemetry/transports/transport.gd"
	if config.transport != "null":
		script_path = "res://addons/godot_telemetry/transports/%s.gd" % config.transport
	transport = load(script_path).new()
	if config.transport == "jsonl":
		transport.path = config.output_path
		transport.max_bytes = config.max_file_bytes
	elif config.transport == "http":
		transport.endpoint = config.endpoint
		transport.timeout_seconds = config.request_timeout
		transport.production = config.environment == "production"
	add_child(transport)
	session_id = new_id()
	busy = false
	retries = 0
	retry_at = 0.0

func new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

func register_schema(name: String, definition: Dictionary) -> void:
	schemas[name + ":" + str(definition.get("version", 1))] = definition

func set_context(values: Dictionary) -> void:
	context.merge(values, true)

func set_enabled(value: bool) -> void:
	config.enabled = value
	if not value:
		set_consent(false)

func set_consent(value: bool) -> void:
	consent = value
	if not value:
		generation += 1
		queue.clear()
		if is_instance_valid(transport):
			transport.purge()
		busy = false

func record(name: String, properties: Dictionary = {}, version: int = 1) -> bool:
	if not config.enabled or (config.consent_required and not consent) or name in config.excluded_events:
		return false
	var schema: Dictionary = schemas.get(name + ":" + str(version), {})
	if config.profile == "production" and schema.get("diagnostic", false):
		return false
	var errors: Array = Schema.errors(properties, schema) if not schema.is_empty() else ["Unregistered schema: " + name]
	if config.validation != "off" and not errors.is_empty():
		diagnostics.last_error = "; ".join(errors)
		if config.validation == "strict":
			diagnostics.rejected += 1
			return false
	if queue.size() >= config.queue_capacity:
		diagnostics.dropped += 1
		return false
	queue.append({"event_id": new_id(), "event_name": name, "schema_version": version,
		"timestamp": Time.get_datetime_string_from_system(true) + "Z", "game_id": config.game_id,
		"environment": config.environment, "build_version": context.get("build_version", "unknown"),
		"session_id": session_id, "run_id": context.get("run_id", ""), "source_type": context.get("source_type", "human"),
		"metadata": config.common_metadata.duplicate(true), "properties": properties.duplicate(true)})
	diagnostics.recorded += 1
	return true

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= config.flush_interval or queue.size() >= config.batch_size:
		flush()

func flush() -> void:
	if busy or queue.is_empty() or not is_instance_valid(transport) or Time.get_unix_time_from_system() < retry_at:
		return
	busy = true
	elapsed = 0.0
	var epoch := generation
	var batch := queue.slice(0, config.batch_size)
	var result: Dictionary = await transport.deliver(batch)
	if epoch != generation:
		return
	busy = false
	if result.get("ok", false) or not result.get("retryable", false) or retries >= config.max_retries:
		for _i in batch.size():
			queue.pop_front()
		if result.get("ok", false):
			diagnostics.delivered += batch.size()
		else:
			diagnostics.dropped += batch.size()
		retries = 0
		retry_at = 0.0
	else:
		retries += 1
		retry_at = Time.get_unix_time_from_system() + minf(60.0, config.retry_base_seconds * pow(2, retries - 1))
	diagnostics.last_error = result.get("error", "")

func health() -> Dictionary:
	var result := diagnostics.duplicate()
	result.merge({"queued": queue.size(), "busy": busy, "retries": retries})
	return result

func shutdown() -> void:
	config.enabled = false
	flush() # Best effort; callers may await busy with a bounded deadline before quitting.
