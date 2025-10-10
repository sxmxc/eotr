extends RuinTileEffect

@export var base_amount := 1

func execute(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var draw_effect := DrawEffect.new()
	draw_effect.amount = base_amount
	draw_effect.execute(targets)
