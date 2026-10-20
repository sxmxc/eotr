extends VisualFX
## Brief fracture on real block depletion. No persistent shield or state tracking.
const WARD_FRAMES = preload("res://resources/vfx/ward_assembly_frames.tres")

func execute() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free()
		return
	var owner_node := get_parent() as Node2D
	if owner_node and owner_node.has_node("ImpactAnchor"):
		position = owner_node.get_node("ImpactAnchor").position
	z_index = 7
	# Split the existing intact ward illustration along three irregular seams.
	# Use frame 2 directly, without replaying a cast or its pre-painted collision.
	var intact := WARD_FRAMES.get_frame_texture(&"default", 2) as AtlasTexture
	var cuts := [
		PackedVector2Array([Vector2(0, 0), Vector2(142, 0), Vector2(111, 99), Vector2(137, 142), Vector2(71, 256), Vector2(0, 256)]),
		PackedVector2Array([Vector2(142, 0), Vector2(256, 0), Vector2(256, 256), Vector2(168, 256), Vector2(137, 142), Vector2(111, 99)]),
		PackedVector2Array([Vector2(71, 256), Vector2(137, 142), Vector2(168, 256)])]
	var directions := [Vector2(-11, -3), Vector2(12, -2), Vector2(2, 10)]
	var turns := [-0.16, 0.14, 0.1]
	for i in range(cuts.size()):
		var shard := Polygon2D.new()
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point: Vector2 in cuts[i]:
			points.append((point - Vector2(128, 128)) * Vector2(0.34, 0.42))
			uvs.append(intact.region.position + point / 256.0 * intact.region.size)
		shard.polygon = points
		shard.uv = uvs
		shard.texture = intact.atlas
		shard.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		shard.modulate.a = 0.36
		add_child(shard)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(shard, "position", directions[i], Utils.presentation_duration(0.26)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", turns[i], Utils.presentation_duration(0.26))
		tween.tween_property(shard, "modulate:a", 0.0, Utils.presentation_duration(0.21)).set_delay(Utils.presentation_duration(0.05))
	var lifetime := create_tween()
	lifetime.tween_interval(Utils.presentation_duration(0.28))
	lifetime.tween_callback(queue_free)
