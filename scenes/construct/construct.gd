class_name Construct
extends Node2D

signal damage_taken(amount: int)

const BADGES := preload("res://ui/world_ui/unit_badges.tscn")
const TEXT_FX := preload("res://ui/fx/text_fx.tscn")
@export var definition: ConstructDefinition
@export var status_handler: StatusHandler
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var modifier_handler: ModifierHandler = $ModifierHandler
var stats: Stats
var tilemap: ProcGenTilemap
var current_tile_position: Vector2i
var pending_effects := 0
var is_dying := false
var attack_intent := Intent.new()

func _ready() -> void:
	stats = Stats.new()
	stats.max_health = definition.max_health
	stats.health = definition.max_health
	stats.damage_taken.connect(func(amount: int): damage_taken.emit(amount))
	sprite_2d.texture = definition.texture
	Utils.ground_sprite(sprite_2d)
	status_handler.status_owner = self
	add_to_group("construct")
	add_child(BADGES.instantiate())

func _physics_process(_delta: float) -> void:
	if is_dying: return
	visible = not tilemap.is_tile_behind_fog(current_tile_position)
	var target := attack_target()
	var damage := modifier_handler.get_modified_value(definition.damage, Enums.ModifierType.DMG_DEALT)
	if target:
		damage = target.modifier_handler.get_modified_value(damage + AnalyzedStatus.count(target), Enums.ModifierType.DMG_TAKEN)
	attack_intent.icon = preload("res://assets/rift/ui/attack.svg")
	attack_intent.current_text = str(damage) if target else "Wait"
	attack_intent.tooltip_text = "%s: range %d. %s" % [definition.display_name, definition.attack_range, "Targets " + target.stats.enemy_name if target else "No visible target in range"]

func take_damage(amount: int, modifier: Enums.ModifierType, direct := false, _profile: ImpactProfile = null) -> void:
	if is_dying:
		return
	var damage := modifier_handler.get_modified_value(amount, modifier)
	if direct:
		stats.take_direct_damage(damage)
	else:
		stats.take_damage(damage)
	var text := TEXT_FX.instantiate() as TextFX
	text.text = str(damage)
	add_child(text)
	text.execute()
	if stats.health <= 0:
		destroy()
	else:
		sprite_2d.self_modulate = Color(1, 0.65, 0.4)
		create_tween().tween_property(sprite_2d, "self_modulate", Color.WHITE, Utils.presentation_duration(0.18))

func destroy() -> void:
	if is_dying:
		return
	is_dying = true
	tilemap.remove_occupant(self)
	status_handler.cancel_application()
	var handler := get_parent() as SummonHandler
	if handler:
		handler.changed()
	if DisplayServer.get_name() == "headless":
		queue_free()
	else:
		SynthforgedFX.play_on(self, "construct_death")
		var duration := Utils.presentation_duration(0.24)
		var death := create_tween()
		death.tween_property(sprite_2d, "modulate:a", 0.0, duration)
		death.parallel().tween_property(sprite_2d, "position:y", sprite_2d.position.y + 5.0, duration)
		death.finished.connect(queue_free)

func attack_target() -> Enemy:
	var candidates: Array[Enemy] = []
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node is Enemy and not node.is_dying and node.stats.health > 0 \
			and not tilemap.is_tile_behind_fog(node.current_tile_position) \
			and SummonHandler.distance(tilemap, current_tile_position, node.current_tile_position) <= definition.attack_range:
			candidates.append(node)
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		var da := SummonHandler.distance(tilemap, current_tile_position, a.current_tile_position)
		var db := SummonHandler.distance(tilemap, current_tile_position, b.current_tile_position)
		if da != db:
			return da < db
		if a.stats.health != b.stats.health:
			return a.stats.health < b.stats.health
		return a.get_index() < b.get_index())
	return candidates[0] if not candidates.is_empty() else null

func activate() -> void:
	if is_dying:
		return
	var target := attack_target()
	if not target:
		return
	face_target(target.global_position)
	var effect := DamageEffect.new()
	effect.amount = modifier_handler.get_modified_value(definition.damage, Enums.ModifierType.DMG_DEALT)
	effect.player_side_attack = true
	effect.source_actor = self
	if DisplayServer.get_name() != "headless":
		var attack := "siege_attack" if definition.id == "siege_platform" else definition.id + "_attack"
		effect.visual_fx = load("res://ui/fx/synthforged/%s.tscn" % attack)
	effect.execute([target])
	while is_instance_valid(target) and target.pending_damage > 0 and is_inside_tree():
		await get_tree().process_frame

func face_target(target_position: Vector2) -> void:
	var direction := target_position.x - global_position.x
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0.0

