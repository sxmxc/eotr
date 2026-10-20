extends Node2D
class_name Player

const UNIT_BADGES := preload("res://ui/world_ui/unit_badges.tscn")
const WHITE_SPRITE_MATERIAL = preload("res://resources/materials/white_sprite_material.tres")
const TEXT_FX = preload("res://ui/fx/text_fx.tscn")
const BLOCK_BREAK_FX = preload("res://ui/fx/block_break_fx.tscn")
const PHASE_TRACE_FX = preload("res://ui/fx/phase_trace_fx.tscn")

@export var stats: PlayerStats : set = set_player_stats
@export var run_stats: RunStats : set = set_run_stats
@export var stats_ui: StatsUI
@export var status_handler: StatusHandler
@export var movement_sound: AudioStream

@onready var token_shine_effect: VisualFX = %TokenShineEffect
@onready var sprite_2d : Sprite2D = $Sprite2D
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var phantom_camera_2d: PhantomCamera2D = %PhantomCamera2D
@onready var mana_well_effect: GPUParticles2D = %ManaWellEffect

var is_mana_buffed : bool = false : set = set_is_mana_buffed
var pending_effects := 0
var movement_tween: Tween

func _ready() -> void:
	add_child(UNIT_BADGES.instantiate())


func set_player_stats(value: PlayerStats) -> void:
	if not is_node_ready():
		await ready
	stats = value
	update_player()

func set_run_stats(value: RunStats) -> void:
	if not is_node_ready():
		await ready
	run_stats = value

func set_is_mana_buffed(value: bool) -> void:
	if not is_node_ready():
		await ready
	is_mana_buffed = value
	mana_well_effect.emitting = is_mana_buffed
	
func update_player() -> void:
	if not stats is PlayerStats:
		return
	if not is_inside_tree():
		await ready
	sprite_2d.texture = stats.board_icon
	Utils.ground_sprite(sprite_2d)

	
func take_damage(
	damage: int, which_modifier: Enums.ModifierType, direct: bool = false, impact_profile: ImpactProfile = null
) -> void:
	if stats.health <= 0:
		return
	pending_effects += 1
		
	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	var profile := impact_profile if impact_profile else ImpactProfile.for_damage(modified_damage)
	var fully_blocked := not direct and stats.block >= modified_damage and modified_damage > 0
	if fully_blocked:
		profile = ImpactProfile.for_weight(ImpactProfile.Weight.LIGHT)
		profile.tint_color = Color(0.66, 0.91, 0.94)
	var cam: Node2D = get_tree().get_first_node_in_group("map_camera")
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
	tween.tween_callback(Utils.shake.bind(self, profile.shake_strength, profile.shake_duration))
	if cam:
		tween.tween_callback(Utils.shake.bind(cam, profile.shake_strength, profile.shake_duration))
	if direct:
		tween.tween_callback(stats.take_direct_damage.bind(modified_damage))
	else:
		tween.tween_callback(func():
			var block_before := stats.block
			stats.take_damage(modified_damage)
			# A cast is transient. Only a damaging hit that exhausts existing
			# block gets fracture feedback; turn resets and bypass damage do not.
			if block_before > 0 and stats.block == 0:
				var fracture := BLOCK_BREAK_FX.instantiate() as VisualFX
				add_child(fracture)
				fracture.execute()
		)
	tween.tween_interval(Utils.presentation_duration(0.17))
	tween.finished.connect(
		func():
			pending_effects -= 1
			sprite_2d.material.set_shader_parameter("hit_flash", 0.0)
			sprite_2d.self_modulate = Color.WHITE
			if stats.health <= 0:
				Events.player_died.emit()
				TelemetryManager.track_stat("player_deaths")
				queue_free()
	)

func face_target(target_position: Vector2) -> void:
	var direction := target_position.x - global_position.x
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0.0


func _on_position_updated(pos: Vector2) -> void:
	_spawn_phase_trace()
	pending_effects += 1
	var og_scale := sprite_2d.scale
	var tween = create_tween()
	movement_tween = tween
	tween.tween_property(sprite_2d, "scale", og_scale * 1.04,.1)
	tween.parallel().tween_property(self, "position", pos, Utils.presentation_duration(.2))
	tween.tween_property(sprite_2d, "scale", og_scale,.1)
	tween.tween_callback(
		func():
			SoundManager.play_sound_random_pitch(movement_sound)
			Events.player_moved.emit()
			pending_effects -= 1
			)

func _on_player_teleported(pos: Vector2) -> void:
	pending_effects += 1
	# Finish arriving on the gate before phasing to the destination.
	if movement_tween and movement_tween.is_running():
		await movement_tween.finished
	_spawn_phase_trace()
	var tween = create_tween()
	tween.tween_property(sprite_2d, "modulate:a", 0.0, Utils.presentation_duration(.1))
	tween.tween_callback(func(): position = pos)
	tween.tween_property(sprite_2d, "modulate:a", 1.0, Utils.presentation_duration(.1))
	tween.tween_callback(
		func():
			SoundManager.play_sound_random_pitch(movement_sound)
			Events.player_moved.emit()
			pending_effects -= 1
			)


func _spawn_phase_trace() -> void:
	var trace := PHASE_TRACE_FX.instantiate() as PhaseTraceFX
	trace.texture = sprite_2d.texture
	trace.texture_offset = sprite_2d.offset
	get_parent().add_child(trace)
	trace.global_transform = sprite_2d.global_transform
	trace.execute()
