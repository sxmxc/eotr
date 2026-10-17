extends Card

@export var base_damage := 7
@export var obelisk_bonus := 5


func play(targets: Array[Node], player_stats: PlayerStats, modifiers: ModifierHandler) -> void:
	await _resolve_with_targets(targets, player_stats, modifiers)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	await _resolve_with_targets(targets, null, modifiers)


func get_default_description() -> String:
	return description % [base_damage, obelisk_bonus]


func get_modified_description(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> String:
	var modified_base := player_modifiers.get_modified_value(
		base_damage, Enums.ModifierType.DMG_DEALT
	)

	if enemy_modifiers:
		modified_base = enemy_modifiers.get_modified_value(
			modified_base, Enums.ModifierType.DMG_TAKEN
		)

	return description % [modified_base, obelisk_bonus]


func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	var modified_base := player_modifiers.get_modified_value(
		base_damage, Enums.ModifierType.DMG_DEALT
	)
	return not is_equal_approx(modified_base, base_damage)


func _sync_effect_configs() -> void:
	var damage_config: CardEffectConfig = CardEffectConfig.for_damage(base_damage)
	damage_config.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	damage_config.camera_shake_strength = 18.0
	damage_config.camera_shake_duration = 0.18
	damage_config.attach_visual_to_effect = false
	CardEffectConfigHelper.apply_card_defaults(self, damage_config, false)

	effect_configs = [damage_config]


func _resolve_with_targets(
	targets: Array[Node], player_stats: PlayerStats, modifiers: ModifierHandler
) -> void:
	if targets.is_empty():
		return

	_sync_effect_configs()
	var target := targets[0]
	var total_damage := _calculate_damage(target)

	if effect_configs.is_empty():
		return
	var damage_config := effect_configs[0] as CardEffectConfig
	damage_config.amount = total_damage

	var resolver := CardResolver.new()
	await resolver.resolve(self, targets, player_stats, modifiers, effect_configs)
	_emit_obelisk_message(target)


func _calculate_damage(target: Node) -> int:
	var damage := base_damage
	if target is Obelisk:
		damage += obelisk_bonus
	return damage


func _emit_obelisk_message(target: Node) -> void:
	if not (target is Obelisk):
		return
	var message := WorldMessageData.new(
		"Sever Anchor rips into the Obelisk for +%s bonus damage!" % obelisk_bonus,
		WorldMessageData.Priority.ROUTINE
	)
	Events.world_message_requested.emit(message)
