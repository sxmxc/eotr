extends EnemyAction

@export_range(1, 6) var tiles_per_turn := 1

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
	var generation := action_generation
	if not enemy:
		return
	print("%s advances" % enemy.stats.enemy_name)
	enemy.perform_turn_based_move(tiles_per_turn)
	await enemy.movement_finished
	if generation != action_generation:
		return
	SoundManager.play_sound_random_pitch(sound)
	complete_movement_action(generation, .3)
	
