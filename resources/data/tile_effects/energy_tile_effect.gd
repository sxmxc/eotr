extends RuinTileEffect

@export var base_amount := 1

func execute(targets: Array[Node], _modifiers: ModifierHandler) -> void:
		var energy_effect := EnergyEffect.new()
		energy_effect.amount = base_amount
		energy_effect.execute(targets)
