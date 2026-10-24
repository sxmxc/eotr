extends EnemyAction

var sealed_cells: Array[Vector2i] = []
var warning_cell := Vector2i(-1, -1)
var marker: Node2D

func _ready() -> void:
	Events.player_turn_started.connect(_prepare)
	marker = preload("res://ui/world_ui/weave_warning.tscn").instantiate()
	add_child(marker)

func _prepare() -> void:
	if not is_instance_valid(enemy) or enemy.is_dying or enemy.stats.health <= 0:
		return
	warning_cell = Vector2i(-1, -1)
	for cell in enemy.tilemap.base_layer.get_surrounding_cells(enemy.tilemap.player_position):
		if enemy.tilemap.is_tile_valid(cell) and not enemy.tilemap.is_tile_corrupt(cell) and enemy.tilemap.is_tile_free(cell):
			warning_cell = cell
			break
	if is_instance_valid(marker):
		marker.visible = warning_cell != Vector2i(-1, -1)
		marker.global_position = enemy.tilemap.cell_to_world(warning_cell)
	enemy.update_intent()

func _process(_delta: float) -> void:
	if is_instance_valid(marker) and is_instance_valid(enemy) and is_instance_valid(enemy.tilemap):
		marker.visible = enemy.current_action == self and not enemy.is_dying and enemy.stats.health > 0 and warning_cell != Vector2i(-1, -1) and enemy.tilemap.is_within_bounds(warning_cell) and not enemy.tilemap.is_tile_behind_fog(warning_cell)

func is_performable() -> bool:
	return true

func perform_action() -> void:
	var board := enemy.tilemap
	if warning_cell != Vector2i(-1, -1) and board.is_within_bounds(warning_cell):
		# Always retain another safe neighboring cell; never remove the last exit.
		var exits := 0
		for cell in board.base_layer.get_surrounding_cells(board.player_position):
			if cell != warning_cell and board.is_tile_valid(cell) and not board.is_tile_corrupt(cell) and board.is_tile_free(cell):
				exits += 1
		if exits > 0 and board.is_tile_free(warning_cell):
			if sealed_cells.size() >= 2:
				var old: Vector2i = sealed_cells.pop_front()
				if board.is_within_bounds(old): board.change_terrain(old, Enums.TileType.RESOURCE)
			board.change_terrain(warning_cell, Enums.TileType.CORRUPTED)
			sealed_cells.append(warning_cell)
		else:
			var damage := DamageEffect.new()
			damage.source_actor = enemy
			damage.amount = 3
			damage.execute([target])
	marker.hide()
	warning_cell = Vector2i(-1, -1)
	Events.enemy_action_completed.emit(enemy)

func update_intent_text() -> void:
	intent.current_text = "Seal route"
	intent.detail_text = "Corrupt the rooted cell (%d, %d). Occupy it to deny the seal (3 blockable damage instead). At most two seals; the final safe exit is preserved." % [warning_cell.x, warning_cell.y]
