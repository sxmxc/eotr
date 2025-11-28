extends Control

const RIFTWALKER_STATS = preload("res://resources/data/stats/player/riftwalker_starting_stats.tres")
const SYNTHFORGED_STATS = preload("res://resources/data/stats/player/synthforged_starting_stats.tres")
const VOIDBINDER_STATS = preload("res://resources/data/stats/player/voidbinder_starting_stats.tres")
const RUN_SCENE = preload("res://scenes/run/run.tscn")

@export var run_bootstrap: RunBootstrap

@onready var class_name_label: Label = %ClassNameLabel
@onready var class_description: RichTextLabel = %ClassDescription
@onready var riftwalker_button: Button = %RiftwalkerButton
@onready var bouncer: Bouncer = %Bouncer
@onready var synthforge_button: Button = %SynthforgeButton
@onready var voidbinder_button: Button = %VoidbinderButton
@onready var starting_relic_label: Label = %StartingRelicLabel
@onready var synthforged_background: TextureRect = $SynthforgedBackground
@onready var voidbinder_background: TextureRect = $VoidbinderBackground
@onready var riftwalker_background: TextureRect = $RiftwalkerBackground

var current_stats: PlayerStats : set = set_current_stats
var _current_background: TextureRect
var current_background: TextureRect : set = set_background, get = get_background
var active_tween: Tween

func _ready() -> void:
	current_stats = RIFTWALKER_STATS
	current_background = riftwalker_background

func set_current_stats(stats: PlayerStats) -> void:
	current_stats = stats
	class_name_label.text = current_stats.player_class_name
	class_description.text = current_stats.player_class_description
	starting_relic_label.text = "Starting Relic: %s" % current_stats.starting_relic.relic_name

func get_background() -> TextureRect:
	return _current_background

func set_background(background_texture_rect: TextureRect) -> void:
	# Cancel any in-flight transition
	#if active_tween and active_tween.is_running():
		#active_tween.kill()
	
	if _current_background == background_texture_rect:
		return

	# Prepare new bg: visible, white RGB, alpha 0
	background_texture_rect.show()
	background_texture_rect.self_modulate = Color(1, 1, 1, 0)

	active_tween = get_tree().create_tween().set_parallel(true)

	# Fade out old bg (alpha only)
	if _current_background and is_instance_valid(_current_background):
		active_tween.tween_property(_current_background, "self_modulate:a", 0.0, 1)

	# Fade in new bg (alpha only)
	active_tween.tween_property(background_texture_rect, "self_modulate:a", 1.0, .3)

	active_tween.tween_callback(func ():
		if _current_background and is_instance_valid(_current_background):
			#_current_background.hide()
			_current_background.self_modulate = Color(1, 1, 1, 1) # reset for later reuse
		_current_background = background_texture_rect
	)
	

func _on_start_button_pressed() -> void:
	var stats_props : Dictionary[String,String] = {
		"class_name" : "%s" % current_stats.player_class_name
	}
	Talo.events.track("class_chosen", stats_props)
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	run_bootstrap.type = RunBootstrap.Type.NEW_RUN
	run_bootstrap.selected_player_class = current_stats
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_riftwalker_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	current_background = riftwalker_background
	current_stats = RIFTWALKER_STATS
	if bouncer.get_parent() != riftwalker_button:
		bouncer.reparent(riftwalker_button)
	


func _on_synthforge_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	current_background = synthforged_background
	current_stats = SYNTHFORGED_STATS
	if bouncer.get_parent() != synthforge_button:
		bouncer.reparent(synthforge_button)
	

func _on_voidbinder_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	current_background = voidbinder_background
	current_stats = VOIDBINDER_STATS
	if bouncer.get_parent() != voidbinder_button:
		bouncer.reparent(voidbinder_button)
	
