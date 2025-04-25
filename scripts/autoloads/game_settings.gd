extends Node

const SETTINGS_PATH = "user://user_settings.ini"

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var settings = ConfigFile.new()
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		return
		
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), settings.get_value("audio", "master_volume"))
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), settings.get_value("audio", "sfx_volume"))
	if settings.get_value("graphics", "fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
