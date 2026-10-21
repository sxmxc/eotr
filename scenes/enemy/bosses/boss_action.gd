extends EnemyAction

# Adapter into EnemyHandler's existing completion/cancellation contract.
func is_performable() -> bool:
	return true

func perform_action() -> void:
	var generation := action_generation
	await enemy.call("perform_boss_turn", self, generation)
	if is_instance_valid(enemy) and generation == action_generation and not enemy.is_dying:
		Events.enemy_action_completed.emit(enemy)

func update_intent_text() -> void:
	if is_instance_valid(enemy):
		enemy.call("describe_boss_intent", intent)
