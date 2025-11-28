extends VisualFX

@export var lifetime := 0.6
@export var target_scale := Vector2(0.9, 0.9)
@export var fade_delay := 0.06


func execute() -> void:
	var base_scale := scale
	scale = base_scale * 0.35
	var final_scale := base_scale * target_scale
	rotation = deg_to_rad(RNG.instance.randf_range(-12.0, 12.0))

	var tween := create_tween()
	tween.tween_property(self, "scale", final_scale, 0.1).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", deg_to_rad(RNG.instance.randf_range(-22.0, 22.0)), 0.14)
	tween.tween_interval(fade_delay)
	tween.tween_property(self, "modulate:a", 0.0, lifetime).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)
