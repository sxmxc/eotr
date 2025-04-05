extends Card

func apply_effects(targets: Array[Node]) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = 10
	block_effect.sound_fx = sound_fx
	block_effect.execute(targets)
