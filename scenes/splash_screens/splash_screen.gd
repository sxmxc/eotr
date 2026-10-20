extends Control

const MAIN_MENU = preload("res://scenes/menus/main_menu.tscn")
const CASTLE_LOOP = preload("res://assets/audio/music/castle_loop.wav")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var accept_button: Button = %AcceptButton
@onready var decline_button: Button = %DeclineButton
var choice_made := false

func _ready() -> void:
	SoundManager.play_music(CASTLE_LOOP, 2)
	accept_button.disabled = true
	decline_button.disabled = true
	show_disclaimer()

func _on_accept_button_pressed() -> void:
	_choose_telemetry(true)

func _on_decline_button_pressed() -> void:
	_choose_telemetry(false)

func _choose_telemetry(enabled: bool) -> void:
	if choice_made:
		return
	choice_made = true
	accept_button.disabled = true
	decline_button.disabled = true
	var settings := GameSettings.get_current_settings()
	settings.telemetry_enabled = enabled
	GameSettings.save_settings(settings)
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	animation_player.play("fade_telemetry_out")
	await animation_player.animation_finished
	_continue_to_menu()

func _continue_to_menu() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU)

func show_disclaimer() -> void:
	animation_player.play("fade_splash_out")
	await animation_player.animation_finished
	$Splash.hide()
	accept_button.disabled = false
	decline_button.disabled = false
	decline_button.grab_focus()
