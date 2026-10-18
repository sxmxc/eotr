extends VisualFX

const HIGHLIGHTER_MATERIAL = preload("res://resources/materials/highlighter_material.tres")

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hide()
	color_rect.material = color_rect.material.duplicate()
	animation_player.animation_finished.connect(func(_animation: StringName): queue_free(), CONNECT_ONE_SHOT)
	
func execute() -> void:
	show()
	animation_player.play("shield_grow")
