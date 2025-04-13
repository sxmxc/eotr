extends EnemyAction

const VOID_RESIDUE = preload("res://resources/data/cards/common/void_residue.tres")

@export var damage := 8


func perform_action() -> void:
	if not enemy or not target:
		return

	var player := target as Player
	if not player:
		return

	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := start + start.direction_to(target.global_position) * 2

	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	var modified_dmg := enemy.modifier_handler.get_modified_value(
		damage, Enums.ModifierType.DMG_DEALT
	)

	damage_effect.amount = modified_dmg
	damage_effect.sound_fx = sound

	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_callback(player.stats.draw_pile.add_card.bind(VOID_RESIDUE.duplicate()))
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)

	tween.finished.connect(func(): Events.enemy_action_completed.emit(enemy))
