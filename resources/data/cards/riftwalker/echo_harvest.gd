extends Card

func apply_effects(targets: Array[Node]) -> void:
	var tile_effect := GatherEffect.new()
	var tilemap_target = targets[0] as TilemapTarget
	var tilemap : ProcGenTilemap = tilemap_target.tilemap
	var tile_target : Vector2i = tilemap_target.tile_position
	var amount = tilemap.get_resource_count(tile_target)
	tilemap.set_resource_count(tile_target,0)
	tile_effect.amount = amount
	tile_effect.sound_fx = sound_fx
	var player_array = targets[0].get_tree().get_nodes_in_group("player")
	tile_effect.execute(player_array)
	
