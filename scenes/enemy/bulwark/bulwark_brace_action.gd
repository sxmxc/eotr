extends EnemyAction

const ARMORED_STATUS := preload("res://resources/data/statuses/armored.tres")

@export_range(0, 12) var block_amount := 8
@export_range(0, 10) var armor_stacks := 3
@export_range(0, 8) var min_block_before_brace := 4
@export_range(0, 4) var brace_cooldown_turns := 2

var _last_brace_turn := -99


func is_performable() -> bool:
	return enemy != null \
		and enemy.stats.block < min_block_before_brace \
		and enemy.turn_ticker - _last_brace_turn >= brace_cooldown_turns


func perform_action() -> void:
	if not enemy:
		return

	_last_brace_turn = enemy.turn_ticker

	var block_effect := BlockEffect.new()
	block_effect.amount = block_amount
	block_effect.sound_fx = sound
	block_effect.visual_fx = visual_fx
	block_effect.execute([enemy])

	var armored := ARMORED_STATUS.duplicate()
	armored.stacks = armor_stacks
	var status_effect := StatusEffect.new()
	status_effect.status = armored
	status_effect.sound_fx = sound
	status_effect.visual_fx = visual_fx
	status_effect.execute([enemy])

	var world_message := WorldMessageData.new("%s braces behind heavy plating" % enemy.name)
	Events.world_message_requested.emit(world_message)

	Events.enemy_action_completed.emit(enemy)


func update_intent_text() -> void:
	var summary := "%d/%d" % [block_amount, armor_stacks]
	intent.current_text = intent.base_text % summary
