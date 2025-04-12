extends Relic

@export var stacks := 1


func activate_relic(owner: RelicUI) -> void:
	var target = owner.get_tree().get_first_node_in_group("player")

	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	var movement_modifier: Modifier = target.modifier_handler.get_modifier(
		Enums.ModifierType.MOVEMENT
	)
	assert(movement_modifier, "No movement modifier on %s" % target)
	var phase_key_modifier_value := movement_modifier.get_value("phase_key")

	if not phase_key_modifier_value:
		phase_key_modifier_value = ModifierValue.create_new_modifier(
			"phase_key", Enums.ModifierValueType.FLAT
		)
	phase_key_modifier_value.flat_value = stacks
	movement_modifier.add_new_value(phase_key_modifier_value)
	owner.flash()
	var world_message = WorldMessageData.new("Phase Key activated!")
	owner.get_tree().create_timer(2).timeout.connect(
		func(): Events.world_message_requested.emit(world_message)
	)
