extends RuinTileEffect

@export var base_amount := 5

func execute(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = base_amount
	damage_effect.execute(targets)
