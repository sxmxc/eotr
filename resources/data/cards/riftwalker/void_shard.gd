extends Card

var base_damage := 6

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	var cam = targets[0].get_tree().get_first_node_in_group("map_camera")
	damage_effect.amount = modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.sound_fx = sound_fx
	damage_effect.visual_fx = visual_fx
	var projectile := projectile_fx.instantiate() as ProjectileFX
	if visual_fx:
		projectile.visual_fx = visual_fx.instantiate() as VisualFX
	var parent: Node = targets[0].get_tree().get_first_node_in_group("fx_layer")
	if not parent:
		parent = targets[0].get_tree().current_scene
	if parent:
		parent.add_child(projectile)
	projectile.complete.connect(func():
		damage_effect.execute(targets)
		Utils.shake(cam, 16, .15)
	)
	projectile.execute(targets[0])


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
