extends "res://addons/godot_telemetry/transports/transport.gd"

var endpoint := ""
var timeout_seconds := 10.0
var production := false
var request_node: HTTPRequest

func deliver(batch: Array) -> Dictionary:
	if not endpoint.begins_with("https://") and (production or not endpoint.begins_with("http://")):
		return {"ok": false, "retryable": false, "error": "Invalid endpoint; production requires HTTPS"}
	request_node = HTTPRequest.new()
	add_child(request_node)
	request_node.timeout = timeout_seconds
	request_node.body_size_limit = 65536
	var error := request_node.request(endpoint, ["Content-Type: application/json"], HTTPClient.METHOD_POST, encode(batch))
	if error != OK:
		request_node.queue_free()
		return {"ok": false, "retryable": true, "error": str(error)}
	var response: Array = await request_node.request_completed
	request_node.queue_free()
	return classify(response[0], response[1], response[3], batch.size())

func encode(batch: Array) -> String:
	return JSON.stringify({"events": batch})

func classify(result: int, code: int, body: PackedByteArray, expected: int) -> Dictionary:
	var ack: Variant = JSON.parse_string(body.get_string_from_utf8())
	var accepted: bool = result == HTTPRequest.RESULT_SUCCESS and code == 200 and ack is Dictionary and ack.get("accepted", -1) == expected
	return {"ok": accepted, "retryable": result != HTTPRequest.RESULT_SUCCESS or code == 0 or code == 429 or code >= 500 or (code >= 200 and code < 300 and not accepted), "error": "" if accepted else str(code)}

func purge() -> void:
	if is_instance_valid(request_node):
		request_node.cancel_request()
