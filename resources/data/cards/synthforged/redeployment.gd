extends Card

func get_valid_targets(ui: CardUI, modifiers: ModifierHandler) -> Array[Vector2i]:
	var board := ui.get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	var world := board.get_parent() as GameWorld
	var selected: Construct = ui.interaction_controller.relocation_unit if ui.interaction_controller else null
	if not is_instance_valid(selected) or ui.interaction_controller.active_card != ui:
		return super.get_valid_targets(ui, modifiers)
	var cells: Array[Vector2i] = []
	for cell in board.base_layer.get_surrounding_cells(selected.current_tile_position):
		if world.summons.legal_cell(cell): cells.append(cell)
	return cells

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	if targets.is_empty() or not targets[0] is Construct or targets[0].is_dying: return false
	if targets.size() == 1: return true
	if not targets[1] is TilemapTarget: return false
	var unit := targets[0] as Construct
	var destination := targets[1] as TilemapTarget
	var handler := unit.get_parent() as SummonHandler
	return destination.tilemap == unit.tilemap and handler.legal_cell(destination.tile_position) \
		and SummonHandler.distance(unit.tilemap, unit.current_tile_position, destination.tile_position) == 1
