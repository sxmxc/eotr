extends Node

var _hitstop_scales: Array[float] = []
var _hitstop_baseline: float = 1.0
var presentation_speed := 1.0
var _ground_offsets: Dictionary[Texture2D, Vector2] = {}

func ground_sprite(sprite: Sprite2D) -> void:
	if not sprite.texture:
		return
	if not _ground_offsets.has(sprite.texture):
		var image := sprite.texture.get_image()
		if image.is_compressed():
			image.decompress()
		var bounds := image.get_used_rect()
		# The opaque artwork's bottom rests on the node origin, regardless of padding.
		_ground_offsets[sprite.texture] = Vector2(0.0, image.get_height() * 0.5 - bounds.end.y)
	sprite.offset = _ground_offsets[sprite.texture]

func _exit_tree() -> void:
	# Input outlives RenderingServer and otherwise retains the configured texture.
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(null)

func stop_audio_for_shutdown() -> void:
	# Release playback while the audio server is still mixing. Stopping only as
	# SceneTree destroys its nodes can retain playback/stream resources at exit.
	for audio: Node in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		(audio as AudioStreamPlayer).stop()
		(audio as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.1, true, false, true).timeout

func presentation_duration(seconds: float) -> float:
	return 0.001 if DisplayServer.get_name() == "headless" else seconds / maxf(presentation_speed, 0.1)

func show_save_error(message: String) -> void:
	push_warning(message)
	var existing := get_node_or_null("SaveError") as AcceptDialog
	if existing:
		existing.dialog_text = message
		existing.popup_centered()
		return
	var dialog: AcceptDialog = preload("res://ui/save_error.tscn").instantiate()
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()

func _ready() -> void:
	await get_tree().root.ready
	# print("Utils creating SignalPrinter and attaching to Eventbus")
	# var signal_printer = SignalPrinter.new()
	# add_child(signal_printer)
	print("Utils ready")

func get_node_global_center(node: Node) -> Vector2:
	return node.global_position + node.size * 0.5
	
func get_control_global_center(control: Control) -> Vector2:
	var rect := control.get_global_rect()
	return rect.position + rect.size * 0.5	
	
func apply_hitstop(target_scale: float, duration: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if duration <= 0.0:
		return

	target_scale = clamp(target_scale, 0.05, 1.0)
	if _hitstop_scales.is_empty():
		_hitstop_baseline = Engine.time_scale

	_hitstop_scales.append(target_scale)
	_set_time_scale_to_active_min()

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	timer.ignore_time_scale = true
	add_child(timer)
	timer.timeout.connect(
		func():
			_hitstop_scales.erase(target_scale)
			if _hitstop_scales.is_empty():
				Engine.time_scale = _hitstop_baseline
			else:
				_set_time_scale_to_active_min()
			timer.queue_free()
	)
	timer.start()
	
func shake(thing: Node2D, strength: float, duration: float = 0.2) -> void:
	if not is_instance_valid(thing) or duration <= 0.0:
		return
	# Shake the visual child of combat units, leaving authoritative tile positions
	# untouched. Local offsets also work beneath rotated/scaled parents.
	var visual := thing.get_node_or_null("Sprite2D") as Node2D
	if not visual:
		visual = thing
	var old_tween: Tween = visual.get_meta("rift_shake_tween") if visual.has_meta("rift_shake_tween") else null
	if old_tween and old_tween.is_valid():
		old_tween.kill()
		visual.position = visual.get_meta("rift_shake_origin", visual.position)
	var origin := visual.position
	visual.set_meta("rift_shake_origin", origin)
	var effect := visual.create_tween()
	visual.set_meta("rift_shake_tween", effect)
	for i in range(8):
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		effect.tween_property(visual, "position", origin + offset * strength * (1.0 - i / 8.0), duration / 9.0)
	effect.tween_property(visual, "position", origin, duration / 9.0)


func _set_time_scale_to_active_min() -> void:
	var min_scale := _hitstop_baseline
	for scale in _hitstop_scales:
		min_scale = minf(min_scale, scale)
	Engine.time_scale = min_scale
