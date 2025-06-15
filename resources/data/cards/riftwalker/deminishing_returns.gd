extends Card

@export var base_damage := 2

func get_default_description() -> String:
	return description

func get_modified_description(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return description

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	# Find all enemies
	var all_enemies := targets[0].get_tree().get_nodes_in_group("enemy")
	var num_enemies := all_enemies.size()
	if num_enemies <= 1:
		return
	# For each adjacent enemy, deal 2 * (num_enemies) damage
	for target in targets:
		if not target.is_in_group("enemy"):
			continue
		var damage_effect := DamageEffect.new()
		damage_effect.amount = base_damage * num_enemies
		damage_effect.sound_fx = sound_fx
		damage_effect.visual_fx = visual_fx
		damage_effect.execute([target])
