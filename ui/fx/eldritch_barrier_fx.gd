extends VisualFX
## A cosmetic shelter, driven by real block state. Never changes combat or RNG.
const INK := Color(0.025, 0.12, 0.16)
const TEAL := Color(0.18, 0.72, 0.79)
const LIGHT := Color(0.55, 0.94, 0.92)
const BRASS := Color(0.64, 0.61, 0.37)
const RADIUS := 39.0
const HEIGHT := 77.0
const DEPTH := 10.0
var actor: Player
var block_stats: Stats
var back_shell: Node2D
var age := 0.0
var release_age := -1.0
var hit_age := 10.0
var last_block := 0
var peak_block := 1
var running := false
var formation := 0.0
var opacity := 0.0
var flex := 1.0

func execute() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free()
		return
	actor = get_parent() as Player
	if not actor or not actor.stats or actor.stats.block <= 0:
		queue_free()
		return
	# One shelter per beneficiary even when block is reinforced several times.
	for sibling in actor.get_children():
		if sibling != self and sibling.get_script() == get_script() and sibling.running:
			sibling.reinforce()
			queue_free()
			return
	position = Vector2.ZERO
	z_index = 5 # Player's illustrated Sprite2D is 4.
	back_shell = Node2D.new()
	back_shell.name = "RearMembrane"
	back_shell.z_index = -2
	add_child(back_shell)
	back_shell.draw.connect(_draw_rear)
	block_stats = actor.stats
	last_block = block_stats.block
	peak_block = maxi(last_block, 1)
	block_stats.stats_changed.connect(_on_stats_changed)
	Events.player_turn_started.connect(_expire)
	running = true

func reinforce() -> void:
	peak_block = maxi(peak_block, block_stats.block)
	last_block = block_stats.block
	release_age = -1.0
	hit_age = 0.1

func _on_stats_changed() -> void:
	var current := block_stats.block
	# Turn reset also changes block; it is not an attack. Player's existing
	# pending_effects spans the authoritative damage callback and reaction.
	if current < last_block and is_instance_valid(actor) and actor.pending_effects > 0:
		hit_age = 0.0
	last_block = current
	if current <= 0:
		_expire()

func _expire() -> void:
	if release_age < 0.0:
		release_age = 0.0

func _process(delta: float) -> void:
	if not running: return
	if not is_instance_valid(actor):
		queue_free()
		return
	var step := delta * maxf(Utils.presentation_speed, 0.1)
	age += step
	hit_age += step
	if release_age >= 0.0:
		release_age += step
		if release_age > 0.26:
			queue_free()
			return
	formation = smoothstep(0.0, 0.3, age)
	var release := 1.0 - smoothstep(0.0, 0.26, maxf(release_age, 0.0))
	opacity = smoothstep(0.0, 0.07, age) * release
	flex = 1.0 - sin(hit_age * 24.0) * exp(-hit_age * 9.0) * 0.045
	queue_redraw()
	back_shell.queue_redraw()

func _point(angle: float, elevation: float, growth: float = 1.0) -> Vector2:
	var up := elevation * growth
	return Vector2(sin(angle) * cos(up) * RADIUS * flex,
		cos(angle) * cos(up) * DEPTH - sin(up) * HEIGHT)

