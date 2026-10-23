extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty():
		return
	var tree := targets[0].get_tree()
	if not tree:
		return
	var player: Player = tree.get_first_node_in_group("player")
	if not player or not player.stats:
		return

	var missing_health := absi(player.stats.max_health - player.stats.health)
	if missing_health <= 0:
		return

	var damage_effect := CardEffectConfig.for_damage(missing_health)
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	CardEffectConfigHelper.apply_card_defaults(self, damage_effect, true)

	var resolver := CardResolver.new()
	await resolver.resolve(self, targets, player.stats, modifiers, [damage_effect])


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description
	
func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	if not player_modifiers or not player_modifiers.get_tree():
		return false
	var player : Player = player_modifiers.get_tree().get_first_node_in_group("player")
	if not player or not player.stats:
		return false
	var life_dif = absi(player.stats.max_health - player.stats.health)
	return life_dif != 0
