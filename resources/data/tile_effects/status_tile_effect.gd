extends RuinTileEffect

@export var base_stacks := 1
@export var base_status : Status = preload("res://resources/data/statuses/attunement.tres")

func execute(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var attunement = base_status.duplicate()
	var status_effect = StatusEffect.new()
	attunement.stacks = base_stacks
	status_effect.status = attunement
	status_effect.execute(targets)
