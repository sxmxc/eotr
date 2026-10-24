extends Card

func get_valid_targets(ui: CardUI, _modifiers: ModifierHandler) -> Array[Vector2i]:
	var world := ui.get_battle_world()
	if not world:
		return []
	var board := world.tilemap
	var cells: Array[Vector2i] = []
	if board.get_resource_count(board.player_position) > 0: cells.append(board.player_position)
	return cells

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	if targets.is_empty() or not targets[0] is TilemapTarget: return false
	var tile := targets[0] as TilemapTarget
	return tile.tile_position == tile.tilemap.player_position and tile.tilemap.get_resource_count(tile.tile_position) > 0
