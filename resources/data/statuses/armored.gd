class_name ArmoredStatus
extends Status

func initialize_status(target: Node) -> void:
	if not target.damage_taken.is_connected(_on_target_damage_taken):
		target.damage_taken.connect(_on_target_damage_taken)

func apply_status(target: Node) -> void:
	if stacks <= 0:
		return
	var block_effect := BlockEffect.new()
	block_effect.amount = stacks
	block_effect.execute([target])
	
	status_applied.emit(self)


func get_tooltip() -> String:
	return tooltip % stacks

func _on_target_damage_taken(amount) -> void:
	stacks -= amount
