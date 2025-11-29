class_name Enemy
extends Node2D

signal damage_taken(amount: int)

const WHITE_SPRITE_MATERIAL = preload("res://resources/materials/white_sprite_material.tres")
const TEXT_FX : PackedScene = preload("res://ui/fx/text_fx.tscn")
const DEATH_FLASH_FX : PackedScene = preload("res://ui/fx/flash_fx.tscn")
const DEATH_SMOKE_FX : PackedScene = preload("res://ui/fx/smoke_fx.tscn")
const DEATH_SPARK_FX : PackedScene = preload("res://ui/fx/spark_fx.tscn")
const DEATH_IMPACT_FX : PackedScene = preload("res://ui/fx/impact_decal_fx.tscn")
const DEATH_EMBER_FX : PackedScene = preload("res://ui/fx/ember_burst_fx.tscn")
const DEFAULT_DEATH_SOUND : AudioStream = preload("res://assets/audio/Monster Sounds/Ghost/Ghost_Death.ogg")
const DEATH_SHAKE_STRENGTH := 10.0
const DEATH_SHAKE_DURATION := 0.18
const DEATH_SCALE_PUNCH := 1.08
const DEATH_FADE_DURATION := 0.35

@export var stats: EnemyStats : set = set_stats
@export var stats_ui: EnemyStatsUI
@export var tilemap: ProcGenTilemap
@export var status_handler: StatusHandler

@onready var sprite_2d : Sprite2D = $Sprite2D
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var phantom_camera_2d: PhantomCamera2D = %PhantomCamera2D
@onready var circle_indicator: Sprite2D = %CircleIndicator

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action
var current_tile_position : Vector2i
var turn_ticker : int = 0
var hovered: bool = false
var is_dying := false

func set_current_action(value: EnemyAction) -> void:
	current_action = value
	if current_action:
		update_intent()

func _ready():
	Events.player_died.connect(func(): self.set_process(false))
	if not $Area2D.input_event.is_connected(_on_area_2d_input_event):
		$Area2D.input_event.connect(_on_area_2d_input_event)
	
	
	
func _physics_process(_delta):
	current_tile_position = tilemap.base_layer.local_to_map(position)
	

func set_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		stats.stats_changed.connect(update_action)
	if not stats.damage_taken.is_connected(func(arg): damage_taken.emit(arg)):
		stats.damage_taken.connect(func(arg): damage_taken.emit(arg))
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
	Events.enemy_updated.emit(self)

func update_intent() -> void:
	if current_action:
		current_action.update_intent_text()
		stats_ui.intent_ui.update_intent(current_action.intent)

func do_turn() -> void:
	#stats.block = 0
	if not current_action:
		return
		
	current_action.perform_action()
	turn_ticker += 1
	
func take_damage(
	damage: int, which_modifier: Enums.ModifierType, direct: bool = false, impact_profile: ImpactProfile = null
) -> void:
	if stats.health <= 0:
		return

	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	var profile := impact_profile if impact_profile else ImpactProfile.for_damage(modified_damage)
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	sprite_2d.self_modulate = profile.tint_color
	if profile.hitstop_duration > 0.0 and profile.hitstop_scale < 1.0:
		Utils.apply_hitstop(profile.hitstop_scale, profile.hitstop_duration)
	var tween := create_tween()
	var text_fx := TEXT_FX.instantiate() as TextFX
	text_fx.text = str(modified_damage)
	add_child(text_fx)
	text_fx.execute()
	if profile.decal_scene:
		var decal: VisualFX = profile.decal_scene.instantiate()
		decal.scale *= profile.decal_scale
		add_child(decal)
		decal.execute()
	if direct:
		tween.tween_callback(Utils.shake.bind(self, profile.shake_strength, profile.shake_duration))
		tween.tween_callback(stats.take_direct_damage.bind(modified_damage))
		tween.tween_interval(0.17)
	else:
		tween.tween_callback(Utils.shake.bind(self, profile.shake_strength, profile.shake_duration))
		tween.tween_callback(stats.take_damage.bind(modified_damage))
		tween.tween_interval(0.17)
	
	tween.finished.connect( 
		func(): 
			sprite_2d.material = null
			sprite_2d.self_modulate = Color.WHITE
			if stats.health <= 0:
				Events.enemy_died.emit(self)
				do_death()
				)

func _begin_death_sequence() -> bool:
	if is_dying:
		return false
	is_dying = true
	_play_death_feedback()
	return true

func _play_death_feedback() -> void:
	if circle_indicator:
		circle_indicator.hide()
	if stats_ui:
		stats_ui.release_focus()

	var flash_fx := DEATH_FLASH_FX.instantiate() as VisualFX
	add_child(flash_fx)
	flash_fx.execute()

	var smoke_fx := DEATH_SMOKE_FX.instantiate() as VisualFX
	add_child(smoke_fx)
	smoke_fx.execute()
	if DEATH_SPARK_FX:
		var spark_fx := DEATH_SPARK_FX.instantiate() as VisualFX
		spark_fx.scale *= 0.8
		add_child(spark_fx)
		spark_fx.execute()
	if DEATH_IMPACT_FX:
		var impact_fx := DEATH_IMPACT_FX.instantiate() as VisualFX
		impact_fx.scale *= 0.75
		add_child(impact_fx)
		impact_fx.execute()
	if DEATH_EMBER_FX:
		var ember_fx := DEATH_EMBER_FX.instantiate() as VisualFX
		ember_fx.scale *= 0.9
		add_child(ember_fx)
		ember_fx.execute()

	if is_instance_valid(phantom_camera_2d):
		Utils.shake(phantom_camera_2d, DEATH_SHAKE_STRENGTH, DEATH_SHAKE_DURATION)

	var death_sound: AudioStream = DEFAULT_DEATH_SOUND
	if stats and stats.death_sound:
		death_sound = stats.death_sound
	if death_sound:
		SoundManager.play_sound_random_pitch(death_sound)

func _fade_out_and_queue_free(duration: float = DEATH_FADE_DURATION) -> void:
	var tween = create_tween()
	tween.tween_property(sprite_2d, "scale", sprite_2d.scale * DEATH_SCALE_PUNCH, 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, duration)
	tween.tween_callback(queue_free)

func do_death() -> void:
	if not _begin_death_sequence():
		return
	Talo.stats.track("enemies_killed")
	_fade_out_and_queue_free()

func get_player_tile_position() -> Vector2i:
	var player = get_tree().get_first_node_in_group("player")
	if player and tilemap and tilemap.base_layer:
		var player_tile = tilemap.base_layer.local_to_map(tilemap.base_layer.to_local(player.global_position))
		return player_tile
	
	return Vector2i.ZERO


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_mouse"):
		if tilemap.is_tile_behind_fog(current_tile_position):
			return
		Events.enemy_selected.emit(self)


func _on_area_2d_mouse_entered() -> void:
	if tilemap.is_tile_behind_fog(current_tile_position):
		return
	hovered = true
	circle_indicator.show()
	stats_ui.grab_focus()
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	if !hovered:
		return
	hovered = false
	circle_indicator.hide()
	stats_ui.release_focus()
	pass # Replace with function body.

func get_gold_value()-> int:
	return stats.gold_value
	
func get_resource_value() -> int:
	return RNG.instance.randi_range(0, stats.resource_value_max)
