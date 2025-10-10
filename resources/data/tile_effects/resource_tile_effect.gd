extends RuinTileEffect

@export var base_amount := 1

func execute(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var gather_effect := GatherEffect.new()
	var tilemap = targets[0].get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	gather_effect.amount = base_amount
	gather_effect.tile_target_position = tilemap.player_position
	gather_effect.execute(targets)
