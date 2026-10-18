extends SceneTree

const Client = preload("res://addons/godot_telemetry/core/client.gd")
const Config = preload("res://addons/godot_telemetry/resources/telemetry_config.gd")
var failures := 0

class FakeTransport:
	extends Node
	var result := {"ok": false, "retryable": true}
	func deliver(_batch: Array) -> Dictionary:
		return result
	func purge() -> void:
		pass

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var client := Client.new()
	root.add_child(client)
	var config := Config.new()
	config.enabled = true
	config.transport = "jsonl"
	config.game_id = "standalone-test"
	config.output_path = "res://build/telemetry-unit.jsonl"
	config.queue_capacity = 2
	client.configure(config)
	client.register_schema("test", JSON.parse_string('{"version":1,"required":["value"],"properties":{"value":{"type":"number","minimum":0}}}'))
	check(not client.record("test", {"value": 1}), "Consent required")
	client.set_consent(true)
	check(not client.record("test", {}), "Required field")
	check(not client.record("test", {"value": "bad"}), "Property type")
	check(not client.record("test", {"value": -1}), "Minimum constraint")
	check(not client.record("test", {"value": 1}, 2), "Schema version")
	client.register_schema("oversize", {"version": 1, "additionalProperties": true})
	check(not client.record("oversize", {"value": "x".repeat(20000)}), "Event byte bound")
	check(client.record("test", {"value": 2.5}), "Valid event")
	check(client.record("test", {"value": 3}), "Second event")
	check(not client.record("test", {"value": 4}), "Bounded queue")
	var stable_id: String = client.queue[0].event_id
	client.flush()
	check(client.queue.is_empty(), "JSONL acknowledgement")
	var file := FileAccess.open(config.output_path, FileAccess.READ)
	check(file != null, "JSONL created")
	if file:
		var event: Dictionary = JSON.parse_string(file.get_line())
		check(event.event_id == stable_id and event.properties.value == 2.5, "Stable ID and numeric serialization")
		file.close()
	client.record("test", {"value": 1})
	client.set_consent(false)
	check(client.queue.is_empty() and not FileAccess.file_exists(config.output_path), "Withdrawal purges queue and local output")
	client.set_enabled(false)
	check(not client.record("test", {"value": 1}), "Disabled collection")
	config.enabled = true
	client.set_consent(true)
	client.transport.queue_free()
	var fake := FakeTransport.new()
	client.add_child(fake)
	client.transport = fake
	client.record("test", {"value": 7})
	var retry_id: String = client.queue[0].event_id
	client.flush()
	check(client.queue.size() == 1 and client.retries == 1 and client.queue[0].event_id == retry_id, "Retry retains stable batch and ID")
	check(client.retry_at > Time.get_unix_time_from_system(), "Backoff deadline")
	client.retry_at = 0.0
	fake.result = {"ok": true}
	client.flush()
	check(client.queue.is_empty() and client.retries == 0, "Recovery acknowledges once")
	client.record("test", {"value": 8})
	fake.result = {"ok": false, "retryable": false}
	client.flush()
	check(client.queue.is_empty(), "Permanent failures do not retry forever")
	client.record("test", {"value": 9})
	fake.result = {"ok": true}
	client.shutdown()
	check(client.queue.is_empty() and not config.enabled, "Shutdown drains synchronous delivery and disables collection")
	var http := preload("res://addons/godot_telemetry/transports/http.gd").new()
	root.add_child(http)
	check(JSON.parse_string(http.encode([{"test": 1}])).events.size() == 1, "HTTP batch serialization")
	check(http.classify(0, 200, '{"accepted":1}'.to_utf8_buffer(), 1).ok, "HTTP whole-batch acknowledgement")
	check(http.classify(0, 200, '{"accepted":0}'.to_utf8_buffer(), 1).retryable, "Ambiguous acknowledgement retries")
	check(not http.classify(0, 400, '{}'.to_utf8_buffer(), 1).retryable, "HTTP permanent rejection")
	check(http.classify(0, 429, '{}'.to_utf8_buffer(), 1).retryable, "HTTP rate limiting retries")
	http.queue_free()
	client.queue_free()
	print("Telemetry tests: %d failures" % failures)
	quit(1 if failures else 0)
