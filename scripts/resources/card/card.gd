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
@export var tags: Array[String] = []
var last_energy_cost: int = 0

@export_group("Card Effects")
@export var effect_configs: Array[CardEffectConfig] = []

@export_group("Card Sound and Visuals")
@export var card_art: Texture2D
@export var sound_fx: AudioStream
@export var visual_fx: PackedScene
@export var projectile_fx: PackedScene
@export var cast_fx: PackedScene


func is_single_targeted() -> bool:
	return (
		target_type == Enums.TargetType.SINGLE_ENEMY
		or target_type == Enums.TargetType.SINGLE_TILE
		or target_type == Enums.TargetType.ADJACENT_ENEMY
		or target_type == Enums.TargetType.ALLY
	)


func is_valid_target(_targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	return true


func _get_targets(targets: Array[Node]) -> Array[Node]:
	if not targets:
		return []
	var tree := targets[0].get_tree() as SceneTree
	var tilemap := tree.get_first_node_in_group("map_layer")

	match target_type:
		Enums.TargetType.SELF:
			return tree.get_nodes_in_group("player")
		Enums.TargetType.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemy")
		Enums.TargetType.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemy")
		Enums.TargetType.SURROUNDING_ENEMIES:
			var player_tile = tilemap.player_position
			var surrounding_tiles = tilemap.base_layer.get_surrounding_cells(player_tile)
			var aoe_targets: Array[Node] = []
			for enemy: Enemy in tree.get_nodes_in_group("enemy"):
				if enemy.intersects_tiles(surrounding_tiles, true):
					aoe_targets.append(enemy)
			return aoe_targets
		_:
			return []


func play(targets: Array[Node], player_stats: PlayerStats, modifiers: ModifierHandler) -> void:
	_sync_effect_configs()
	var cost := get_energy_cost(player_stats)
	last_energy_cost = cost
	player_stats.energy -= cost
	Events.card_played.emit(self)

	var resolved_targets := targets
	if not is_single_targeted():
		resolved_targets = _get_targets(targets)
	await resolve_effects(resolved_targets, player_stats, modifiers)


func resolve_effects(resolved_targets: Array[Node], player_stats: PlayerStats, modifiers: ModifierHandler) -> void:
	if modifiers and is_single_targeted():
		var caster := modifiers.get_tree().get_first_node_in_group("player") as Player
		if is_instance_valid(caster):
			for target: Node in resolved_targets:
				if target is TilemapTarget:
					caster.face_target(target.tilemap.cell_to_world(target.tile_position))
					break
				if target is Node2D and target != caster:
					caster.face_target(target.global_position)
					break
	if cast_fx and DisplayServer.get_name() != "headless" and modifiers:
		var player := modifiers.get_tree().get_first_node_in_group("player") as Player
		if is_instance_valid(player):
			var feedback := cast_fx.instantiate() as VisualFX
			player.add_child(feedback)
			feedback.execute()

	if not effect_configs.is_empty():
		var resolver := CardResolver.new()
		await resolver.resolve(self, resolved_targets, player_stats, modifiers, effect_configs)
	else:
		# Legacy card overrides may yield even though the base hook is synchronous.
		@warning_ignore("redundant_await")
		await apply_effects(resolved_targets, modifiers)


func get_default_description() -> String:
	return description


func get_modified_description(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> String:
	for config in effect_configs:
		if config.effect_type in [CardEffectConfig.EffectType.DAMAGE, CardEffectConfig.EffectType.MULTI_DAMAGE]:
			return description.replace("Deal %d" % config.amount, "Deal %d" % config.get_preview_amount(player_modifiers, enemy_modifiers))
	return description


func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	for config in effect_configs:
		if config.effect_type in [CardEffectConfig.EffectType.DAMAGE, CardEffectConfig.EffectType.MULTI_DAMAGE] and config.get_effect_amount(player_modifiers) != config.amount:
			return true
	return false


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func get_energy_cost(_player_stats: PlayerStats) -> int:
	return energy_cost


func get_valid_targets(card_ui: CardUI, _modifiers: ModifierHandler) -> Array[Vector2i]:
	var tree := card_ui.get_tree() as SceneTree
	var tilemap := tree.get_first_node_in_group("map_layer") as ProcGenTilemap
	if not tilemap:
		return []
	var enemies: Array[Enemy] = []
	for node in tree.get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy:
			enemies.append(enemy)
	
	match target_type:
		Enums.TargetType.ALLY:
			var cells: Array[Vector2i] = []
			var world := tilemap.get_parent() as GameWorld
			if world:
				for unit in world.summons.living(): cells.append(unit.current_tile_position)
			return cells
		Enums.TargetType.SINGLE_TILE:
			return tilemap.base_layer.get_used_cells()
		Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.ALL_ENEMIES:
			var tiles: Array[Vector2i] = []
			for enemy: Enemy in enemies:
				tiles.append_array(enemy.visible_tiles())
			return tiles
		Enums.TargetType.SELF:
			var tile_pos = tilemap.player_position
			return [tile_pos]
		Enums.TargetType.EVERYONE:
			var tiles_all: Array[Vector2i] = []
			for enemy: Enemy in enemies:
				tiles_all.append_array(enemy.visible_tiles())
			tiles_all.append(tilemap.player_position)
			return tiles_all
		Enums.TargetType.SURROUNDING_ENEMIES, Enums.TargetType.ADJACENT_ENEMY:
			var player_tile = tilemap.player_position
			var surrounding_tiles = tilemap.base_layer.get_surrounding_cells(player_tile)
			var aoe_targets: Array[Vector2i] = []
			for enemy: Enemy in enemies:
				if enemy.intersects_tiles(surrounding_tiles, true):
					for cell in enemy.visible_tiles():
						if surrounding_tiles.has(cell):
							aoe_targets.append(cell)
			return aoe_targets
		_:
			return []


func _sync_effect_configs() -> void:
	for config in effect_configs:
		CardEffectConfigHelper.apply_card_defaults(self, config, config.attach_visual_to_effect)
