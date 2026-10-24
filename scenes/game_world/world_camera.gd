# Runtime-only framing controller; the base camera supplies its editor integration.
@warning_ignore("missing_tool")
extends PhantomCamera2D

# Framing inputs only; PhantomCameraHost remains the sole Camera2D driver.
@onready var world: GameWorld = get_parent()
var overview := false
var manual := false
var aiming := false
var dragging := false
var tactical_zoom := 1.5
const TACTICAL_MIN := 1.1
const TACTICAL_MAX := 2.15

func _ready() -> void:
	super._ready()
	get_viewport().size_changed.connect(_resize)
	Events.card_aim_started.connect(_aim_started)
	Events.card_drag_started.connect(_aim_started)
	Events.card_aim_ended.connect(_aim_ended)
	Events.card_drag_ended.connect(_aim_ended)
	var board := world.get_node("Tilemap") as ProcGenTilemap
	board.player_position_updated.connect(_follow_player)
	board.player_teleported.connect(_follow_player)

func _follow_player(_position: Vector2) -> void:
	if not is_instance_valid(world.player):
		return
	manual = false
	overview = false
	dragging = false
	# Give Phantom Camera the moving actor; its native damping owns the chase.
	set_follow_target(world.player)
	follow_mode = FollowMode.SIMPLE
	_update_safe_offset()

func _start_pan() -> void:
	if follow_target == world.player:
		world.tilemap.center_marker.global_position = world.player.global_position
	set_follow_target(world.tilemap.center_marker)
	follow_mode = FollowMode.SIMPLE
	manual = true
	dragging = true

func combat_rect() -> Rect2:
	return world.game_world_ui.combat_rect()

func board_bounds(revealed_only := false) -> Rect2:
	var bounds := Rect2()
	var first := true
	var half := Vector2(world.tilemap.base_layer.tile_set.tile_size) / 2.0
	for cell: Vector2i in world.tilemap.tile_map_data:
		if revealed_only and world.tilemap.is_tile_behind_fog(cell):
			continue
		var tile_rect := Rect2(world.tilemap.cell_to_world(cell) - half, half * 2.0)
		bounds = tile_rect if first else bounds.merge(tile_rect)
		first = false
	# Reserve space above tile origins for tall actors and their intention badges.
	bounds.position.y -= 40.0
	bounds.size.y += 52.0
	return bounds.grow(12.0)

func fit_zoom() -> float:
	var bounds := board_bounds()
	var usable := combat_rect().size
	return minf(usable.x / maxf(bounds.size.x, 1.0), usable.y / maxf(bounds.size.y, 1.0))

func combatant_bounds() -> Rect2:
	var bounds := Rect2(world.player.global_position - Vector2(48, 96), Vector2(96, 128))
	for enemy: Enemy in world.enemy_handler.get_children():
		if enemy.is_dying or not enemy.is_revealed(): continue
		var body := enemy.sprite_2d.global_transform * enemy.sprite_2d.get_rect()
		# Include the existing intent label above the grounded body.
		body.position.y -= 32.0
		body.size.y += 32.0
		bounds = bounds.merge(body)
	return bounds.grow(24.0)

func frame_battle(fit := false) -> void:
	if aiming or world.tilemap.tile_map_data.is_empty():
		return
	overview = fit
	manual = false
	var bounds := board_bounds()
	if not fit:
		bounds = board_bounds(true)
	var boss_stage := world.battle_stats != null and world.battle_stats.category == EncounterDefinition.Category.BOSS
	if boss_stage and not fit:
		bounds = combatant_bounds()
	# Do not sacrifice character readability to fit a large encounter.
	var usable := combat_rect().size
	tactical_zoom = clampf(minf(usable.x / bounds.size.x, usable.y / bounds.size.y), TACTICAL_MIN, TACTICAL_MAX)
	var boss_zoom := minf(minf(usable.x / bounds.size.x, usable.y / bounds.size.y), TACTICAL_MAX)
	set_zoom(Vector2.ONE * (minf(fit_zoom(), TACTICAL_MAX) if fit else boss_zoom if boss_stage else tactical_zoom))
	var center := bounds.get_center()
	if not fit and not boss_stage and fit_zoom() < TACTICAL_MIN and is_instance_valid(world.player):
		center = world.player.global_position
		# Keep the player in view without wasting space beyond a nearby board edge.
		var half_view := combat_rect().size / (zoom * 2.0)
		center.x = bounds.get_center().x if bounds.size.x <= half_view.x * 2.0 else clampf(center.x, bounds.position.x + half_view.x, bounds.end.x - half_view.x)
		center.y = bounds.get_center().y if bounds.size.y <= half_view.y * 2.0 else clampf(center.y, bounds.position.y + half_view.y, bounds.end.y - half_view.y)
	follow_target = world.tilemap.center_marker
	follow_mode = FollowMode.SIMPLE
	world.tilemap.center_marker.global_position = center
	_update_safe_offset()
	priority = 40

func _update_safe_offset() -> void:
	set_follow_offset((get_viewport_rect().size / 2.0 - combat_rect().get_center()) / zoom)

func _resize() -> void:
	if not is_node_ready() or not world.is_node_ready():
		return
	if manual or follow_target == world.player:
		_update_safe_offset()
	else:
		frame_battle(overview)

func _aim_started(_card: CardUI) -> void:
	aiming = true
	dragging = false

func _aim_ended(_card: CardUI = null) -> void:
	aiming = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("drag_camera"):
		dragging = false
	if aiming or get_tree().paused or world.tilemap.tile_map_data.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_HOME or event.physical_keycode == KEY_F:
			frame_battle(event.physical_keycode == KEY_F)
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and combat_rect().has_point(event.position):
		if event.is_action_pressed("drag_camera"):
			_start_pan()
		if event.is_action_pressed("zoom_in") or event.is_action_pressed("zoom_out"):
			manual = true
			var factor := 1.1 if event.is_action_pressed("zoom_in") else 1.0 / 1.1
			set_zoom(Vector2.ONE * clampf(zoom.x * factor, minf(fit_zoom(), TACTICAL_MIN), tactical_zoom * 1.5))
			_update_safe_offset()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and dragging:
		if not Input.is_action_pressed("drag_camera"):
			dragging = false
			return
		manual = true
		world.tilemap.center_marker.global_position -= event.relative / zoom
		var bounds := board_bounds()
		world.tilemap.center_marker.global_position = world.tilemap.center_marker.global_position.clamp(bounds.position, bounds.end)
		get_viewport().set_input_as_handled()
