extends Control
const MAIN_MENU = "res://scenes/menus/main_menu.tscn"
const SETTINGS_PATH = "user://user_settings.ini"

@onready var save_button: Button = %SaveButton
@onready var cancel_button: Button = %CancelButton
@onready var fullscreen_button: CheckButton = %FullscreenButton
@onready var resolution_button: OptionButton = %OptionButton
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var telemetry_check_box: CheckBox = %TelemetryCheckBox

var save_settings : ConfigFile
var have_values_changed := false

func _ready() -> void:
	load_initial_settings()

func _process(_delta: float) -> void:
	save_button.disabled = !have_values_changed

func load_initial_settings() -> void:
	var settings = ConfigFile.new()
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		return
		
	master_volume_slider.value = settings.get_value("audio", "master_volume")
	sfx_volume_slider.value = settings.get_value("audio", "sfx_volume")
	fullscreen_button.button_pressed = settings.get_value("graphics", "fullscreen")

func _on_save_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	save_settings = ConfigFile.new()
	if !FileAccess.file_exists(SETTINGS_PATH):
		save_settings.save(SETTINGS_PATH)
	
	var err = save_settings.load(SETTINGS_PATH)
	if err != OK:
		return
		
	save_settings.set_value("graphics", "fullscreen", fullscreen_button.button_pressed)
	save_settings.set_value("graphics", "resolution", resolution_button.get_selected_id())
	save_settings.set_value("audio", "master_volume", master_volume_slider.value)
	save_settings.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	save_settings.set_value("telemetry", "enabled", telemetry_check_box.button_pressed)
	
	save_settings.save(SETTINGS_PATH)
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_cancel_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	GameSettings.load_settings()
	get_tree().change_scene_to_file(MAIN_MENU)
	pass # Replace with function body.


func _on_fullscreen_button_toggled(toggled_on: bool) -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	have_values_changed = true
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	pass # Replace with function body.


func _on_option_button_item_selected(_index: int) -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_tick)
	have_values_changed = true
	pass # Replace with function body.


func _on_master_volume_slider_value_changed(value: float) -> void:
	have_values_changed = true
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)
	SoundManager.play_sound(AudioLibrary.ui_tick)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	have_values_changed = true
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value)
	SoundManager.play_sound(AudioLibrary.ui_tick)


func _on_telemetry_check_box_toggled(_toggled_on: bool) -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_tick)
	have_values_changed = true
	pass # Replace with function body.
