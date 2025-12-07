extends TextureButton

const HOVER_MATERIAL_PATH := "res://resources/materials/blotchy_border.tres"

@onready var hover_material := preload(HOVER_MATERIAL_PATH)


func _on_mouse_exited() -> void:
	material = null
	pass # Replace with function body.

func _on_mouse_entered() -> void:
	material = hover_material
	pass # Replace with function body.
