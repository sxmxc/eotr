extends VisualFX

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func execute() -> void:
	animated_sprite_2d.play("default")
	animated_sprite_2d.animation_finished.connect(queue_free)
