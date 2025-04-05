extends Card

const BURNED_STATUS = preload("res://resources/data/statuses/burned.tres")

var base_damage := 4
var burn_duration := 2

func apply_effects(targets: Array[Node]) -> void:
	var damage_effect = DamageEffect.new()
	damage_effect.amount = base_damage
	damage_effect.sound_fx = sound_fx
	damage_effect.execute(targets)
	
	var status_effect = StatusEffect.new()
	var burned := BURNED_STATUS.duplicate()
	burned.duration = burn_duration
	status_effect.status = burned
	status_effect.execute(targets)
	
	
