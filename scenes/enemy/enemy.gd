class_name Enemy
extends Node2D

signal damage_taken(amount: int)

const UNIT_BADGES := preload("res://ui/world_ui/unit_badges.tscn")
const WHITE_SPRITE_MATERIAL = preload("res://resources/materials/white_sprite_material.tres")
const TEXT_FX : PackedScene = preload("res://ui/fx/text_fx.tscn")
const DEATH_FLASH_FX : PackedScene = preload("res://ui/fx/flash_fx.tscn")
const DEATH_SMOKE_FX : PackedScene = preload("res://ui/fx/smoke_fx.tscn")
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
var current_tile_position: Vector2i:
	set(value):
		current_tile_position = value
		if is_instance_valid(tilemap):
			tilemap.update_occupant(self, value)
var turn_ticker : int = 0
var hovered: bool = false
var queue_button: Button = null
var queue_hovered: bool = false
var is_dying := false
var pending_damage := 0

func set_current_action(value: EnemyAction) -> void:
	current_action = value
	update_intent()

func _ready():
	add_child(UNIT_BADGES.instantiate())
	if sprite_2d.material:
		sprite_2d.material = sprite_2d.material.duplicate()
		sprite_2d.material.set_shader_parameter("rim_color", Color(0.9, 0.68, 0.57, 0.55))
	if has_node("GroundPresence"):
		$GroundPresence.material.set_shader_parameter("accent", Color(0.84, 0.42, 0.34))
	Events.player_died.connect(func(): self.set_process(false))
	if not $Area2D.input_event.is_connected(_on_area_2d_input_event):
		$Area2D.input_event.connect(_on_area_2d_input_event)
	
	
	
func _physics_process(_delta):
	# Taller illustrations must not leak out from under neighboring fog cells.
	if is_instance_valid(tilemap):
		visible = not tilemap.is_tile_behind_fog(current_tile_position)
	

func set_stats(value: EnemyStats) -> void:
	# Inherited scenes can deserialize an empty base export before their override.
	if value == null:
		return
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
	if self is MovingEnemy:
		var escape: EnemyAction = preload("res://scenes/enemy/escape_collapse_action.gd").new()
		escape.intent = Intent.new()
		escape.intent.tooltip_text = "Plans to leave the collapsing edge"
		escape.intent.base_text = "Reposition"
		escape.intent.icon = preload("res://assets/rift/ui/move.svg")
		new_action_picker.add_child(escape)
		new_action_picker.move_child(escape, 0)
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
	Utils.ground_sprite(sprite_2d)
	setup_ai()
	if stats_ui:
		update_stats()
		stats_ui.hide()
		
func update_stats():
	if not stats_ui or not stats:
		return
	stats_ui.update_stats(stats)
	Events.enemy_updated.emit(self)

func update_intent() -> void:
	if current_action:
		current_action.update_intent_text()
	Events.enemy_updated.emit(self)

func do_turn() -> void:
	var evaluation_start := Time.get_ticks_usec()
	#stats.block = 0
	if is_dying or stats.health <= 0:
		Events.enemy_action_completed.emit(self)
		return
	if not current_action or not current_action.is_eligible():
		if current_action:
			Events.enemy_decision_rejected.emit(self, "intent_became_invalid")
		current_action = enemy_action_picker.get_action()
	if not current_action:
		TelemetryManager.track_event("enemy_waited", {"enemy": stats.enemy_name, "reason": "no_legal_action"})
		Events.enemy_action_completed.emit(self)
		return
		
	TelemetryManager.track_event("enemy_action", {"enemy": stats.enemy_name, "action": str(current_action.name), "turn": turn_ticker, "evaluation_us": Time.get_ticks_usec() - evaluation_start})
	current_action.perform_action()
	turn_ticker += 1
	
