class_name Card
extends Resource

static var RARITY_COLORS := {
	Enums.CardRarity.COMMON: Colors.rarity_common,
	Enums.CardRarity.UNCOMMON: Colors.rarity_uncommon,
	Enums.CardRarity.RARE: Colors.rarity_rare
}

@export_group("Card Attributes")
@export var card_type: Enums.CardType
@export var target_type: Enums.TargetType
@export var id: String
@export var name: String
@export var card_rarity: Enums.CardRarity
@export_multiline var description: String
@export var energy_cost: int
@export var exhaust: bool = false

@export_group("Card Sound and Visuals")
@export var card_art: Texture2D
@export var sound_fx: AudioStream
@export var visual_fx: PackedScene


func is_single_targeted() -> bool:
	return (
		target_type == Enums.TargetType.SINGLE_ENEMY or target_type == Enums.TargetType.SINGLE_TILE
	)


func is_valid_target(_targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	return true


func _get_targets(targets: Array[Node]) -> Array:
	if not targets:
		return []
	var tree := targets[0].get_tree() as SceneTree

	match target_type:
		Enums.TargetType.SELF:
			return tree.get_nodes_in_group("player")
		Enums.TargetType.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemy")
		Enums.TargetType.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemy")
		Enums.TargetType.SURROUNDING_ENEMIES:
			var player = tree.get_first_node_in_group("player")
			var enemy = tree.get_first_node_in_group("enemy")
			var enemies = tree.get_nodes_in_group("enemy")
			var player_tile = enemy.tilemap.base_layer.local_to_map(player.position)
			var surrounding_tiles = enemy.tilemap.base_layer.get_surrounding_cells(player_tile)
			var aoe_targets: Array[Node]
			for en in enemies:
				var enemy_tile_position = enemy.tilemap.base_layer.local_to_map(en.position)
				if surrounding_tiles.has(enemy_tile_position):
					aoe_targets.append(en)
			return aoe_targets
		_:
			return []


func play(targets: Array[Node], player_stats: PlayerStats, modifiers: ModifierHandler) -> void:
	Events.card_played.emit(self)
	player_stats.energy -= energy_cost

	if is_single_targeted():
		apply_effects(targets, modifiers)
	else:
		apply_effects(_get_targets(targets), modifiers)


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description

func is_card_modified(_player_modifiers: ModifierHandler) -> bool:
	return false

func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass
