class_name TileSprite
extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(func(_arg): queue_free())
	animation_player.play("swirl_out")
