class_name ConstructSummonCard
extends Card
## Shared summon behavior: legal deployment and the existing fabrication discount.
@export var construct: ConstructDefinition

func _sync_effect_configs() -> void:
	if effect_configs.is_empty():
		var summon := CardEffectConfig.new()
		summon.effect_type = CardEffectConfig.EffectType.SUMMON
		effect_configs = [summon]
	for effect in effect_configs:
		if effect.effect_type == CardEffectConfig.EffectType.SUMMON:
			effect.construct = construct
	super._sync_effect_configs()

func get_energy_cost(stats: PlayerStats) -> int:
	return maxi(0, energy_cost - (1 if stats and stats.fabrication_discount else 0))

func play(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	await super.play(targets, stats, modifiers)
	stats.fabrication_discount = false

func get_valid_targets(ui: CardUI, _modifiers: ModifierHandler) -> Array[Vector2i]:
	var world := ui.get_battle_world()
	if not world:
		return []
	var board := world.tilemap
	var cells: Array[Vector2i] = []
	for cell in board.get_surrounding_tiles_in_radius(board.player_position, 2):
		if world.summons.can_deploy(cell): cells.append(cell)
	return cells

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	if targets.is_empty() or not targets[0] is TilemapTarget: return false
	var tile := targets[0] as TilemapTarget
	var world := tile.tilemap.get_parent() as GameWorld
	return world != null and world.summons.can_deploy(tile.tile_position)
