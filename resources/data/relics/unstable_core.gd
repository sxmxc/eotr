extends Relic

@export var amount := 5


func activate_relic(owner: RelicUI) -> void:
	var enemies = owner.get_tree().get_nodes_in_group("enemy")
	var damage_effect := DamageEffect.new()
	damage_effect.amount = amount
	damage_effect.receiver_modifier_type = Enums.ModifierType.NO_MODIFIER
	damage_effect.execute(enemies)
	owner.flash()
	var world_message = WorldMessageData.new("%s activated!" % relic_name)
	owner.get_tree().create_timer(.5).timeout.connect(
		func(): Events.world_message_requested.emit(world_message)
	)

	
