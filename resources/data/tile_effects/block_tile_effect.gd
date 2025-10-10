extends RuinTileEffect

@export var base_amount := 10

func execute(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = base_amount
	block_effect.execute(targets)
