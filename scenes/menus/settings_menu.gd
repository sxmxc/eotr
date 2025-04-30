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
@onready var tutorial_checkbox: CheckBox = %TutorialCheckbox

var save_settings : ConfigFile
var have_values_changed := false

func _ready() -> void:
	load_initial_settings()

func _process(_delta: float) -> void:
	save_button.disabled = !have_values_changed

func load_initial_settings() -> void:
	var settings : SettingsData = GameSettings.get_current_settings()
		
	master_volume_slider.value = settings.master_volume
	sfx_volume_slider.value = settings.sfx_volume
	resolution_button.select(settings.resolution)
	fullscreen_button.button_pressed = settings.fullscreen
	telemetry_check_box.button_pressed = settings.telemetry_enabled
	tutorial_checkbox.button_pressed = settings.tutorial_enabled

func _on_save_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	var settings_data = SettingsData.new()
	settings_data.fullscreen = fullscreen_button.button_pressed
	settings_data.resolution = resolution_button.get_selected_id()
	settings_data.master_volume = master_volume_slider.value
	settings_data.sfx_volume = sfx_volume_slider.value
	settings_data.telemetry_enabled = telemetry_check_box.button_pressed
	settings_data.tutorial_enabled = tutorial_checkbox.button_pressed
	GameSettings.save_settings(settings_data)
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


func _on_tutorial_checkbox_toggled(_toggled_on: bool) -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_tick)
	have_values_changed = true
	pass # Replace with function body.
