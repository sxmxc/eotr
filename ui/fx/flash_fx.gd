extends VisualFX

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func execute() -> void:
	var cam = get_tree().get_first_node_in_group("map_camera")
	Shaker.shake(cam,20)
	animated_sprite_2d.play("default")
	animated_sprite_2d.animation_finished.connect(queue_free)
