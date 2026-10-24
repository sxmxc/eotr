extends Card

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	var world := player.get_parent() as GameWorld
	return world.run_stats.gold >= 8 and player.stats.health < player.stats.max_health

func resolve_effects(_targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	var world := player.get_parent() as GameWorld
	world.run_stats.gold -= 8
	stats.heal(4)
	if visual_fx and DisplayServer.get_name() != "headless":
		var feedback := visual_fx.instantiate() as VisualFX
		player.add_child(feedback)
		feedback.execute()
