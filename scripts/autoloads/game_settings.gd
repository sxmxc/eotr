extends Node

signal telemetry_changed(enabled: bool)

const SETTINGS_PATH := "user://user_settings.ini"
# Stable IDs: existing saves use zero for 1920×1080.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(2560, 1440)]
const FIELDS: Dictionary = {
	"master_volume": "audio", "sfx_volume": "audio", "music_volume": "audio", "ui_volume": "audio",
	"fullscreen": "graphics", "resolution": "graphics", "vsync_enabled": "graphics",
	"telemetry_enabled": "telemetry", "tutorial_enabled": "gameplay",
}

@export var show_tutorial := true
var telemetry_enabled := false
var music_base_volume := 1.0
var window_resolution_id := -1

func _ready() -> void:
	# Music's authored mix is quieter than effects; the slider scales that mix.
	music_base_volume = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music"))
	load_settings()

func load_settings() -> void:
	var data := get_current_settings()
	show_tutorial = data.tutorial_enabled
	telemetry_enabled = data.telemetry_enabled
	apply_audio(data)
	if not OS.get_cmdline_user_args().has("--validation-local"):
		apply_display(data)
	telemetry_changed.emit(telemetry_enabled)

func apply_audio(data: SettingsData) -> void:
	for bus: String in ["Master", "SFX", "Music", "UI"]:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			var gain: float = data.get(bus.to_lower() + "_volume")
			AudioServer.set_bus_volume_linear(index, gain * music_base_volume if bus == "Music" else gain)

func apply_display(data: SettingsData) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if data.vsync_enabled else DisplayServer.VSYNC_DISABLED)
	var desired_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	var mode_changed := DisplayServer.window_get_mode() != desired_mode
	if mode_changed:
		DisplayServer.window_set_mode(desired_mode)
	if not data.fullscreen and (mode_changed or window_resolution_id != data.resolution):
		var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		var requested := RESOLUTIONS[clampi(data.resolution, 0, RESOLUTIONS.size() - 1)]
		var available := usable.size - Vector2i(32, 64)
		var fit_scale := minf(1.0, minf(float(available.x) / requested.x, float(available.y) / requested.y))
		var fitted := Vector2i(Vector2(requested) * fit_scale)
		DisplayServer.window_set_size(fitted)
		DisplayServer.window_set_position(usable.position + (usable.size - fitted) / 2)
		window_resolution_id = data.resolution

func get_current_settings() -> SettingsData:
	var data := SettingsData.new()
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return data
	for field: String in FIELDS:
		var fallback: Variant = data.get(field)
		var value: Variant = settings.get_value(FIELDS[field], _config_key(field), fallback)
		if field.ends_with("_volume"):
			if (value is float or value is int) and is_finite(float(value)):
				data.set(field, clampf(float(value), 0.0, 1.0))
		elif field == "resolution":
			if value is int and value >= 0 and value < RESOLUTIONS.size():
				data.resolution = value
		elif value is bool:
			data.set(field, value)
	return data

func _config_key(field: String) -> String:
	if field == "telemetry_enabled":
		return "enabled"
	if field == "tutorial_enabled":
		return "tutorials"
	return field

func save_settings(data: SettingsData) -> bool:
	var settings := ConfigFile.new()
	var err := settings.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		return false
	for field: String in FIELDS:
		settings.set_value(FIELDS[field], _config_key(field), data.get(field))
	if settings.save(SETTINGS_PATH) != OK:
		return false
	load_settings()
	return true
