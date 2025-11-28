extends EnemyAction

const POISONED = preload("res://resources/data/statuses/poisoned.tres")

@export var damage := 4
@export var curse_fx_scene : PackedScene
@export var status_duration := 2

func perform_action() -> void:
	if not enemy or not target:
		return
	print("%s attacks!" % enemy.name)
	var world_message = WorldMessageData.new("%s attacks!" % enemy.name)
	Events.world_message_requested.emit(world_message)
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := start + start.direction_to(target.global_position) * 2
	var damage_effect := DamageEffect.new()
	var status_effect = StatusEffect.new()
	var target_array: Array[Node] = [target]
	var poisoned := POISONED.duplicate()
	var curse_fx : VisualFX = curse_fx_scene.instantiate()
	target.add_child(curse_fx)
	poisoned.duration = status_duration
	status_effect.status = poisoned
	status_effect.sound_fx = sound
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	damage_effect.visual_fx = visual_fx
	
	intent.current_text = intent.base_text
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(
		func():
			damage_effect.execute(target_array)
			status_effect.execute(target_array)
			curse_fx.execute()
			)
	
	tween.tween_interval(0.25)
	tween.tween_property(enemy,"global_position", start, 0.4)
	
	tween.finished.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)

func update_intent_text() -> void:
	if !is_instance_valid(target):
		return
	var player := target as Player
	if not player:
		return
	
	var modified_dmg := player.modifier_handler.get_modified_value(damage, Enums.ModifierType.DMG_TAKEN)
	intent.current_text = intent.base_text % modified_dmg
