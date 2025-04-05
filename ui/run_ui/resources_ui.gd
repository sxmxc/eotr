extends HBoxContainer
class_name ResourceUI

@export var run_stats: RunStats : set = set_run_stats

@onready var label: Label = $Label

func set_run_stats(new_value: RunStats) -> void:
	run_stats = new_value
	
	if not run_stats.resources_changed.is_connected(_update_resources):
		run_stats.resources_changed.connect(_update_resources)
		_update_resources()
		
func _update_resources() -> void:
	label.text = str(run_stats.resources)