func take_damage(
	damage: int, which_modifier: Enums.ModifierType, direct: bool = false, impact_profile: ImpactProfile = null
) -> void:
	if stats.health <= 0:
		return
	pending_damage += 1

	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	print("[Enemy] %s incoming dmg=%s mod=%s direct=%s -> modified=%s (health=%s, block=%s)" % [name, damage, which_modifier, direct, modified_damage, stats.health, stats.block])
	var profile := impact_profile if impact_profile else ImpactProfile.for_damage(modified_damage)
	var fully_blocked := not direct and stats.block >= modified_damage and modified_damage > 0
	if fully_blocked:
		profile = ImpactProfile.for_weight(ImpactProfile.Weight.LIGHT)
		profile.tint_color = Color(0.66, 0.91, 0.94)
	sprite_2d.material.set_shader_parameter("hit_flash", 0.65)
	sprite_2d.self_modulate = profile.tint_color
	if profile.hitstop_duration > 0.0 and profile.hitstop_scale < 1.0:
		Utils.apply_hitstop(profile.hitstop_scale, profile.hitstop_duration)
	var tween := create_tween()
	var text_fx := TEXT_FX.instantiate() as TextFX
	text_fx.text = str(modified_damage)
	add_child(text_fx)
	text_fx.position = $ImpactAnchor.position
	if fully_blocked:
		text_fx.label.modulate = Color(0.66, 0.91, 0.94)
	text_fx.execute()
	if profile.decal_scene:
		var decal: VisualFX = profile.decal_scene.instantiate()
		decal.scale *= profile.decal_scale
		add_child(decal)
		decal.position = $ImpactAnchor.position
		decal.execute()
	if direct:
		tween.tween_callback(Utils.shake.bind(self, profile.shake_strength, profile.shake_duration))
		tween.tween_callback(stats.take_direct_damage.bind(modified_damage))
		tween.tween_interval(Utils.presentation_duration(0.17))
	else:
		tween.tween_callback(Utils.shake.bind(self, profile.shake_strength, profile.shake_duration))
		tween.tween_callback(stats.take_damage.bind(modified_damage))
		tween.tween_interval(Utils.presentation_duration(0.17))
	
	tween.finished.connect( 
		func(): 
			pending_damage -= 1
			sprite_2d.material.set_shader_parameter("hit_flash", 0.0)
			sprite_2d.self_modulate = Color.WHITE
			if stats.health <= 0 and not is_dying and pending_damage == 0:
				Events.enemy_died.emit(self)
				do_death()
				)

func _begin_death_sequence() -> bool:
	if is_dying:
		return false
	is_dying = true
	if is_instance_valid(tilemap):
		tilemap.remove_occupant(self)
	_play_death_feedback()
	return true

func _play_death_feedback() -> void:
	if DisplayServer.get_name() == "headless":
		return
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

	if is_instance_valid(phantom_camera_2d):
		Utils.shake(phantom_camera_2d, DEATH_SHAKE_STRENGTH, DEATH_SHAKE_DURATION)

	var death_sound: AudioStream = DEFAULT_DEATH_SOUND
	if stats and stats.death_sound:
		death_sound = stats.death_sound
	if death_sound:
		SoundManager.play_sound_random_pitch(death_sound)

func _fade_out_and_queue_free(duration: float = DEATH_FADE_DURATION) -> void:
	if DisplayServer.get_name() == "headless":
		queue_free.call_deferred()
		return
	var tween = create_tween()
	tween.tween_property(sprite_2d, "scale", sprite_2d.scale * DEATH_SCALE_PUNCH, Utils.presentation_duration(0.1))\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, duration)
	tween.tween_callback(queue_free)

func do_death() -> void:
	if not _begin_death_sequence():
		return
	TelemetryManager.track_stat("enemies_killed")
	_fade_out_and_queue_free()

func get_player_tile_position() -> Vector2i:
	if tilemap:
		return tilemap.player_position
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
		if is_instance_valid(queue_button):
			queue_button.grab_focus()
			queue_button.modulate = Color.WHITE


func _on_area_2d_mouse_entered() -> void:
	if tilemap.is_tile_behind_fog(current_tile_position):
		return
	hovered = true
	circle_indicator.show()
	if stats_ui:
		stats_ui.show()
		stats_ui.grab_focus()
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	if !hovered:
		return
	hovered = false
	circle_indicator.hide()
	if stats_ui and not stats_ui.inspection_pinned:
		stats_ui.hide()
		stats_ui.release_focus()
	pass # Replace with function body.


func set_queue_button(button: Button) -> void:
	queue_button = button
	if not queue_button:
		return
	queue_button.mouse_entered.connect(_on_queue_button_entered)
	queue_button.mouse_exited.connect(_on_queue_button_exited)


func _on_queue_button_entered() -> void:
	queue_hovered = true
	circle_indicator.show()
	if stats_ui:
		stats_ui.show()


func _on_queue_button_exited() -> void:
	queue_hovered = false
	if not hovered:
		circle_indicator.hide()
		if stats_ui and not stats_ui.inspection_pinned:
			stats_ui.hide()

func get_gold_value()-> int:
	return stats.gold_value
	
func get_resource_value() -> int:
	return RNG.instance.randi_range(0, stats.resource_value_max)
