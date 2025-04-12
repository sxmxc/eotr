# meta-name: Relic
# meta-description: Create a Relic which can be acquired by the player.
extends Relic


func initialize_relic(_owner: RelicUI) -> void:
	print("New relic needs initializing")


func activate_relic(_owner: RelicUI) -> void:
	print("New Relic needs activation logic")


func deactivate_relic(_owner: RelicUI) -> void:
	print("New relic needs deactivation logic")


func get_description() -> String:
	return description
