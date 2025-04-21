extends Panel
class_name StatsUI

@export var player_stats: PlayerStats:
	set = set_player_stats
	
@export var stat_change_fx : PackedScene
@export var stat_change_txt_fx : PackedScene

@onready var health_ui: HealthUI = %HealthUI
@onready var block_label := %BlockLabel
@onready var energy_label := %EnergyLabel
@onready var blockfx_marker: Marker2D = %blockfx_marker
@onready var energyfx_marker: Marker2D = %energyfx_marker
@onready var block_icon: TextureRect = %BlockIcon
@onready var energy_icon: TextureRect = %EnergyIcon



var last_health
var last_block
var last_energy
var last_max_energy

func set_player_stats(value: PlayerStats) -> void:
	player_stats = value

	if not player_stats.stats_changed.is_connected(_on_stats_changed):
		player_stats.stats_changed.connect(_on_stats_changed)

	if not is_node_ready():
		await ready
		
	last_energy = player_stats.energy
	last_max_energy = player_stats.max_energy
	last_block = player_stats.block
	
	_on_stats_changed()


func _on_stats_changed() -> void:
	
	
	# Update labels
	energy_label.text = "%s/%s" % [player_stats.energy, player_stats.max_energy]
	block_label.text = str(player_stats.block)
	
	# Energy change check
	if player_stats.energy > last_energy:
		var txt_fx: TextFX = stat_change_txt_fx.instantiate() as TextFX
		add_child(txt_fx)
		txt_fx.text = str(player_stats.energy - last_energy)
		txt_fx.global_position = energyfx_marker.global_position
		txt_fx.label.add_theme_color_override("font_color", Color.GREEN)
		txt_fx.execute()
		stat_changed("energy")
	elif player_stats.energy < last_energy:
		var txt_fx: TextFX = stat_change_txt_fx.instantiate() as TextFX
		add_child(txt_fx)
		txt_fx.text = str(last_energy - player_stats.energy)
		txt_fx.global_position = energyfx_marker.global_position
		txt_fx.label.add_theme_color_override("font_color", Color.RED)
		txt_fx.execute()
		
	last_energy = player_stats.energy
	
	# Max energy change check
	if player_stats.max_energy > last_max_energy:
		var txt_fx: TextFX = stat_change_txt_fx.instantiate() as TextFX
		add_child(txt_fx)
		txt_fx.text = str(player_stats.max_energy - last_max_energy)
		txt_fx.global_position = energyfx_marker.global_position
		txt_fx.label.add_theme_color_override("font_color", Color.GREEN)
		txt_fx.execute()
		stat_changed("energy_max")
	elif player_stats.max_energy< last_max_energy:
		var txt_fx: TextFX = stat_change_txt_fx.instantiate() as TextFX
		add_child(txt_fx)
		txt_fx.text = str(last_max_energy - player_stats.max_energy)
		txt_fx.global_position = energyfx_marker.global_position
		txt_fx.label.add_theme_color_override("font_color", Color.RED)
		txt_fx.execute()
	last_max_energy = player_stats.max_energy
	
	# Block change check
	if player_stats.block > last_block:
		var txt_fx: TextFX = stat_change_txt_fx.instantiate() as TextFX
		add_child(txt_fx)
		txt_fx.text = str(player_stats.block - last_block)
		txt_fx.global_position = blockfx_marker.global_position
		txt_fx.label.add_theme_color_override("font_color", Color.GREEN)
		txt_fx.execute()
		stat_changed("block")
	elif player_stats.block < last_block:
		var txt_fx: TextFX = stat_change_txt_fx.instantiate() as TextFX
		add_child(txt_fx)
		txt_fx.text = str(last_block - player_stats.block)
		txt_fx.global_position = blockfx_marker.global_position
		txt_fx.label.add_theme_color_override("font_color", Color.RED)
		txt_fx.execute()
	last_block = player_stats.block
	
	
	# Update the health UI last
	health_ui.update_stats(player_stats)

func stat_changed(which: String) -> void:
	var fx: VisualFX = stat_change_fx.instantiate() as VisualFX
	
	add_child(fx)
	
	
	match which:
		"block":
			fx.global_position = blockfx_marker.global_position
			var tween = create_tween()
			tween.tween_property(block_icon, "scale", Vector2(1.1,1.1), .3)
			tween.tween_property(block_icon, "scale", Vector2.ONE, .3)
			
		"energy_max", "energy":
			fx.global_position = energyfx_marker.global_position
			var tween = create_tween()
			tween.tween_property(energy_icon, "scale", Vector2(1.1,1.1), .3)
			tween.tween_property(energy_icon, "scale", Vector2.ONE, .3)
	
	fx.execute()
	
	
