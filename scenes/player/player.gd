extends Node2D
class_name Player

const WHITE_SPRITE_MATERIAL = preload("res://resources/materials/white_sprite_material.tres")
const TEXT_FX = preload("res://ui/fx/text_fx.tscn")

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

	
func take_damage(
	damage: int, which_modifier: Enums.ModifierType, direct: bool = false, impact_profile: ImpactProfile = null
) -> void:
	if stats.health <= 0:
		return
		
	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	var profile := impact_profile if impact_profile else ImpactProfile.for_damage(modified_damage)
	var cam: Node2D = get_tree().get_first_node_in_group("map_camera")
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
	tween.tween_callback(Utils.shake.bind(self, profile.shake_strength, profile.shake_duration))
	if cam:
		tween.tween_callback(Utils.shake.bind(cam, profile.shake_strength, profile.shake_duration))
	if direct:
		tween.tween_callback(stats.take_direct_damage.bind(modified_damage))
	else:
		tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	tween.finished.connect(
		func():
			sprite_2d.material = null
			sprite_2d.self_modulate = Color.WHITE
			if stats.health <= 0:
				Events.player_died.emit()
				Talo.stats.track("player_deaths")
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
			Events.player_moved.emit()
			)

func _on_player_teleported(pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "self_modulate", Color.TRANSPARENT, .1)
	tween.tween_property(self, "position", pos, .2)
	tween.tween_property(self, "self_modulate", Color.WHITE ,.1)
	tween.tween_callback(
		func():
			SoundManager.play_sound_random_pitch(movement_sound)
			)
	
