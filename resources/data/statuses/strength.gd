class_name StrengthStatus
extends Status


func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)


func _on_status_changed(target: Node) -> void:
	print("Strength status: +%s damage" % stacks)
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	var dmg_dealt_modifier: Modifier = target.modifier_handler.get_modifier(
		Enums.ModifierType.DMG_DEALT
	)
	assert(dmg_dealt_modifier, "No damage modifier on %s" % target)
	var strength_modifier_value := dmg_dealt_modifier.get_value("strength")

	if not strength_modifier_value:
		strength_modifier_value = ModifierValue.create_new_modifier(
			"strength", Enums.ModifierValueType.FLAT
		)
	strength_modifier_value.flat_value = stacks
	dmg_dealt_modifier.add_new_value(strength_modifier_value)


func get_tooltip() -> String:
	return tooltip % stacks
