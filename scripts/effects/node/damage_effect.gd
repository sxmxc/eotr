extends NodeEffect
class_name DamageEffect

const TEXT_FX = preload("res://ui/fx/text_fx.tscn")

var amount := 0
var cause := ""
# Explicit provenance; DoT, terrain, and enemy effects leave this false.
var player_side_attack := false
var source_actor: Node2D
var receiver_modifier_type := Enums.ModifierType.DMG_TAKEN
var direct := false
var impact_profile: ImpactProfile


func execute(targets: Array[Node]) -> void:
	var resolved_profile := impact_profile
	if not resolved_profile:
		resolved_profile = ImpactProfile.for_damage(max(amount, 0))

	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player or target is Construct:
			var pre_health : int = target.stats.health if target and target.stats else null
			var pre_block : int = target.stats.block if target and target.stats else null

			SoundManager.play_sound_random_pitch(sound_fx)
			if visual_fx != null:
				var visual_effect : VisualFX = visual_fx.instantiate()
				target.add_child(visual_effect)
				if visual_effect is SynthforgedFX: visual_effect.caster = source_actor
				visual_effect.execute()
			var attack_bonus := AnalyzedStatus.count(target) if player_side_attack else 0
			if target is Player:
				target.take_damage(amount + attack_bonus, receiver_modifier_type, direct, resolved_profile, get_player_cause())
			else:
				target.take_damage(amount + attack_bonus, receiver_modifier_type, direct, resolved_profile)
			if pre_health != null:
				print(
					"[DamageEffect] %s took %s (mod type %s, direct=%s) | health %s -> %s, block %s -> %s"
					% [
						target.name,
						amount,
						receiver_modifier_type,
						direct,
						pre_health,
						target.stats.health,
						pre_block,
						target.stats.block
					]
				)
			

func get_player_cause() -> String:
	if not cause.is_empty():
		return cause
	if is_instance_valid(source_actor) and source_actor is Enemy:
		var attacker := source_actor as Enemy
		if not is_instance_valid(attacker.tilemap) or attacker.tilemap.is_tile_behind_fog(attacker.current_tile_position):
			return "An unseen attacker"
		return attacker.stats.enemy_name
	return "Damage"
