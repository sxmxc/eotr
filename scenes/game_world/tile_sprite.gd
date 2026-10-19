class_name TileSprite
extends Sprite2D

const SHAPES := [
	[Vector2(0, -32), Vector2(12, -26), Vector2(5, -9), Vector2(-13, -4), Vector2(-32, -16)],
	[Vector2(12, -26), Vector2(32, -16), Vector2(32, 16), Vector2(14, 10), Vector2(5, -9)],
	[Vector2(32, 16), Vector2(0, 32), Vector2(-2, 15), Vector2(14, 10)],
	[Vector2(0, 32), Vector2(-32, 16), Vector2(-32, -16), Vector2(-13, -4), Vector2(-2, 15)],
	[Vector2(-13, -4), Vector2(5, -9), Vector2(14, 10), Vector2(-2, 15)]
]
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(func(_arg): queue_free())

func swirl_out() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free()
		return
	var atlas := texture as AtlasTexture
	if not atlas:
		queue_free()
		return
	texture = null
	z_index = 1
	for i in SHAPES.size():
		var points := PackedVector2Array(SHAPES[i])
		var centroid := Vector2.ZERO
		for point in points:
			centroid += point
		centroid /= float(points.size())
		var shard := Node2D.new()
		shard.name = "Shard%d" % i
		shard.position = centroid
		add_child(shard)
		var local_points := PackedVector2Array()
		var uv := PackedVector2Array()
		for point in points:
			local_points.append(point - centroid)
			uv.append(atlas.region.position + Vector2(32, 32) + point)
		var underside := Polygon2D.new()
		underside.polygon = local_points
		underside.position.y = 4.5
		underside.color = Color(0.065, 0.075, 0.1)
		shard.add_child(underside)
		var face := Polygon2D.new()
		face.polygon = local_points
		face.uv = uv
		face.texture = atlas.atlas
		shard.add_child(face)
		var seam := Line2D.new()
		seam.points = local_points
		seam.closed = true
		seam.width = 0.8
		seam.default_color = Color(0.72, 0.48, 0.66, 0.9)
		seam.antialiased = true
		shard.add_child(seam)
		var flight := create_tween().set_parallel(true)
		var push := centroid.normalized() * (10.0 + float(i % 3) * 3.0)
		flight.tween_method(func(t: float):
			shard.position = centroid + push * (1.0 - pow(1.0 - t, 2.0)) + Vector2(0, 88.0 * t * t - sin(t * PI) * 6.0)
			shard.rotation = (float(i) - 2.0) * 0.17 * t
			shard.scale = Vector2.ONE * (1.0 - t * t * 0.55)
		, 0.0, 1.0, 0.64).set_delay(float(i % 3) * 0.025)
		flight.tween_property(seam, "modulate:a", 0.0, 0.2)
		flight.tween_property(shard, "modulate", Color(0.28, 0.25, 0.38, 0.0), 0.3).set_delay(0.39)
	var dust := preload("res://ui/fx/explosion_fx.tscn").instantiate() as VisualFX
	add_child(dust)
	dust.modulate = Color(0.58, 0.55, 0.68, 0.65)
	dust.execute()
	var finish := create_tween()
	finish.tween_interval(0.76)
	finish.tween_callback(queue_free)

func grow_out() -> void:
	animation_player.play("grow_out")