func _line(canvas: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() > 1:
		canvas.draw_polyline(points, Color(color, color.a * opacity), width, true)

func _rim(canvas: Node2D, front: bool, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in range(41):
		var angle := lerpf(-PI * 0.5, PI * 0.5, float(i) / 40.0)
		if not front: angle += PI
		points.append(_point(angle, 0.0))
	_line(canvas, points, color, width)

func _draw_rear() -> void:
	if not running: return
	# Back rim and membrane sit behind the illustration, establishing enclosure.
	var hull := PackedVector2Array()
	for i in range(33):
		var angle := PI + float(i) / 32.0 * PI
		hull.append(Vector2(cos(angle) * RADIUS * flex, sin(angle) * HEIGHT * formation))
	back_shell.draw_colored_polygon(hull, Color(0.1, 0.51, 0.58, 0.065 * opacity))
	_rim(back_shell, false, Color(INK, 0.9), 2.6)
	_rim(back_shell, false, Color(TEAL, 0.65), 0.8)

func _draw() -> void:
	if not running: return
	var strength := 0.65 + 0.35 * clampf(float(last_block) / peak_block, 0.0, 1.0)
	var strike := exp(-hit_age * 8.5)
	var settling := 1.0 - smoothstep(0.32, 0.75, age)
	# Staggered, curved courses. Their bright outer and transparent inner edges
	# give the shell material depth without painting over the central silhouette.
	for side in [-1.0, 1.0]:
		var rise := smoothstep(0.025 if side > 0.0 else 0.0, 0.32, age)
		for course in range(3):
			var low := float(course) * PI / 6.0
			var high := float(course + 1) * PI / 6.0 - 0.025
			var panel := PackedVector2Array()
			var colors := PackedColorArray()
			for i in range(9):
				var e := lerpf(low, high, float(i) / 8.0)
				panel.append(_point(side * 1.5, e, rise))
				colors.append(Color(0.12, 0.65, 0.73, (0.23 * strength + strike * 0.22) * opacity))
			for i in range(9):
				panel.append(_point(side * 0.68, lerpf(high, low, float(i) / 8.0), rise))
				colors.append(Color(0.11, 0.4, 0.49, 0.025 * opacity))
			draw_polygon(panel, colors)
			# Unequal triangular planes borrow the fractured, painted facets in the card.
			var shard := PackedVector2Array([
				_point(side * 1.45, low + 0.02, rise),
				_point(side * 1.05, high, rise),
				_point(side * 0.8, low + 0.14, rise)])
			draw_polygon(shard, PackedColorArray([
				Color(0.31, 0.8, 0.8, 0.12 * opacity * strength),
				Color(0.16, 0.64, 0.73, 0.035 * opacity),
				Color(0.1, 0.34, 0.42, 0.01 * opacity)]))
		# Tapered brush rim: irregular width and value, rather than a UI-like wire.
		var ink_edge := PackedVector2Array()
		var brush := PackedVector2Array()
		var brush_colors := PackedColorArray()
		for i in range(33):
			var e := float(i) / 32.0 * PI * 0.5
			var point := _point(side * 1.52, e, rise)
			ink_edge.append(point)
			brush.append(point)
			var value := 0.3 + pow(sin(e * 2.1 + side * 0.4), 2.0) * 0.45
			brush_colors.append(Color(TEAL.lerp(LIGHT, value + strike * 0.3), (0.53 * strength + settling * 0.15 + strike * 0.25) * opacity))
		for i in range(32, -1, -1):
			var e := float(i) / 32.0 * PI * 0.5
			var point := _point(side * 1.52, e, rise)
			var width := (0.6 + pow(sin(e * 3.2 + side), 2.0) * 1.65) * sin(e + 0.28)
			brush.append(point - Vector2(side * width, -0.25))
			brush_colors.append(Color(TEAL, 0.07 * opacity))
		_line(self, ink_edge, Color(INK, 0.8), 2.8)
		draw_polygon(brush, brush_colors)
		# Seams stop at the flanks, never crossing the character's face or chest.
		for course in range(1, 3):
			var seam := PackedVector2Array()
			for i in range(13):
				seam.append(_point(side * lerpf(0.8, 1.5, float(i) / 12.0), float(course) * PI / 6.0, rise))
			_line(self, seam, Color(LIGHT, 0.14 * strength + strike * 0.5), 0.65)
		# Actual absorbed damage sends a brief pressure crease up each curved side.
		# This is keyed to block consumption, never the cast animation or a timer.
		if hit_age < 0.4:
			var travel := hit_age / 0.4
			var elevation := lerpf(0.18, 1.48, travel)
			var ripple := PackedVector2Array()
			for i in range(17):
				ripple.append(_point(side * lerpf(0.68, 1.53, float(i) / 16.0), elevation, rise))
			_line(self, ripple, Color(TEAL, sin(travel * PI) * 0.3), 3.0)
			_line(self, ripple, Color(LIGHT, sin(travel * PI) * 0.9), 1.3)
	# Ground contact is quiet and broken into sweeps, so it does not compete
	# with the existing occupancy ring and tile-selection highlights.
	for side in [-1.0, 1.0]:
		var lip := PackedVector2Array()
		for i in range(17):
			lip.append(_point(side * lerpf(0.12, 1.5, float(i) / 16.0), 0.0))
		_line(self, lip, Color(INK, 0.7), 2.2)
		_line(self, lip, Color(TEAL.lerp(LIGHT, strike), 0.35 * strength + strike * 0.4), 0.75)
	# Small clasp detail references the Riftwalker's brass fastening.
	var clasp := _point(0.0, 0.0)
	var diamond := PackedVector2Array([clasp + Vector2(0, -1.8), clasp + Vector2(1.3, 0), clasp + Vector2(0, 1.8), clasp + Vector2(-1.3, 0)])
	draw_colored_polygon(diamond, Color(BRASS, 0.65 * opacity * strength))
	if age < 0.5:
		var crest_alpha := sin(clampf((age - 0.2) / 0.3, 0.0, 1.0) * PI)
		var top := Vector2(0, -HEIGHT * formation)
		_line(self, PackedVector2Array([top + Vector2(-4, 2), top, top + Vector2(4, 2)]), Color(LIGHT, crest_alpha * 0.6), 1.0)
