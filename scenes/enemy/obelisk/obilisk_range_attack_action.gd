extends EnemyAction

const OBELISK_PROJECTILE_FX = preload("res://ui/fx/obelisk_projectile_fx.tscn")


var base_damage := 7

func perform_action() -> void:
	if not enemy or not target: 
		return
		
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	var cam = get_tree().get_first_node_in_group("map_camera")
	var projectile := OBELISK_PROJECTILE_FX.instantiate() as ProjectileFX
	projectile.visual_fx = visual_fx.instantiate() as VisualFX
	damage_effect.amount = base_damage
	damage_effect.sound_fx = sound
	
	intent.current_text = intent.base_text
	
	add_child(projectile)
	projectile.execute(target, enemy)
	await projectile.complete
	Shaker.shake(cam, 16, .15)
	damage_effect.execute(target_array)
	
	get_tree().create_timer(.5).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)


func update_intent_text() -> void:
	var player := target as Player
	if not player:
		return
	
	var modified_dmg := player.modifier_handler.get_modified_value(base_damage, Enums.ModifierType.DMG_TAKEN)
	intent.current_text = intent.base_text % modified_dmg
