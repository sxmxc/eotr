extends Card

@export var base_damage := 2

func get_default_description() -> String:
	return description

func get_modified_description(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return description

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if targets.is_empty():
		return
	var tree := targets[0].get_tree()
	if not tree:
		return
	var num_enemies := tree.get_nodes_in_group("enemy").size()
	if num_enemies <= 1:
		return

	var amount := base_damage * num_enemies
	var damage_effect := CardEffectConfig.for_damage(amount)
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	CardEffectConfigHelper.apply_card_defaults(self, damage_effect, true)

	var resolver := CardResolver.new()
	await resolver.resolve(self, targets, null, _modifiers, [damage_effect])
