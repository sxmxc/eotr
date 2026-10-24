extends RiftBoss

const DISCHARGE_SOUND = preload("res://assets/audio/spells/disenchant2.wav")
var discharging := false
var discharge_progress := 0.0

func _process(delta: float) -> void:
	super._process(delta)
	if discharging:
		discharge_progress = minf(discharge_progress + delta / maxf(Utils.presentation_duration(0.3), 0.01), 1.0)
var relays: Array[Enemy] = []
var active_relay: Enemy
var relay_cursor := -1
var had_link := false
var transferred_totals: Dictionary[Enemy, int] = {}

func _ready() -> void:
	super._ready()
	Events.enemy_died.connect(_relay_died)

func prepare_signature() -> void:
	if relays.is_empty():
		for child: Enemy in get_parent().get_children():
			if child is Enemy and child != self:
				relays.append(child)
				transferred_totals[child] = child.stats.total_health_damage
				child.damage_taken.connect(_relay_hit.bind(child))
	active_relay = null
	for step in relays.size():
		relay_cursor = (relay_cursor + 1) % relays.size()
		var relay := relays[relay_cursor]
		if is_instance_valid(relay) and not relay.is_dying and relay.stats.health > 0:
			active_relay = relay
			break
	had_link = is_instance_valid(active_relay)
	_refresh_caption()

func _refresh_caption() -> void:
	if is_instance_valid(active_relay) and active_relay.stats.health > 0:
		boss_caption = "LIVE CIRCUIT: %s. Its health damage also hits the core. Destroy it to cancel Discharge 9." % active_relay.stats.enemy_name
	elif had_link:
		boss_caption = "CIRCUIT BROKEN - discharge cancelled. Next relay lights next turn."
	else:
		boss_caption = "CORE EXPOSED - Discharge 4. No relays remain."

func _has_relays() -> bool:
	for relay in relays:
		if is_instance_valid(relay) and not relay.is_dying and relay.stats.health > 0:
			return true
	return false

func _relay_hit(_amount: int, relay: Enemy) -> void:
	var total := relay.stats.total_health_damage
	var actual := total - int(transferred_totals.get(relay, 0))
	transferred_totals[relay] = total
	if relay == active_relay and actual > 0 and not is_dying and not encounter_finished:
		take_damage(actual, Enums.ModifierType.NO_MODIFIER, true)
		feedback = 1.0
	_refresh_caption()
	update_intent()

func _relay_died(_relay: Enemy) -> void:
	_refresh_caption()
	update_intent()

func describe_boss_intent(plan: Intent) -> void:
	plan.current_text = "Discharge 9" if is_instance_valid(active_relay) and active_relay.stats.health > 0 else ("Interrupted" if had_link else "Discharge 4")
	plan.detail_text = boss_caption

func get_boss_summary() -> String:
	if is_instance_valid(active_relay) and active_relay.stats.health > 0:
		return "LIVE: %s / DISCHARGE 9 / Break this relay to interrupt." % active_relay.stats.enemy_name
	return "CIRCUIT BROKEN: discharge interrupted this turn." if had_link else "UNBOUND CORE: Discharge 4. No relays remain."

func perform_boss_turn(action: EnemyAction, generation: int) -> void:
	var live := is_instance_valid(active_relay) and active_relay.stats.health > 0 and not active_relay.is_dying
	if had_link and not live:
		return
	feedback = 1.0
	present_attack("windup")
	discharging = true
	discharge_progress = 0.0
	await get_tree().create_timer(Utils.presentation_duration(0.3)).timeout
	discharging = false
	if action_is_live(action, generation):
		present_attack("release")
		strike_player(9 if live else 4, DISCHARGE_SOUND)

func _draw() -> void:
	super._draw()
	if not is_instance_valid(tilemap) or is_dying or encounter_finished:
		return
	if discharging and is_instance_valid(tilemap.player):
		var origin := to_local(active_relay.global_position) if is_instance_valid(active_relay) else Vector2(0, -24)
		var destination := to_local(tilemap.player.global_position) + Vector2(0, -20)
		var tip := origin.lerp(destination, discharge_progress * discharge_progress)
		var direction := (destination - origin).normalized()
		var side := direction.orthogonal() * 8.0
		draw_colored_polygon(PackedVector2Array([tip + direction * 16, tip + side, tip - direction * 18, tip - side]), Color(0.9, 0.82, 1.0, 0.9))
	for relay in relays:
		if not is_instance_valid(relay) or relay.is_dying or relay.stats.health <= 0 or not tilemap.is_within_bounds(relay.current_tile_position):
			continue
		var lit := relay == active_relay
		var color := Color(0.85, 0.77, 1.0, 0.9) if lit else Color(0.4, 0.5, 0.6, 0.45)
		var at := to_local(relay.global_position)
		var diamond := PackedVector2Array([at + Vector2(0, -48), at + Vector2(22, -20), at + Vector2(0, 4), at + Vector2(-22, -20)])
		draw_colored_polygon(diamond, Color(color, 0.2 if lit else 0.07))
		diamond.append(diamond[0])
		draw_polyline(diamond, color, 2.0, true)
		if lit:
			var direction := at.normalized()
			var side := direction.orthogonal() * (2.0 + feedback * 4.0)
			draw_colored_polygon(PackedVector2Array([direction * 24, at + side, at - side]), Color(0.72, 0.65, 1.0, 0.22))
