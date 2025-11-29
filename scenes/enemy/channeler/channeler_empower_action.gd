extends EnemyAction

const STRENGTH_STATUS := preload("res://resources/data/statuses/strength.tres")

@export var block_amount := 6
@export_range(1, 3) var strength_stacks := 1
@export_range(1, 4) var buff_cooldown_turns := 2

var _last_buff_turn := -99


func is_performable() -> bool:
	return enemy != null \
		and not _get_allies().is_empty() \
		and enemy.turn_ticker - _last_buff_turn >= buff_cooldown_turns


func perform_action() -> void:
	if not enemy:
		return

	var allies := _get_allies()
	if allies.is_empty():
		Events.enemy_action_completed.emit(enemy)
		return

	_last_buff_turn = enemy.turn_ticker

	var block_effect := BlockEffect.new()
	block_effect.amount = block_amount
	block_effect.sound_fx = sound
	block_effect.visual_fx = visual_fx

	var strength_effect := StatusEffect.new()
	var strength := STRENGTH_STATUS.duplicate()
	strength.stacks = strength_stacks
	strength_effect.status = strength
	strength_effect.sound_fx = sound

	intent.current_text = intent.base_text

	var message := WorldMessageData.new("%s empowers the swarm" % enemy.name, WorldMessageData.Priority.IMPORTANT)
	Events.world_message_requested.emit(message)

	block_effect.execute(allies)
	strength_effect.execute(allies)

	Events.enemy_action_completed.emit(enemy)


func update_intent_text() -> void:
	var summary := "%d/%d" % [block_amount, strength_stacks]
	intent.current_text = intent.base_text % summary


func _get_allies() -> Array[Node]:
	if not enemy:
		return []
	var others: Array[Node] = []
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemy"):
		if other == enemy:
			continue
		if other.stats and other.stats.health > 0:
			others.append(other)
	return others
