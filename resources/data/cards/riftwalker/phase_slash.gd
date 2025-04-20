extends Card

var base_damage := 6

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.sound_fx = sound_fx
	var player_handler : PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if player_handler.card_types_played.has(Enums.CardType.MOVEMENT):
		damage_effect.direct = true
		damage_effect.execute(targets)
	damage_effect.execute(targets)


func get_default_description() -> String:
	return description % base_damage


func get_modified_description(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> String:
	var modified_dmg := player_modifiers.get_modified_value(
		base_damage, Enums.ModifierType.DMG_DEALT
	)

	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(
			modified_dmg, Enums.ModifierType.DMG_TAKEN
		)

	return description % modified_dmg
	
func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	var modified_dmg := player_modifiers.get_modified_value(
		base_damage, Enums.ModifierType.DMG_DEALT
	)
	var player_handler: PlayerHandler = player_modifiers.get_tree().get_first_node_in_group("player_handler")
	if modified_dmg != base_damage or player_handler.card_types_played.has(Enums.CardType.MOVEMENT):
		return true
	return false
