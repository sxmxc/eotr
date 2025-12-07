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

	var cam = targets[0].get_tree().get_first_node_in_group("map_camera")
	var damage_effect := DamageEffect.new()
	var modified_damage := modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.amount = modified_damage
	damage_effect.sound_fx = sound_fx

	if projectile_fx and visual_fx:
		var projectile := projectile_fx.instantiate() as ProjectileFX
		projectile.visual_fx = visual_fx.instantiate() as VisualFX
		targets[0].get_tree().get_first_node_in_group("fx_layer").add_child(projectile)
		projectile.complete.connect(func():
			damage_effect.execute(targets)
			Utils.shake(cam, 16, .15)
		)
		projectile.execute(targets[0])
	else:
		damage_effect.visual_fx = visual_fx
		damage_effect.execute(targets)


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
