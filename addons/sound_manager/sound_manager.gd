extends Node

const SoundEffectsPlayer = preload("res://addons/sound_manager/sound_effects.gd")
const MusicPlayer = preload("res://addons/sound_manager/music.gd")

var sound_effects: SoundEffectsPlayer = SoundEffectsPlayer.new(["Sounds", "SFX"], 8)
var ui_sound_effects: SoundEffectsPlayer = SoundEffectsPlayer.new(["UI", "Interface", "Sounds", "SFX"], 8)
var music: MusicPlayer = MusicPlayer.new(["Music"], 2)
var rng: RandomNumberGenerator

var sound_process_mode: ProcessMode:
	set(value):
		sound_effects.process_mode = value
	get:
		return sound_effects.process_mode

var ui_sound_process_mode: ProcessMode:
	set(value):
		ui_sound_effects.process_mode = value
	get:
		return ui_sound_effects.process_mode

var music_process_mode: ProcessMode:
	set(value):
		music.process_mode = value
	get:
		return music.process_mode


func _init() -> void:
	Engine.register_singleton("SoundManager", self)

	add_child(sound_effects)
	add_child(ui_sound_effects)
	add_child(music)

	self.sound_process_mode = PROCESS_MODE_PAUSABLE
	self.ui_sound_process_mode = PROCESS_MODE_ALWAYS
	self.music_process_mode = PROCESS_MODE_ALWAYS
	
func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = Time.get_datetime_string_from_system().to_int()
	rng.randomize()


func set_master_volume(volume_between_0_and_1) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume_between_0_and_1))
	

func get_sound_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(sound_effects.bus)))


func get_ui_sound_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(ui_sound_effects.bus)))


func set_sound_volume(volume_between_0_and_1) -> void:
	_show_shared_bus_warning()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(sound_effects.bus), linear_to_db(volume_between_0_and_1))
	

func set_ui_volume(volume_between_0_and_1) -> void:
	_show_shared_bus_warning()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(ui_sound_effects.bus), linear_to_db(volume_between_0_and_1))
	
func play_sound(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	return sound_effects.play(resource, override_bus)


func play_sound_with_pitch(resource: AudioStream, pitch: float = 1.0, override_bus: String = "") -> AudioStreamPlayer:
	var player = sound_effects.play(resource, override_bus)
	player.pitch_scale = pitch
	return player
	
func play_sound_random_pitch(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	var rnd =  rng.randf_range(0.5,1)
	var player = sound_effects.play(resource, override_bus)
	player.pitch_scale = rnd
	return player


func play_ui_sound(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	return ui_sound_effects.play(resource, override_bus)


func play_ui_sound_with_pitch(resource: AudioStream, pitch: float = 1.0, override_bus: String = "") -> AudioStreamPlayer:
	var player = ui_sound_effects.play(resource, override_bus)
	player.pitch_scale = pitch
	return player
	
func play_ui_sound_random_pitch(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	var rnd = rng.randf_range(0.5,1)
	var player = ui_sound_effects.play(resource, override_bus)
	player.pitch_scale = rnd
	return player


func set_default_sound_bus(bus: String) -> void:
	sound_effects.bus = bus


func set_default_ui_sound_bus(bus: String) -> void:
	ui_sound_effects.bus = bus


func get_music_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(music.bus)))


func set_music_volume(volume_between_0_and_1: float) -> void:
	_show_shared_bus_warning()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(music.bus), linear_to_db(volume_between_0_and_1))


func play_music(resource: AudioStream, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, 0.0,  0.0, crossfade_duration, override_bus)
	
func play_music_queue(resource: AudioStreamPlaylist, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play_queue(resource, 0.0,  0.0, crossfade_duration, override_bus)


func play_music_from_position(resource: AudioStream, position: float = 0.0, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, position, 0.0, crossfade_duration, override_bus)


func play_music_at_volume(resource: AudioStream, volume: float = 0.0, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, 0.0, volume, crossfade_duration, override_bus)


func play_music_from_position_at_volume(resource: AudioStream, position: float = 0.0, volume: float = 0.0, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, position, volume, crossfade_duration, override_bus)


func get_music_track_history() -> Array:
	return music.track_history


func get_last_played_music_track() -> String:
	return music.track_history[0]


func is_music_playing(resource: AudioStream = null) -> bool:
	return music.is_playing(resource)


func is_music_track_playing(resource_path: String) -> bool:
	return music.is_track_playing(resource_path)
	
func is_sound_playing() -> bool:
	return sound_effects.is_sound_playing()


func get_currently_playing_music() -> Array:
	return music.get_currently_playing()


func get_currently_playing_music_tracks() -> Array:
	return music.get_current_tracks()


func pause_music(resource: AudioStream = null) -> void:
	music.pause(resource)


func resume_music(resource: AudioStream = null) -> void:
	music.resume(resource)


func stop_music(fade_out_duration: float = 0.0) -> void:
	music.stop(fade_out_duration)


func set_default_music_bus(bus: String) -> void:
	music.bus = bus


### Helpers


func _show_shared_bus_warning() -> void:
	if music.bus == sound_effects.bus or music.bus == ui_sound_effects.bus:
		push_warning("Both music and sounds are using the same bus: %s" % music.bus)
