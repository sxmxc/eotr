extends EnemyAction


func is_performable() -> bool:
	if target == null:
		return false
	var enemy_tile = enemy.tilemap.base_layer.local_to_map(enemy.position)
	var player_tile = enemy.tilemap.base_layer.local_to_map(target.position)
	var surrounding_tiles = enemy.tilemap.base_layer.get_surrounding_cells(enemy_tile)
	if surrounding_tiles.has(player_tile):
		return false

	return true


func perform_action() -> void:
	if not enemy:
		return
	var moving_enemy := enemy as MovingEnemy
	var world_message = WorldMessageData.new("%s moves closer to player" % moving_enemy.name)
	Events.world_message_requested.emit(world_message)
	var player_tile = moving_enemy.tilemap.base_layer.local_to_map(target.position)
	var around_player := moving_enemy.tilemap.base_layer.get_surrounding_cells(player_tile)
	var target_tile := around_player[RNG.instance.randi_range(0, around_player.size() - 1)]
	moving_enemy.set_movement_target(target_tile)
	await moving_enemy.navigation_agent_2d.navigation_finished
	SoundManager.play_sound_random_pitch(sound)
	get_tree().create_timer(.6).timeout.connect(func(): Events.enemy_action_completed.emit(moving_enemy))
