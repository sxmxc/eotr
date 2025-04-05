extends Control

const CLASS_SELECTOR_SCENE = preload("res://scenes/menus/class_selector.tscn")

@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	get_tree().paused = false
	
func _on_continue_button_pressed() -> void:
	pass # Replace with function body.


func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_packed(CLASS_SELECTOR_SCENE)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
