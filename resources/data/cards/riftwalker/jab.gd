extends Card

@export var base_damage := 6

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
	if modified_dmg != base_damage:
		return true
	return false

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	if targets.is_empty():
		return false
	var enemy : Enemy = targets[0]
	var tilemap = enemy.tilemap
	return tilemap.base_layer.get_surrounding_cells(tilemap.player_position).has(enemy.current_tile_position)

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.sound_fx = sound_fx
	damage_effect.visual_fx = visual_fx
	damage_effect.execute(targets)
	await targets[0].get_tree().create_timer(.3).timeout
	damage_effect.execute(targets)
	
