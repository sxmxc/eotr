class_name PauseMenu
extends CanvasLayer

signal save_and_quit
signal abandon_run
var confirming_abandon := false

@onready var back_to_game_button: Button = %BackToGameButton
@onready var save_and_quit_button: Button = %SaveAndQuitButton
var previous_focus: WeakRef


func _ready() -> void:
	back_to_game_button.pressed.connect(_unpause)
	save_and_quit_button.pressed.connect(_on_save_and_quit_button_pressed)
	%AbandonButton.pressed.connect(_abandon)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			_unpause()
		else:
			_pause()

		get_viewport().set_input_as_handled()


func _pause() -> void:
	confirming_abandon = false
	%AbandonButton.text = "Abandon expedition"
	var focused := get_viewport().gui_get_focus_owner()
	previous_focus = weakref(focused) if focused else null
	show()
	get_tree().paused = true
	back_to_game_button.grab_focus()
	$AnimationPlayer.play("open")


func _unpause() -> void:
	hide()
	get_tree().paused = false
	var focused := previous_focus.get_ref() as Control if previous_focus else null
	if is_instance_valid(focused) and focused.is_visible_in_tree():
		focused.grab_focus()


func _on_save_and_quit_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	get_tree().paused = false
	save_and_quit.emit()

func _abandon() -> void:
	if not confirming_abandon:
		confirming_abandon = true
		%AbandonButton.text = "Confirm abandonment - lose this run"
		return
	abandon_run.emit()
