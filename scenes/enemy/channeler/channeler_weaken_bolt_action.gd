extends EnemyAction

const WEAKENED_STATUS := preload("res://resources/data/statuses/weakened.tres")

@export var damage := 5
@export_range(1, 4) var weaken_duration := 2
@export var projectile_scene: PackedScene
@export var projectile_visual_fx: PackedScene


func perform_action() -> void:
	if not enemy or not target:
		return

	var player := target as Player
	if not player:
		return

	var world_message := WorldMessageData.new("%s channels a weakening bolt" % enemy.name)
	Events.world_message_requested.emit(world_message)

	if projectile_scene:
		var projectile := projectile_scene.instantiate() as ProjectileFX
		if projectile_visual_fx:
			projectile.visual_fx = projectile_visual_fx.instantiate() as VisualFX
		add_child(projectile)
		projectile.execute(target, enemy)
		await projectile.complete

	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	damage_effect.visual_fx = visual_fx

	var weaken_effect := StatusEffect.new()
	var weakened := WEAKENED_STATUS.duplicate()
	weakened.duration = weaken_duration
	weaken_effect.status = weakened
	weaken_effect.sound_fx = sound

	intent.current_text = intent.base_text

	var targets: Array[Node] = [target]
	damage_effect.execute(targets)
	weaken_effect.execute(targets)

	Events.enemy_action_completed.emit(enemy)


func update_intent_text() -> void:
	if !is_instance_valid(target):
		return
	var player := target as Player
	if not player:
		return

	var modified_dmg := player.modifier_handler.get_modified_value(damage, Enums.ModifierType.DMG_TAKEN)
	modified_dmg = enemy.modifier_handler.get_modified_value(modified_dmg, Enums.ModifierType.DMG_DEALT)
	var summary := "%d/%d" % [modified_dmg, weaken_duration]
	intent.current_text = intent.base_text % summary
