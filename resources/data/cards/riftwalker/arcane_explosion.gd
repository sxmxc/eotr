extends Card

func apply_effects(targets: Array[Node]):
	var damage_effect := DamageEffect.new()
	damage_effect.amount = 6
	damage_effect.sound_fx = sound_fx
	damage_effect.execute(targets)
