extends "res://addons/sound_manager/abstract_audio_player_pool.gd"

signal sound_finished

func play(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	var player = prepare(resource, override_bus)
	player.finished.connect(
		func():
			sound_finished.emit()
	)
	player.call_deferred("play")
	return player

func is_sound_playing() -> bool:
	return busy_players.size() > 0
