extends Card

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var selected := targets[0] as Construct
	var handler := selected.get_parent() as SummonHandler
	var cluster: Array[Node] = []
	for unit in handler.living():
		if SummonHandler.distance(selected.tilemap, unit.current_tile_position, selected.current_tile_position) <= 1: cluster.append(unit)
	await super.resolve_effects(cluster, stats, modifiers)
