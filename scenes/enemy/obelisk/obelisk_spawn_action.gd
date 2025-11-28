extends EnemyAction

@export var spawn_turn_freq := 5
@export_range(0, 10) var minimum_turns_before_spawn := 1
@export var allow_damage_override := true
@export_range(1, 12) var live_enemy_cap := 3
@export_range(0.05, 1.5, 0.05) var action_complete_delay := 0.3


func is_performable() -> bool:
	var obelisk := enemy as Obelisk
	if not obelisk:
		return false

	var has_spawn_tile := obelisk.has_viable_spawn_tile()
	var damage_override := allow_damage_override and obelisk.has_taken_damage()

	if not damage_override and enemy.turn_ticker < minimum_turns_before_spawn:
		return false

	var handler := obelisk.enemy_handler
	if handler and handler.get_active_mobile_enemy_count() >= live_enemy_cap:
		return false

	if enemy.turn_ticker % spawn_turn_freq != 0:
		return false

	return has_spawn_tile


func perform_action() -> void:
	if not enemy or not target:
		return
	var obelisk: Obelisk = enemy as Obelisk
	if not obelisk:
		return
	var spawned: bool = obelisk.spawn_random_enemy()
	var delay: float = action_complete_delay if spawned else min(action_complete_delay, 0.15)
	get_tree().create_timer(delay).timeout.connect(func(): Events.enemy_action_completed.emit(enemy))


func update_intent_text() -> void:
	intent.current_text = intent.base_text
	var obelisk: Obelisk = enemy as Obelisk
	if not obelisk:
		return
	
	var handler: EnemyHandler = obelisk.enemy_handler
	if handler and handler.get_active_mobile_enemy_count() >= live_enemy_cap:
		intent.current_text += "\nSpawn cap reached"
		return

	var next_tile = obelisk.peek_next_spawn_tile()
	if next_tile:
		intent.current_text += "\nNext spawn: (%d, %d)" % [next_tile.x, next_tile.y]
	else:
		intent.current_text += "\nAwaiting spawn window"
