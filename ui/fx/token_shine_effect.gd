extends VisualFX

const HIGHLIGHTER_MATERIAL = preload("res://resources/materials/highlighter_material.tres")

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.material.set_shader_parameter("speed", 0.0)
	hide()
	
func execute() -> void:
	show()
	var tween = create_tween()
	tween.tween_method(set_shader_position, 0.0, 1.0, .5)
	tween.tween_callback(hide)

func set_shader_position(value: float) -> void:
	color_rect.material.set_shader_parameter("Position", value)
