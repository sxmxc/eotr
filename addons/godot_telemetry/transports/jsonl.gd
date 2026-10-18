extends "res://addons/godot_telemetry/transports/transport.gd"

var path := "user://telemetry.jsonl"
var max_bytes := 8388608

func deliver(batch: Array) -> Dictionary:
	var payload := ""
	for event in batch:
		payload += JSON.stringify(event) + "\n"
	if payload.to_utf8_buffer().size() > max_bytes:
		return {"ok": false, "retryable": false, "error": "Batch exceeds file capacity"}
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE_READ)
	if not file:
		return {"ok": false, "retryable": true, "error": "Cannot open JSONL"}
	if file.get_length() + payload.to_utf8_buffer().size() > max_bytes:
		file.close()
		file = FileAccess.open(path, FileAccess.WRITE_READ)
	if not file:
		return {"ok": false, "retryable": true, "error": "Cannot rotate JSONL"}
	file.seek_end()
	file.store_string(payload)
	file.flush()
	return {"ok": file.get_error() == OK, "retryable": true}

func purge() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
