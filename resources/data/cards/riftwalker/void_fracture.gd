extends Card

const VOID_SHARD = preload("res://resources/data/cards/riftwalker/void_shard.tres")

@export var amount := 3


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var player_handler : PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	for i in range(amount):
		player_handler.player_hand.add_card_spotlight(VOID_SHARD.duplicate())
	
