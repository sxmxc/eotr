extends TileEffect
class_name MoveEffect

var tilemap_target: TilemapTarget

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Player:
			tilemap_target.tilemap.move_player(tilemap_target.tile_position)
			SoundManager.play_sound_random_pitch(sound_fx)
