extends VisualFX

const HIGHLIGHTER_MATERIAL = preload("res://resources/materials/highlighter_material.tres")

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hide()
	
func execute() -> void:
	show()
	animation_player.play("shield_grow")
