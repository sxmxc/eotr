class_name TileSprite
extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(func(_arg): queue_free())
	pass

func swirl_out() -> void:
	animation_player.play("swirl_out")
	
func grow_out() -> void:
	animation_player.play("grow_out")
