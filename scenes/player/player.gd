extends Node2D
class_name Player

const WHITE_SPRITE_MATERIAL = preload("res://resources/materials/white_sprite_material.tres")

@export var stats: PlayerStats : set = set_player_stats
@export var run_stats: RunStats : set = set_run_stats
@export var stats_ui: StatsUI
@export var status_handler: StatusHandler
@export var movement_sound: AudioStream

@onready var token_shine_effect: VisualFX = %TokenShineEffect
@onready var sprite_2d : Sprite2D = $Sprite2D
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var phantom_camera_2d: PhantomCamera2D = %PhantomCamera2D


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

	
func take_damage(damage: int, which_modifier: Enums.ModifierType) -> void:
	if stats.health <= 0:
		return
		
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self,16,.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null
			if stats.health <= 0:
				Events.player_died.emit()
				queue_free()
	)

func _on_position_updated(pos: Vector2) -> void:
	var og_scale = scale
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.5,.1)
	tween.parallel().tween_property(self, "position", pos, .2)
	tween.tween_property(self, "scale", og_scale,.1)
	tween.tween_callback(
		func():
			SoundManager.play_sound_random_pitch(movement_sound)
			)
	
