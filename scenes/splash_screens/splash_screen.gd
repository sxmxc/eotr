extends Control

const MAIN_MENU = preload("res://scenes/menus/main_menu.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var accept_button: Button = %AcceptButton
@onready var decline_button: Button = %DeclineButton

func _ready() -> void:
	accept_button.hide()
	decline_button.hide()
	show_disclaimer()
	

func _on_accept_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	animation_player.play("fade_telemetry_out")
	await animation_player.animation_finished
	get_tree().change_scene_to_packed(MAIN_MENU)
	pass # Replace with function body.


func _on_decline_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	get_tree().quit()

func show_disclaimer() -> void:
	animation_player.play("fade_splash_out")
	await animation_player.animation_finished
	get_tree().create_timer(2).timeout.connect(
		func():
			accept_button.show()
			decline_button.show()
			)
