extends VisualFX

@export var duration := 0.55
@export var grounded := false
var playback: Tween
var surface: Sprite2D
var illustration: AnimatedSprite2D
const Layer = preload("res://ui/fx/spell_layer.gd")
var layers: Array[AnimatedSprite2D] = []

func execute() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free.call_deferred()
		return
	var owner_node := get_parent()
	if grounded:
		position = Vector2.ZERO
	elif owner_node is Node2D and owner_node.has_node("ImpactAnchor"):
		position = owner_node.get_node("ImpactAnchor").position
	surface = $Surface as Sprite2D
	surface.material = surface.material.duplicate()
	surface.material.set_shader_parameter("progress", 0.0)
	if playback and playback.is_valid():
		playback.kill()
	playback = create_tween()
	illustration = get_node_or_null("Illustration") as AnimatedSprite2D
	if illustration:
		illustration.stop()
		illustration.animation = &"default"
		illustration.frame = 0
	layers.clear()
	for child in get_children():
		if child is Layer:
			layers.append(child)
	_sample(0.0)
	playback.tween_method(_sample, 0.0, 1.0, maxf(duration, 0.05))
	playback.tween_callback(queue_free)

func _sample(value: float) -> void:
	surface.material.set_shader_parameter("progress", value)
	if illustration and not illustration is Layer:
		var frames := illustration.sprite_frames.get_frame_count(&"default")
		illustration.frame = mini(int(pow(value, 0.75) * float(frames)), frames - 1)
		illustration.modulate.a = 1.0 - smoothstep(0.78, 1.0, value)
	for layer in layers:
		layer.sample(value)
