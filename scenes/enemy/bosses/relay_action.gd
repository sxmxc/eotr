extends EnemyAction

func is_performable() -> bool:
	return true

func perform_action() -> void:
	Events.enemy_action_completed.emit(enemy)

func update_intent_text() -> void:
	intent.current_text = "Relay"
	intent.detail_text = "Stationary conduit. The lit relay transfers actual health damage to the Prismatic Core; destroying it interrupts this turn's discharge."
	if enemy and enemy.stats.enemy_name == "Memory Anchor":
		intent.current_text = "Memory"
		intent.detail_text = "The Spectre heals this Anchor while listening. Destroy it to stop Void Residue from entering your deck."

func get_queue_summary() -> String:
	return "Destroy to stop Void Residue" if enemy.stats.enemy_name == "Memory Anchor" else "When lit: damages the core"
