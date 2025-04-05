extends Panel
class_name StatsUI

@export var player_stats: PlayerStats : set = set_player_stats

@onready var health_ui: HealthUI = %HealthUI
@onready var block_label := %BlockLabel
@onready var energy_label := %EnergyLabel

func set_player_stats(value: PlayerStats) -> void:
	player_stats = value
	
	if not player_stats.stats_changed.is_connected(_on_stats_changed):
		player_stats.stats_changed.connect(_on_stats_changed)

	if not is_node_ready():
		await ready

	_on_stats_changed()


func _on_stats_changed() -> void:
	energy_label.text = "%s / %s" % [player_stats.energy, player_stats.max_energy]
	block_label.text = str(player_stats.block)
	energy_label.text = "%s / %s" % [str(player_stats.energy), str(player_stats.max_energy)]
	health_ui.update_stats(player_stats)
