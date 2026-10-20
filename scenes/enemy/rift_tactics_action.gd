extends EnemyAction

const WEAKENED = preload("res://resources/data/statuses/weakened.tres")
const CORRODED = preload("res://resources/data/statuses/corroded.tres")
const ATTACK_ICON = preload("res://assets/rift/ui/attack.svg")
const MOVE_ICON = preload("res://assets/rift/ui/move.svg")
const WARD_ICON = preload("res://assets/rift/ui/block.svg")
const MEND_FX = preload("res://ui/fx/mend_signature.tscn")
const WARD_FX = preload("res://ui/fx/eldritch_barrier_signature.tscn")
const CUT_FX = preload("res://ui/fx/jab_signature.tscn")
const RANGED_FX = preload("res://ui/fx/void_shard_signature.tscn")
const HEX_FX = preload("res://ui/fx/curse_fx.tscn")

func is_performable() -> bool:
	return enemy != null and enemy.stats.tactics != null and target is Player

func _profile() -> EnemyTactics:
	return enemy.stats.tactics

func _in_range(radius: int) -> bool:
	return enemy.tilemap.get_surrounding_tiles_in_radius(enemy.current_tile_position, radius).has(enemy.tilemap.player_position)

func _allies() -> Array[Node]:
	var result: Array[Node] = []
	for other in enemy.get_parent().get_children():
		if other is Enemy and other != enemy and not other.is_dying and other.stats.health > 0:
			if enemy.tilemap.get_surrounding_tiles_in_radius(enemy.current_tile_position, 3).has(other.current_tile_position):
				result.append(other)
	result.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		if _profile().protect_lowest_health:
			return float(a.stats.health) / a.stats.max_health < float(b.stats.health) / b.stats.max_health
		return a.stats.max_health > b.stats.max_health)
	return result

func _support_target() -> Enemy:
	for ally in _allies():
		if _profile().role == EnemyTactics.Role.MENDER and ally.stats.health < ally.stats.max_health:
			return ally
		if _profile().role == EnemyTactics.Role.GUARDIAN and ally.stats.block < _profile().support_amount:
			return ally
	return null

func _plan() -> String:
	var p := _profile()
	if enemy.turn_ticker % p.cadence == 0:
		if p.role in [EnemyTactics.Role.GUARDIAN, EnemyTactics.Role.MENDER] and _support_target():
			return "Mend" if p.role == EnemyTactics.Role.MENDER else "Ward ally"
		if p.role == EnemyTactics.Role.SCAVENGER and enemy.tilemap.get_resource_count(enemy.current_tile_position) > 0:
			return "Consume resource"
	if _in_range(p.preferred_range):
		if p.role == EnemyTactics.Role.NEEDLE and _in_range(maxi(1, p.preferred_range - 2)):
			if enemy.calculate_next_tile_move(p.steps) != MovingEnemy.INVALID_TILE:
				return "Retreat"
		if p.role == EnemyTactics.Role.REAVER and enemy.turn_ticker % p.cadence == 0:
			return "Brace"
		return "Strike"
	return "Advance"

func perform_action() -> void:
	var generation := action_generation
	var p := _profile()
	var plan := _plan()
	match plan:
		"Mend":
			var ally := _support_target()
			if ally:
				ally.stats.heal(p.support_amount)
				_play_mend(ally)
		"Ward ally":
			var ally := _support_target()
			if ally:
				var ward := BlockEffect.new()
				ward.amount = p.support_amount
				ward.visual_fx = WARD_FX
				ward.execute([ally])
		"Consume resource":
			enemy.tilemap.set_resource_count(enemy.current_tile_position, enemy.tilemap.get_resource_count(enemy.current_tile_position) - 1)
			enemy.stats.heal(p.support_amount)
			_play_mend(enemy)
			var block := BlockEffect.new()
			block.amount = p.support_amount
			block.visual_fx = WARD_FX
			block.execute([enemy])
		"Brace":
			var block := BlockEffect.new()
			block.amount = p.support_amount
			block.visual_fx = WARD_FX
			block.execute([enemy])
		"Advance", "Retreat":
			enemy.perform_turn_based_move(p.steps)
			await enemy.movement_finished
			if generation != action_generation:
				return
		"Strike":
			for hit in p.hits:
				if not is_instance_valid(target) or target.stats.health <= 0:
					break
				var damage := DamageEffect.new()
				damage.amount = enemy.modifier_handler.get_modified_value(p.damage, Enums.ModifierType.DMG_DEALT)
				damage.visual_fx = CUT_FX if p.preferred_range <= 1 else RANGED_FX
				damage.execute([target])
				# Resolve each hit separately so block and death are authoritative.
				while is_instance_valid(target) and target.pending_effects > 0:
					await get_tree().process_frame
					if generation != action_generation:
						return
			if p.role == EnemyTactics.Role.SIPHON:
				enemy.stats.heal(p.support_amount)
				_play_mend(enemy)
			if p.role == EnemyTactics.Role.HEXER:
				var effect := StatusEffect.new()
				var status: Status = CORRODED.duplicate() if p.hits > 1 else WEAKENED.duplicate()
				status.duration = p.support_amount
				status.stacks = p.support_amount
				effect.status = status
				effect.visual_fx = HEX_FX
				effect.execute([target])
	Events.enemy_action_completed.emit(enemy)

func _play_mend(recipient: Node2D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var fx := MEND_FX.instantiate() as VisualFX
	recipient.add_child(fx)
	fx.execute()

func update_intent_text() -> void:
	if not is_performable():
		return
	var plan := _plan()
	var p := _profile()
	intent.current_text = plan
	intent.icon = ATTACK_ICON if plan == "Strike" else (MOVE_ICON if plan in ["Advance", "Retreat"] else WARD_ICON)
	if plan == "Strike":
		var amount := enemy.modifier_handler.get_modified_value(p.damage, Enums.ModifierType.DMG_DEALT)
		amount = target.modifier_handler.get_modified_value(amount, Enums.ModifierType.DMG_TAKEN)
		intent.current_text = "%d × %d" % [amount, p.hits]
		intent.tooltip_text = "%s: %d hit(s), range %d. %s" % [enemy.stats.enemy_name, p.hits, p.preferred_range, _role_note()]
	else:
		intent.tooltip_text = "%s: %s. %s" % [enemy.stats.enemy_name, plan, _role_note()]

func _role_note() -> String:
	match _profile().role:
		EnemyTactics.Role.NEEDLE: return "Retreats when crowded; close the gap."
		EnemyTactics.Role.GUARDIAN: return "Wards one ally within three hexes; separate them."
		EnemyTactics.Role.MENDER: return "Heals an injured ally within three hexes; focus targets."
		EnemyTactics.Role.SIPHON: return "Heals after striking; stay outside its reach."
		EnemyTactics.Role.REAVER: return "Alternates bracing and multi-hit pressure."
		EnemyTactics.Role.SCAVENGER: return "Consumes a resource on its tile to heal and block."
		EnemyTactics.Role.HEXER: return "Applies Corroded with multi-hit attacks, otherwise Weakened."
	return "Closes quickly; use terrain and block."
