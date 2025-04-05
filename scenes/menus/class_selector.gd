extends Control

const RIFTWALKER_STATS = preload("res://resources/data/stats/player/riftwalker_starting_stats.tres")
const SYNTHFORGED_STATS = preload("res://resources/data/stats/player/synthforged_starting_stats.tres")
const VOIDBINDER_STATS = preload("res://resources/data/stats/player/voidbinder_starting_stats.tres")
const RUN_SCENE = preload("res://scenes/run/run.tscn")

@export var run_bootstrap: RunBootstrap

@onready var class_name_label: Label = %ClassNameLabel
@onready var class_description: RichTextLabel = %ClassDescription

var current_stats: PlayerStats : set = set_current_stats

func _ready() -> void:
	set_current_stats(RIFTWALKER_STATS)

func set_current_stats(stats: PlayerStats) -> void:
	current_stats = stats
	class_name_label.text = current_stats.player_class_name
	class_description.text = current_stats.player_class_description

func _on_start_button_pressed() -> void:
	run_bootstrap.type = RunBootstrap.Type.NEW_RUN
	run_bootstrap.selected_player_class = current_stats
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_riftwalker_button_pressed() -> void:
	current_stats = RIFTWALKER_STATS
	


func _on_synthforge_button_pressed() -> void:
	current_stats = SYNTHFORGED_STATS
	


func _on_voidbinder_button_pressed() -> void:
	current_stats = VOIDBINDER_STATS
	
