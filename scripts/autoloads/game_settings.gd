extends Node

const SETTINGS_PATH = "user://user_settings.ini"

@export var show_tutorial := true

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var settings = ConfigFile.new()
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		return
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), settings.get_value("audio", "master_volume"))
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), settings.get_value("audio", "sfx_volume"))
	if settings.has_section("gameplay"):
		show_tutorial = settings.get_value("gameplay","tutorials")
	if settings.get_value("graphics", "fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func get_current_settings() -> SettingsData:
	var data = SettingsData.new()
	var settings = ConfigFile.new()
	if !FileAccess.file_exists(SETTINGS_PATH):
		settings.save(SETTINGS_PATH)
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		return null
	
	if settings.has_section("audio"):
		data.master_volume = settings.get_value("audio", "master_volume")
		data.sfx_volume = settings.get_value("audio", "sfx_volume")
	if settings.has_section("graphics"):
		data.fullscreen = settings.get_value("graphics", "fullscreen")
		data.resolution = settings.get_value("graphics", "resolution")
	if settings.has_section("telemetry"):
		data.telemetry_enabled = settings.get_value("telemetry", "enabled")
	if settings.has_section("gameplay"):
		data.tutorial_enabled = settings.get_value("gameplay","tutorials")
	
	return data

func save_settings(data: SettingsData) -> void:
	show_tutorial = data.tutorial_enabled
	var	save_setting = ConfigFile.new()
	if !FileAccess.file_exists(SETTINGS_PATH):
		save_setting.save(SETTINGS_PATH)
	
	var err = save_setting.load(SETTINGS_PATH)
	if err != OK:
		return
		
	save_setting.set_value("graphics", "fullscreen", data.fullscreen)
	save_setting.set_value("graphics", "resolution", data.resolution)
	save_setting.set_value("audio", "master_volume", data.master_volume)
	save_setting.set_value("audio", "sfx_volume", data.sfx_volume)
	save_setting.set_value("telemetry", "enabled", data.telemetry_enabled)
	save_setting.set_value("gameplay", "tutorials", data.tutorial_enabled)
	
	save_setting.save(SETTINGS_PATH)
