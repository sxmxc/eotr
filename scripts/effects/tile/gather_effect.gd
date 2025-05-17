extends TileEffect
class_name GatherEffect

var amount := 0
var tile_target_position : Vector2 = Vector2.ZERO

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target or not target.run_stats:
			continue
		if target is Player:
			Talo.stats.track("resources_gathered", amount)
			target.run_stats.resources += amount
			if visual_fx != null:
				var visual_effect : VisualFX = visual_fx.instantiate()
				if "quantity" in visual_effect:
					visual_effect.quantity = amount
				target.get_tree().get_first_node_in_group("map_layer").add_child(visual_effect)
				visual_effect.position = tile_target_position
				visual_effect.execute()
			SoundManager.play_sound_random_pitch(sound_fx)
