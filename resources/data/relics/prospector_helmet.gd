extends Relic

var tilemap: ProcGenTilemap

func activate_relic(owner: RelicUI) -> void:
	owner.flash()
	tilemap = owner.get_tree().get_first_node_in_group("map_layer")
	tilemap.is_resource_count_visible = true
	
func deactivate_relic(_owner: RelicUI) -> void:
	tilemap.is_resource_count_visible = false

func get_description() -> String:
	return description
