class_name TutorialUI
extends CanvasLayer

signal completed

func display_tutorial() -> void:
	_pause()

func _pause() -> void:
	show()
	get_tree().paused = true


func _unpause() -> void:
	hide()
	get_tree().paused = false
	completed.emit()

func _on_button_pressed() -> void:
	_unpause()
	pass # Replace with function body.
