extends EnemyAction

@export_range(0, 8) var block_gain := 3


func is_performable() -> bool:
	if not enemy or not target:
		return false
	var enemy_tile := enemy.tilemap.base_layer.local_to_map(enemy.position)
	var player_tile := enemy.tilemap.base_layer.local_to_map(target.position)
	var surrounding_tiles := enemy.tilemap.base_layer.get_surrounding_cells(player_tile)
	return not surrounding_tiles.has(enemy_tile)


func perform_action() -> void:
	if not enemy:
		return

	var world_message := WorldMessageData.new("%s braces forward" % enemy.name)
	Events.world_message_requested.emit(world_message)
	enemy.perform_turn_based_move(1)
	await enemy.navigation_agent_2d.navigation_finished

	if block_gain > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = block_gain
		block_effect.sound_fx = sound
		block_effect.visual_fx = visual_fx
		block_effect.execute([enemy])

	Events.enemy_action_completed.emit(enemy)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % block_gain
