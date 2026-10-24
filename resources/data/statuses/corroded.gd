extends Status
class_name CorrodedStatus

@export var damage_per_stack: int = 2
@export var block_shred_per_stack: int = 3


func apply_status(target: Node) -> void:
	if stacks <= 0 or not target:
		return
	if not (target is Enemy or target is Player):
		return

	var stacks_to_apply: int = max(stacks, 1)
	var stats: Stats = target.get("stats")
	if stats:
		var shred_amount: int = block_shred_per_stack * stacks_to_apply
		stats.block = max(stats.block - shred_amount, 0)

	var damage_effect := DamageEffect.new()
	damage_effect.cause = "Corrosion"
	damage_effect.amount = damage_per_stack * stacks_to_apply
	damage_effect.direct = true
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	damage_effect.execute([target])

	status_applied.emit(self)


func get_tooltip() -> String:
	var stacks_to_apply: int = max(stacks, 1)
	var damage_total: int = damage_per_stack * stacks_to_apply
	var block_loss: int = block_shred_per_stack * stacks_to_apply
	return tooltip % [damage_total, block_loss, duration]
