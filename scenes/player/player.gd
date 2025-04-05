extends Node2D
class_name Player

const WHITE_SPRITE_MATERIAL = preload("res://resources/materials/white_sprite_material.tres")

@export var stats: PlayerStats : set = set_player_stats
@export var run_stats: RunStats : set = set_run_stats
@export var stats_ui: StatsUI
@export var status_handler: StatusHandler

@onready var sprite_2d : Sprite2D = $Sprite2D


#func _ready() -> void:
	#status_handler.status_owner = self

func set_player_stats(value: PlayerStats) -> void:
	if not is_node_ready():
		await ready
	stats = value
	update_player()

func set_run_stats(value: RunStats) -> void:
	if not is_node_ready():
		await ready
	run_stats = value
	
func update_player() -> void:
	if not stats is PlayerStats:
		return
	if not is_inside_tree():
		await ready
	sprite_2d.texture = stats.board_icon

	
func take_damage(damage: int) -> void:
	if stats.health <= 0:
		return
		
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self,16,.15))
	tween.tween_callback(stats.take_damage.bind(damage))
	tween.tween_interval(.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null
			if stats.health <= 0:
				Events.player_died.emit()
				queue_free()
	)

func _on_position_updated(pos: Vector2) -> void:
	position = pos
