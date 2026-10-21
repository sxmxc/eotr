class_name WeakenedStatus
extends Status

const MODIFIER := 0.5


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	var dmg_taken_modifier: Modifier = target.modifier_handler.get_modifier(
		Enums.ModifierType.DMG_TAKEN
	)
	assert(dmg_taken_modifier, "No damage modifier on %s" % target)
	var weakened_modifier_value := dmg_taken_modifier.get_value("weakened")

	if not weakened_modifier_value:
		weakened_modifier_value = ModifierValue.create_new_modifier(
			"weakened", Enums.ModifierValueType.PERCENT_BASED
		)
	weakened_modifier_value.percent_value = MODIFIER
	dmg_taken_modifier.add_new_value(weakened_modifier_value)


func remove_status(target: Node) -> void:
	if is_instance_valid(target) and is_instance_valid(target.modifier_handler):
		var modifier: Modifier = target.modifier_handler.get_modifier(Enums.ModifierType.DMG_TAKEN)
		if modifier:
			modifier.remove_value("weakened")


func get_tooltip() -> String:
	return tooltip % duration
