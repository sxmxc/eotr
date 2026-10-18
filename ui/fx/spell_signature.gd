extends VisualFX

@export var duration := 0.55
@export var grounded := false
var playback: Tween

func execute() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free.call_deferred()
		return
	var owner_node := get_parent()
	if grounded:
		position = Vector2.ZERO
	elif owner_node is Node2D and owner_node.has_node("ImpactAnchor"):
		position = owner_node.get_node("ImpactAnchor").position
	var surface := $Surface as Sprite2D
	surface.material = surface.material.duplicate()
	if playback and playback.is_valid():
		playback.kill()
	playback = create_tween()
	playback.tween_method(func(value: float): surface.material.set_shader_parameter("progress", value), 0.0, 1.0, duration)
	var illustration := get_node_or_null("Illustration") as AnimatedSprite2D
	if illustration:
		illustration.play(&"default")
		playback.parallel().tween_property(illustration, "modulate:a", 0.0, duration)
	playback.tween_callback(queue_free)
