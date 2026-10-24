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
	synthforge_button.tooltip_text = "Synthforged — Overclock and allied constructs"
	voidbinder_button.tooltip_text = "Voidbinder - Locked"
	current_stats = RIFTWALKER_STATS
	current_background = riftwalker_background

func set_current_stats(stats: PlayerStats) -> void:
	current_stats = stats
	class_name_label.text = current_stats.player_class_name
	var paragraphs := current_stats.player_class_description.split("\n", false, 1)
	class_description.text = "[color=#%s]%s[/color]" % [class_description.get_theme_color("font_color", "Muted").to_html(), paragraphs[0]]
	if paragraphs.size() > 1:
		class_description.text += "\n\n" + paragraphs[1]
	starting_relic_label.text = current_stats.starting_relic.relic_name

func get_background() -> TextureRect:
	return _current_background

func set_background(background_texture_rect: TextureRect) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	if _current_background == background_texture_rect:
		return

	# Prepare new bg: visible, white RGB, alpha 0
	background_texture_rect.show()
	background_texture_rect.self_modulate = Color(1, 1, 1, 0)

	active_tween = create_tween().set_parallel(true)
	if _current_background:
		active_tween.tween_property(_current_background, "self_modulate:a", 0.0, 0.22)
	active_tween.tween_property(background_texture_rect, "self_modulate:a", 1.0, 0.22)
	_current_background = background_texture_rect


func _on_start_button_pressed() -> void:
	UIAnimation.animate_shrink(%ClassPanel)
	var stats_props : Dictionary[String,String] = {
		"class_name" : "%s" % current_stats.player_class_name
	}
	TelemetryManager.track_event("class_chosen", stats_props)
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
	


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
