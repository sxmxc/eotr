extends Node

signal telemetry_changed(enabled: bool)

const SETTINGS_PATH = "user://user_settings.ini"

@export var show_tutorial := true
var telemetry_enabled := false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var data := get_current_settings()
	show_tutorial = data.tutorial_enabled
	telemetry_enabled = data.telemetry_enabled
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), data.master_volume)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), data.sfx_volume)
	if DisplayServer.get_name() != "headless":
		var fullscreen := data.fullscreen and not OS.has_feature("editor")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	telemetry_changed.emit(telemetry_enabled)


func get_current_settings() -> SettingsData:
	var data := SettingsData.new()
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return data
	# Older or partial settings files must use defaults for missing keys.
	data.master_volume = settings.get_value("audio", "master_volume", data.master_volume)
	data.sfx_volume = settings.get_value("audio", "sfx_volume", data.sfx_volume)
	data.fullscreen = settings.get_value("graphics", "fullscreen", data.fullscreen)
	data.resolution = settings.get_value("graphics", "resolution", data.resolution)
	data.telemetry_enabled = settings.get_value("telemetry", "enabled", data.telemetry_enabled)
	data.tutorial_enabled = settings.get_value("gameplay", "tutorials", data.tutorial_enabled)
	return data


func save_settings(data: SettingsData) -> void:
	var settings := ConfigFile.new()
	var err := settings.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Couldn't load settings: %s" % error_string(err))
		return
	settings.set_value("graphics", "fullscreen", data.fullscreen)
	settings.set_value("graphics", "resolution", data.resolution)
	settings.set_value("audio", "master_volume", data.master_volume)
	settings.set_value("audio", "sfx_volume", data.sfx_volume)
	settings.set_value("telemetry", "enabled", data.telemetry_enabled)
	settings.set_value("gameplay", "tutorials", data.tutorial_enabled)
	err = settings.save(SETTINGS_PATH)
	if err != OK:
		push_error("Couldn't save settings: %s" % error_string(err))
		return
	load_settings()
