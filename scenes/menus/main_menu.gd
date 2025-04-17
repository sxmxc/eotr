extends Control

const CLASS_SELECTOR_SCENE = preload("res://scenes/menus/class_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")
const CLICK_5 = preload("res://assets/audio/battle_sound_effects/click5.ogg")

@export var run_bootstrap: RunBootstrap

@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	get_tree().paused = false
	continue_button.disabled = SaveGame.load_data() == null


func _on_continue_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	run_bootstrap.type = RunBootstrap.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_new_game_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	get_tree().change_scene_to_packed(CLASS_SELECTOR_SCENE)


func _on_exit_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	get_tree().quit()
	pass  # Replace with function body.
