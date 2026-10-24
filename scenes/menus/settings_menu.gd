extends Control

signal closed

const MAIN_MENU := "res://scenes/menus/main_menu.tscn"
var embedded := false
var saved: SettingsData
var applied := false

@onready var save_button: Button = %SaveButton
@onready var cancel_button: Button = %CancelButton
@onready var fullscreen_button: CheckButton = %FullscreenButton
@onready var resolution_button: OptionButton = %OptionButton
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var telemetry_check_box: CheckBox = %TelemetryCheckBox
@onready var tutorial_checkbox: CheckBox = %TutorialCheckbox

func _ready() -> void:
	saved = GameSettings.get_current_settings()
	for index: int in GameSettings.RESOLUTIONS.size():
		var resolution: Vector2i = GameSettings.RESOLUTIONS[index]
		resolution_button.add_item("%d × %d" % [resolution.x, resolution.y], index)
	for key: String in ["Master", "SFX", "Music", "UI"]:
		(get_node("%" + key + "VolumeSlider") as HSlider).value_changed.connect(_volume_changed)
	fullscreen_button.toggled.connect(_option_changed)
	resolution_button.item_selected.connect(_option_changed)
	%VSyncButton.toggled.connect(_option_changed)
	telemetry_check_box.toggled.connect(_option_changed)
	tutorial_checkbox.toggled.connect(_option_changed)
	save_button.pressed.connect(_on_save_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	%DefaultsButton.pressed.connect(func(): _populate(SettingsData.new()); _changed())
	_populate(saved)
	fullscreen_button.grab_focus()

func _populate(data: SettingsData) -> void:
	for key: String in ["Master", "SFX", "Music", "UI"]:
		(get_node("%" + key + "VolumeSlider") as HSlider).set_value_no_signal(data.get(key.to_lower() + "_volume"))
	resolution_button.select(data.resolution)
	fullscreen_button.set_pressed_no_signal(data.fullscreen)
	%VSyncButton.set_pressed_no_signal(data.vsync_enabled)
	telemetry_check_box.set_pressed_no_signal(data.telemetry_enabled)
	tutorial_checkbox.set_pressed_no_signal(data.tutorial_enabled)
	_update_labels()
	save_button.disabled = true

func _read_controls() -> SettingsData:
	var data := SettingsData.new()
	data.fullscreen = fullscreen_button.button_pressed
	data.resolution = resolution_button.get_selected_id()
	data.vsync_enabled = %VSyncButton.button_pressed
	for key: String in ["Master", "SFX", "Music", "UI"]:
		data.set(key.to_lower() + "_volume", (get_node("%" + key + "VolumeSlider") as HSlider).value)
	data.telemetry_enabled = telemetry_check_box.button_pressed
	data.tutorial_enabled = tutorial_checkbox.button_pressed
	return data

func _update_labels() -> void:
	for key: String in ["Master", "SFX", "Music", "UI"]:
		(get_node("%" + key + "Value") as Label).text = "%d%%" % roundi((get_node("%" + key + "VolumeSlider") as HSlider).value * 100.0)
	resolution_button.disabled = fullscreen_button.button_pressed
	%ResolutionHint.text = "Fullscreen uses your display's native resolution." if fullscreen_button.button_pressed else "Window size is fitted to your display."

func _changed() -> void:
	_update_labels()
	var data := _read_controls()
	save_button.disabled = true
	for field: String in GameSettings.FIELDS:
		if data.get(field) != saved.get(field):
			save_button.disabled = false
	GameSettings.apply_audio(data)
	%SaveError.hide()

func _volume_changed(_value: float) -> void:
	_changed()
	SoundManager.play_ui_sound(AudioLibrary.ui_tick)

func _option_changed(_value: Variant) -> void:
	_changed()
	SoundManager.play_ui_sound_random_pitch(AudioLibrary.ui_tick)

func _on_save_button_pressed() -> void:
	SoundManager.play_ui_sound_random_pitch(AudioLibrary.ui_click)
	if not GameSettings.save_settings(_read_controls()):
		%SaveError.show()
		return
	applied = true
	_close()

func _on_cancel_button_pressed() -> void:
	SoundManager.play_ui_sound_random_pitch(AudioLibrary.ui_click)
	GameSettings.apply_audio(saved)
	_close()

func _close() -> void:
	if embedded:
		closed.emit()
		queue_free()
	else:
		get_tree().change_scene_to_file(MAIN_MENU)

func _exit_tree() -> void:
	if saved and not applied:
		GameSettings.apply_audio(saved)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_on_cancel_button_pressed()
