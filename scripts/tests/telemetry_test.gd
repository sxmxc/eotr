extends SceneTree

const Client = preload("res://addons/godot_telemetry/core/client.gd")
const Config = preload("res://addons/godot_telemetry/resources/telemetry_config.gd")
var failures := 0

class FakeTransport:
	extends Node
	var result := {"ok": false, "retryable": true}
	var batches: Array = []
	func deliver(batch: Array) -> Dictionary:
		batches.append(batch.duplicate(true))
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
	config.output_path = "user://telemetry-unit.jsonl"
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
	config.common_metadata = {"origin": "test"}
	var details := {"reason_code": "turn_limit", "limits": {"turns": 50}}
	check(client.record("test", {"value": 2.5}, 1, details), "Valid event with metadata")
	details.limits.turns = 100
	check(client.queue[0].metadata.origin == "test" and client.queue[0].metadata.limits.turns == 50, "Per-event metadata merged and copied")
	check(not client.record("test", {"value": 1}, 1, {"oversize": "x".repeat(4097)}), "Backend metadata byte bound")
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
		check(event.metadata.reason_code == "turn_limit", "Diagnostic metadata survives serialization")
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
	for response_body: String in ["", "<html>Bad gateway</html>", "not json"]:
		var malformed: Dictionary = http.classify(HTTPRequest.RESULT_SUCCESS, 200, response_body.to_utf8_buffer(), 1)
		check(not malformed.ok and malformed.retryable and malformed.error == "Invalid JSON acknowledgement (HTTP 200)", "Malformed success acknowledgement is handled without parser errors")
	for response_body: String in ["null", "[]", '{"accepted":0}']:
		var invalid: Dictionary = http.classify(HTTPRequest.RESULT_SUCCESS, 200, response_body.to_utf8_buffer(), 1)
		check(not invalid.ok and invalid.retryable, "Invalid acknowledgement shape/count retries")
	var unavailable: Dictionary = http.classify(HTTPRequest.RESULT_SUCCESS, 503, "<html>Unavailable</html>".to_utf8_buffer(), 1)
	check(not unavailable.ok and unavailable.retryable and unavailable.error == "HTTP status 503", "HTML server error reports status and retries")
	var missing: Dictionary = http.classify(HTTPRequest.RESULT_SUCCESS, 404, "Not found".to_utf8_buffer(), 1)
	check(not missing.ok and not missing.retryable and missing.error == "HTTP status 404", "Plain-text client rejection remains permanent")
	var disconnected: Dictionary = http.classify(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray(), 1)
	check(not disconnected.ok and disconnected.retryable and disconnected.error.contains("transport failure"), "Connection failures skip parsing and retry")
	http.queue_free()
	client.queue_free()
	test_minimum_batch_boundary()
	print("Telemetry tests: %d failures" % failures)
	quit(1 if failures else 0)

func test_minimum_batch_boundary() -> void:
	var client := Client.new()
	root.add_child(client)
	var config := Config.new()
	config.enabled = true
	config.consent_required = false
	config.max_event_bytes = 512
	config.max_batch_bytes = 0
	client.configure(config)
	check(config.max_batch_bytes == config.max_event_bytes + 32, "Batch byte limit clamps to minimum allowance")
	client.register_schema("boundary", {"version": 1, "properties": {"value": {"type": "string"}}})
	check(client.record("boundary", {"value": ""}), "Boundary fixture fits event limit")
	if client.queue.is_empty():
		client.queue_free()
		return
	var padding := config.max_event_bytes - JSON.stringify(client.queue[0]).to_utf8_buffer().size()
	client.queue.clear()
	var props := {"value": "x".repeat(padding)}
	check(client.record("boundary", props), "Accept exactly maximum-size event")
	check(client.record("boundary", props), "Accept a following maximum-size event")
	check(not client.record("boundary", {"value": "x".repeat(padding + 1)}), "Reject an event one byte over the limit")
	if client.queue.size() != 2:
		client.queue_free()
		return
	check(JSON.stringify(client.queue[0]).to_utf8_buffer().size() == config.max_event_bytes, "Fixture reaches exact serialized byte boundary")
	var first_id: String = client.queue[0].event_id
	var second_id: String = client.queue[1].event_id
	client.transport.queue_free()
	var fake := FakeTransport.new()
	fake.result = {"ok": true}
	client.add_child(fake)
	client.transport = fake
	client.flush()
	check(fake.batches.size() == 1 and fake.batches[0].size() == 1, "Minimum-size batch delivers one maximum-size event")
	check(client.queue.size() == 1 and client.queue[0].event_id == second_id, "Acknowledgement advances past the maximum-size head event")
	client.flush()
	check(client.queue.is_empty() and client.diagnostics.delivered == 2, "Following event drains on the next flush")
	if fake.batches.size() == 2 and fake.batches[0].size() == 1 and fake.batches[1].size() == 1:
		check(fake.batches[0][0].event_id == first_id and fake.batches[1][0].event_id == second_id, "Boundary-sized batches preserve FIFO delivery")
	client.queue_free()
