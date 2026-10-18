@tool
extends EditorPlugin

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("telemetry/config_path"):
		ProjectSettings.set_setting("telemetry/config_path", "")
	ProjectSettings.add_property_info({"name": "telemetry/config_path", "type": TYPE_STRING, "hint": PROPERTY_HINT_FILE, "hint_string": "*.tres"})
