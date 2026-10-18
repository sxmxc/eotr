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
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "retryable": true, "error": "HTTP transport failure (result %d, status %d)" % [result, code]}
	if code != 200:
		return {"ok": false, "retryable": code == 0 or code == 429 or code >= 500 or (code >= 200 and code < 300), "error": "HTTP status %d" % code}
	var parser := JSON.new()
	if parser.parse(body.get_string_from_utf8()) != OK:
		return {"ok": false, "retryable": true, "error": "Invalid JSON acknowledgement (HTTP 200)"}
	var ack: Variant = parser.data
	var accepted: bool = ack is Dictionary and ack.get("accepted", -1) == expected
	return {"ok": accepted, "retryable": not accepted, "error": "" if accepted else "Invalid batch acknowledgement (HTTP 200)"}

func purge() -> void:
	if is_instance_valid(request_node):
		request_node.cancel_request()
