extends Card


func get_energy_cost(player_stats: PlayerStats) -> int:
	if not player_stats:
		return energy_cost
	return max(player_stats.energy, 1)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty():
		return
	var base_damage := last_energy_cost
	if base_damage <= 0:
		return

	var damage_config := CardEffectConfig.for_damage(base_damage)
	damage_config.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	damage_config.projectile_fx = projectile_fx
	damage_config.projectile_visual_fx = visual_fx
	damage_config.attach_visual_to_effect = false
	damage_config.sound_fx = sound_fx
	damage_config.camera_shake_strength = 16.0
	damage_config.camera_shake_duration = 0.15

	var resolver := CardResolver.new()
	await resolver.resolve(self, targets, null, modifiers, [damage_config])


func get_default_description() -> String:
	var preview: Variant = last_energy_cost
	if preview <= 0:
		preview = "current"
	return description % preview


func get_modified_description(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> String:
	var preview := _get_preview_damage(player_modifiers, enemy_modifiers)
	if preview <= 0:
		return description % "current"
	return description % preview


func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	var preview := _get_preview_damage(player_modifiers, null)
	return preview > 0 and preview != last_energy_cost


func _get_preview_damage(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> int:
	var energy_available := _get_current_energy(player_modifiers)
	if energy_available <= 0:
		return 0
	var modified := player_modifiers.get_modified_value(
		energy_available, Enums.ModifierType.DMG_DEALT
	)
	if enemy_modifiers:
		modified = enemy_modifiers.get_modified_value(
			modified, Enums.ModifierType.DMG_TAKEN
		)
	return modified


func _get_current_energy(player_modifiers: ModifierHandler) -> int:
	if not player_modifiers:
		return 0
	var tree := player_modifiers.get_tree()
	if not tree:
		return 0
	var handler := tree.get_first_node_in_group("player_handler") as PlayerHandler
	if not handler:
		return 0
	var stats := handler.player_stats
	if not stats:
		return 0
	return stats.energy
