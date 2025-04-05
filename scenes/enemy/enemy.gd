extends Node2D
class_name Enemy

const WHITE_SPRITE_MATERIAL = preload("res://resources/materials/white_sprite_material.tres")

@export var stats: EnemyStats : set = set_stats
@export var stats_ui: EnemyStatsUI
@export var tilemap: ProcGenTilemap

@onready var sprite_2d : Sprite2D = $Sprite2D
@onready var status_handler: StatusHandler = $StatusHandler

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action
var current_tile_position : Vector2i
var turn_ticker : int = 0

func set_current_action(value: EnemyAction) -> void:
	current_action = value

func _ready():
	Events.player_died.connect(func(): self.set_process(false))
	stats_ui.hide()
	status_handler.status_owner = self
	
func _physics_process(_delta):
	current_tile_position = tilemap.base_layer.local_to_map(position)
	if tilemap.base_layer.get_surrounding_cells(current_tile_position).has(get_player_tile_position()):
		stats_ui.show()
	else:
		stats_ui.hide()
	

func set_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		stats.stats_changed.connect(update_action)
	update_enemy()

func setup_ai() -> void:
	if enemy_action_picker:
		enemy_action_picker.queue_free()
	var new_action_picker: EnemyActionPicker = stats.ai.instantiate()
	add_child(new_action_picker)
	enemy_action_picker = new_action_picker
	enemy_action_picker.enemy = self

func update_action() -> void:
	if not enemy_action_picker:
		return
	if not current_action:
		current_action = enemy_action_picker.get_action()
		return
		
	var new_conditional_action := enemy_action_picker.get_first_conditional_action()
	if new_conditional_action and current_action != new_conditional_action:
		current_action = new_conditional_action
	
func update_enemy() -> void:
	if not stats is EnemyStats:
		return
	if not is_inside_tree():
		await ready
	
	sprite_2d.texture = stats.board_icon
	setup_ai()
	update_stats()
		
func update_stats():
	stats_ui.update_stats(stats)

func do_turn() -> void:
	print("%s doing turn" % name)
	stats.block = 0
	
	if not current_action:
		return
		
	current_action.perform_action()
	turn_ticker += 1
	
func take_damage(damage: int) -> void:
	if stats.health <= 0:
		return
		
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_callback(stats.take_damage.bind(damage))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0:
				Events.enemy_died.emit(self)
				queue_free()
			)
	

func get_player_tile_position() -> Vector2i:
	var player = get_tree().get_first_node_in_group("player")
	if player and tilemap and tilemap.base_layer:
		var player_tile = tilemap.base_layer.local_to_map(tilemap.base_layer.to_local(player.global_position))
		return player_tile
	
	return Vector2i.ZERO
