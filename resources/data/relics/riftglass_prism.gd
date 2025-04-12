extends Relic

@export var amount := 1


func activate_relic(owner: RelicUI) -> void:
	_add_energy(owner)


func _add_energy(owner: RelicUI) -> void:
	owner.flash()
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player.stats.energy += amount
