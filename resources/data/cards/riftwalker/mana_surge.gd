extends Card

func apply_effects(targets: Array[Node]) -> void:
	var energy_effect := EnergyEffect.new()
	energy_effect.amount = 1
	energy_effect.sound_fx = sound_fx
	energy_effect.execute(targets)
