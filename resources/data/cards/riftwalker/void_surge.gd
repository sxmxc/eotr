extends Card

var base_damage := 0

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.sound_fx = sound_fx
	var player : Player = targets[0].get_tree().get_first_node_in_group("player")
	var life_dif = absi(player.stats.max_health - player.stats.health)
	base_damage += life_dif
	damage_effect.amount = modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.execute(targets)


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description
	
func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	var player : Player = player_modifiers.get_tree().get_first_node_in_group("player")
	var life_dif = absi(player.stats.max_health - player.stats.health)
	if life_dif != 0:
		return true
	return false
