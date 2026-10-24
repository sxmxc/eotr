extends RefCounted

var checked_round := -1

func inspect(world: GameWorld) -> Dictionary:
	var result := {"fatal": "", "warnings": []}
	if not is_instance_valid(world.player):
		result.fatal = "Player reference disappeared during active combat"
		return result
	var occupied := {world.tilemap.player_position: "player"}
	for node in world.enemy_handler.get_children():
		if not node is Enemy or node.is_dying or node.stats.health <= 0:
			continue
		for cell in node.occupied_tiles():
			if occupied.has(cell):
				result.fatal = "Entities overlap at %s: %s and %s" % [cell, occupied[cell], node.stats.enemy_name]
				return result
			occupied[cell] = node.stats.enemy_name
			if not world.tilemap.is_within_bounds(cell):
				result.fatal = "Live required enemy outside battlefield: " + node.stats.enemy_name
				return result
		if checked_round != world.current_round and node is MovingEnemy and not node.can_reach_tile(world.tilemap.player_position):
			result.warnings.append("No grounded path to player for " + node.stats.enemy_name + "; ranged/teleport options may still resolve this legally")
	checked_round = world.current_round
	return result
