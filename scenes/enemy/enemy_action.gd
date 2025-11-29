extends Node
class_name EnemyAction

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0
@export var sound: AudioStream
@export var visual_fx: PackedScene

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D

func is_performable() -> bool:
	return false
	
func perform_action() -> void:
	pass

func get_weight(_decision_context: Dictionary = {}) -> float:
	if type != Type.CHANCE_BASED:
		return 0.0
	if not enemy:
		return 0.0
	return max(chance_weight, 0.0)

func get_expected_player_damage(raw_damage: int, hits: int = 1, ignore_block: bool = false) -> float:
	var player := target as Player
	if not player or not player.stats:
		return 0.0

	var modified_damage: int = raw_damage
	if enemy:
		modified_damage = enemy.modifier_handler.get_modified_value(modified_damage, Enums.ModifierType.DMG_DEALT)
	modified_damage = player.modifier_handler.get_modified_value(modified_damage, Enums.ModifierType.DMG_TAKEN)
	modified_damage = max(modified_damage, 0)

	if ignore_block:
		return float(modified_damage * hits)

	var remaining_block: int = player.stats.block
	var total_damage: float = 0.0
	for _i in range(hits):
		var blocked: int = min(remaining_block, modified_damage)
		var hit_damage: int = modified_damage - blocked
		total_damage += hit_damage
		remaining_block = max(remaining_block - modified_damage, 0)

	return total_damage

func get_attack_weight(raw_damage: int, hits: int = 1, decision_context: Dictionary = {}) -> float:
	var expected_damage: float = get_expected_player_damage(raw_damage, hits)
	var base_weight: float = max(chance_weight, 0.1)

	var distance: float = decision_context.get("distance_to_player", _get_tile_distance_to_target())
	var distance_penalty: float = 1.0
	if distance > 2.0:
		distance_penalty = 0.45
	elif distance > 1.1:
		distance_penalty = 0.7

	if expected_damage <= 0.0:
		return base_weight * distance_penalty * 0.2

	var player := target as Player
	var finisher_bonus: float = 1.0
	if player and player.stats and player.stats.health <= expected_damage:
		finisher_bonus = 1.6

	var pressure_bonus: float = clamp(expected_damage / float(max(raw_damage * hits, 1)), 0.45, 1.4)
	return base_weight * distance_penalty * finisher_bonus * pressure_bonus

func get_block_weight(_block_amount: int, decision_context: Dictionary = {}) -> float:
	if not enemy or not enemy.stats:
		return max(chance_weight, 0.0)

	var base_weight: float = max(chance_weight, 0.25)
	var health_ratio: float = float(enemy.stats.health) / float(max(enemy.stats.max_health, 1))
	var low_health_bonus: float = lerpf(1.0, 1.8, clamp(1.0 - health_ratio, 0.0, 1.0))

	var player := target as Player
	var player_energy: float = 0.0
	var player_block: float = 0.0
	if player and player.stats:
		player_energy = float(player.stats.energy)
		player_block = float(player.stats.block)
	player_energy = decision_context.get("player_energy", player_energy)
	player_block = decision_context.get("player_block", player_block)

	var threat_bonus: float = 1.0 + clamp((player_energy - 2.0) * 0.2, 0.0, 0.6)
	var patience_bonus: float = 1.0 + clamp(player_block / 25.0, 0.0, 0.6)

	var distance: float = decision_context.get("distance_to_player", _get_tile_distance_to_target())
	var distance_penalty: float = 0.85 if distance > 1.5 else 1.0

	return base_weight * low_health_bonus * threat_bonus * patience_bonus * distance_penalty

func update_intent_text() -> void:
	intent.current_text = intent.base_text

func _get_tile_distance_to_target() -> float:
	if not enemy or not target:
		return 0.0
	if not enemy.tilemap or not enemy.tilemap.base_layer:
		return 0.0

	var enemy_tile := enemy.tilemap.base_layer.local_to_map(enemy.position)
	var target_tile := enemy.tilemap.base_layer.local_to_map(target.position)
	return Vector2(enemy_tile).distance_to(Vector2(target_tile))
