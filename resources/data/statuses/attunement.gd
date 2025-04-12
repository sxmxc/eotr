class_name AttunementStatus
extends Status


func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)


func _on_status_changed(target: Node) -> void:
	print("Attunement status: +%s damage" % stacks)
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	var dmg_dealt_modifier: Modifier = target.modifier_handler.get_modifier(
		Enums.ModifierType.DMG_DEALT
	)
	assert(dmg_dealt_modifier, "No damage modifier on %s" % target)
	var attunement_modifier_value := dmg_dealt_modifier.get_value("attunement")

	if not attunement_modifier_value:
		attunement_modifier_value = ModifierValue.create_new_modifier(
			"attunement", Enums.ModifierValueType.FLAT
		)
	attunement_modifier_value.flat_value = stacks
	dmg_dealt_modifier.add_new_value(attunement_modifier_value)


func get_tooltip() -> String:
	return tooltip % stacks
