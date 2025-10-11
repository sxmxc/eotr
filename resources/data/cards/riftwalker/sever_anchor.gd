extends Card

@export var base_damage := 7
@export var obelisk_bonus := 5


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty():
		return

	var target := targets[0]
	var total_damage := _calculate_damage(target)
	var damage_effect := DamageEffect.new()
	var cam := target.get_tree().get_first_node_in_group("map_camera")
	damage_effect.amount = modifiers.get_modified_value(total_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.sound_fx = sound_fx

	var projectile := projectile_fx.instantiate() as ProjectileFX
	if visual_fx:
		projectile.visual_fx = visual_fx.instantiate() as VisualFX
	target.get_tree().get_first_node_in_group("fx_layer").add_child(projectile)
	projectile.complete.connect(func():
		damage_effect.execute(targets)
		Utils.shake(cam, 18, 0.18)
		_emit_obelisk_message(target)
	)
	projectile.execute(target)


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
