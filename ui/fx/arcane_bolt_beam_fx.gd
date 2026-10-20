extends ProjectileFX
## Arcane Bolt is a connected, braided channel. ProjectileFX is only the existing
## sequencing contract: no projectile body moves along this beam.
var source_ref: WeakRef
var target_ref: WeakRef
var start := Vector2.ZERO
var end := Vector2.ZERO
var elapsed := 0.0
var contact_time := 0.075
var length_world := 0.0
var active := false
var contacted := false

func execute(target: Node, source: Node = null) -> void:
	if DisplayServer.get_name() == "headless":
		force_complete_deferred()
		queue_free.call_deferred()
		return
	source_ref = weakref(source) if is_instance_valid(source) else null
	target_ref = weakref(target) if is_instance_valid(target) else null
	start = resolve_start(source)
	end = resolve_end(target, start)
	# Keep the previous pre-effect contact boundary; only presentation changes.
	contact_time = clampf(start.distance_to(end) / 1550.0, 0.075, 0.26)
	active = true
	_update_endpoints()
	queue_redraw()

func _update_endpoints() -> void:
	var source: Node = source_ref.get_ref() if source_ref else null
	var target: Node = target_ref.get_ref() if target_ref else null
	if is_instance_valid(source): start = resolve_start(source)
	if is_instance_valid(target): end = resolve_end(target, start)
	length_world = start.distance_to(end)
	global_transform = Transform2D((end - start).angle(), start)

func _physics_process(delta: float) -> void:
	if not active: return
	elapsed += delta
	_update_endpoints()
	if not contacted and elapsed >= contact_time:
		contacted = true
		var target: Node = target_ref.get_ref() if target_ref else null
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			play_visual_on_target(target)
		mark_complete()
	if elapsed >= contact_time + 0.2:
		queue_free()
		return
	queue_redraw()

func _curve(u: float, strand: int) -> Vector2:
	var phase := float(strand) * PI
	var envelope := pow(maxf(sin(u * PI), 0.0), 0.65)
	var wave := sin(u * TAU * 1.65 - elapsed * 27.0 + phase)
	return Vector2(u * length_world, wave * 4.5 * envelope)

func _draw() -> void:
	if not active or length_world < 0.1: return
	var opacity := smoothstep(0.0, 0.025, elapsed) * (1.0 - smoothstep(contact_time + 0.02, contact_time + 0.2, elapsed))
	var release := 1.0 - smoothstep(contact_time, contact_time + 0.2, elapsed)
	var axis := PackedVector2Array([Vector2.ZERO, Vector2(length_world, 0)])
	# Dark illustrated edge, cyan body and an unbroken bright capillary establish
	# a single connected channel. The two folded ribbons supply its arcane identity.
	draw_polyline(axis, Color(0.025, 0.12, 0.2, 0.35 * opacity), 9.0, true)
	draw_polyline(axis, Color(0.12, 0.55, 0.8, 0.45 * opacity), 4.5, true)
	draw_polyline(axis, Color(0.65, 0.96, 0.97, 0.9 * opacity), 1.2 + release * 0.6, true)
	for strand in range(2):
		var outline := PackedVector2Array()
		for i in range(49):
			outline.append(_curve(float(i) / 48.0, strand))
		draw_polyline(outline, Color(0.025, 0.15, 0.22, opacity * 0.8), 4.0, true)
		for i in range(48):
			var u := float(i) / 48.0
			var v := float(i + 1) / 48.0
			var p := _curve(u, strand)
			var q := _curve(v, strand)
			var width := 0.65 + pow(sin(u * PI), 2.0) * (1.2 + release * 0.5)
			var tone := 0.5 + 0.5 * sin(u * TAU * 1.65 - elapsed * 27.0 + strand * PI)
			var color := Color(0.16, 0.62, 0.83).lerp(Color(0.55, 0.97, 0.96), tone)
			color.a = opacity * 0.88
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, width), q + Vector2(0, width), q - Vector2(0, width), p - Vector2(0, width)]), color)
	# Small opposing brackets bind the channel to both bodies; these are open
	# strokes, rather than projectile heads, target rings or an expanding explosion.
	for at_end in [false, true]:
		var x := length_world if at_end else 0.0
		var facing := -1.0 if at_end else 1.0
		for side in [-1.0, 1.0]:
			var bracket := PackedVector2Array([Vector2(x + facing * 3, side * 6), Vector2(x - facing, side * 3.5), Vector2(x, side * 1.8)])
			draw_polyline(bracket, Color(0.35, 0.9, 0.94, opacity * 0.8), 1.1, true)
