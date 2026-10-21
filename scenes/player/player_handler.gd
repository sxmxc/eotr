class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.12
const HAND_DISCARD_INTERVAL := 0.08
const HEX_TRAIL = preload("res://ui/player_ui/hex_trail.tscn")
const OBELISK_ENERGY_BONUS := 1
const MOMENTUM_FLOW_LABEL := "Momentum Flow"
const ADAPTIVE_SURGE_LABEL := "Adaptive Surge"
const MANA_WELL_LABEL := "Mana Well Resonance"
const OBELISK_FOCUS_LABEL := "Obelisk Focus"

@export var relics: RelicHandler
@export var player: Player
@export var player_hand: PlayerHand
@export var tilemap: ProcGenTilemap

var player_stats: PlayerStats
var card_types_played: Array[Enums.CardType] = []
var player_turn_count := 0
var free_movement_refund_available := false
var obelisk_first_hit_awarded := false
var obelisk: Obelisk
var resolving_action := false
var hand_ready := false
var _draw_tween: Tween


func _ready() -> void:
	if not LimboConsole.has_command("draw_card"):
		LimboConsole.register_command(draw_card, "draw_card", "Draw card from deck")
	Events.card_played.connect(_on_card_played)
	Events.obelisk_destroyed.connect(_on_obelisk_destroyed)
	if is_instance_valid(player):
		player.tree_exiting.connect(_cancel_draw)
	#Events.player_moved.connect(_on_player_moved)


func _exit_tree() -> void:
	_cancel_draw()


func _cancel_draw() -> void:
	if _draw_tween and _draw_tween.is_valid():
		_draw_tween.kill()
	_draw_tween = null
	hand_ready = false


func cancel_turn() -> void:
	_cancel_draw()
	if is_instance_valid(player_hand):
		player_hand.disable_hand()
	if is_instance_valid(player):
		if is_instance_valid(player.status_handler):
			player.status_handler.cancel_application()
		if is_instance_valid(player.phantom_camera_2d):
			player.phantom_camera_2d.priority = 0
	if is_instance_valid(relics):
		relics.cancel_activation()


func _can_draw() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() \
		and is_instance_valid(player) and not player.is_queued_for_deletion() \
		and player.is_inside_tree() and player.stats != null and player.stats.health > 0 \
		and player_stats != null and is_instance_valid(player_hand) \
		and not player_hand.is_queued_for_deletion() and player_hand.is_inside_tree()


func start_battle(stats: PlayerStats) -> void:
	player_stats = stats
	player_stats.draw_pile = player_stats.deck.deep_duplicate()
	player_stats.draw_pile.shuffle()
	player_stats.discard = CardPile.new()
	player_stats.exhaust_pile = CardPile.new()
	player_turn_count = 0
	free_movement_refund_available = false
	obelisk_first_hit_awarded = false
	_disconnect_obelisk_signal()
	call_deferred("_connect_obelisk_bonus")
	relics.relics_activated.connect(_on_relics_activated)
	player.status_handler.statuses_applied.connect(_on_statuses_applied)
	player.status_handler.status_added.connect(player_hand._on_status_added)
	_configure_player_camera_targets()
	start_turn()


func start_turn() -> void:
	hand_ready = false
	card_types_played = []
	if !is_instance_valid(player):
		return
	player_turn_count += 1
	Events.player_turn_started.emit()
	print("Starting player turn %d" % player_turn_count)
	free_movement_refund_available = true
	obelisk_first_hit_awarded = false
	player.phantom_camera_2d.priority = 20
	player_stats.block = 0
	player_stats.reset_energy()
	var pending_start_tile_effects := tilemap and tilemap.has_start_tile_effects_pending()
	if tilemap.is_tile_mana_well(tilemap.player_position) and not pending_start_tile_effects:
		_grant_energy_bonus(1, MANA_WELL_LABEL)
	if _is_riftwalker() and player_turn_count % 3 == 0:
		_grant_energy_bonus(1, ADAPTIVE_SURGE_LABEL)

	TelemetryManager.track_event("player_turn_started", {
		"turn_number": player_turn_count, "player_class": player_stats.player_class_name,
		"energy": player_stats.energy, "health": player_stats.health})
	relics.activate_relics_by_type(Enums.RelicType.START_OF_TURN)


func end_turn() -> void:
	hand_ready = false
	player_hand.disable_hand()
	relics.activate_relics_by_type(Enums.RelicType.END_OF_TURN)
	Events.enemy_info_hide_requested.emit()
	player.phantom_camera_2d.priority = 0


func draw_card() -> void:
	if not _can_draw():
		_cancel_draw()
		return
	reshuffle_deck_from_discard()
	if player_stats.draw_pile.is_empty():
		return
	player_hand.add_card(player_stats.draw_pile.draw_card())
	reshuffle_deck_from_discard()


func draw_cards(amount: int) -> void:
	_cancel_draw()
	if not _can_draw():
		return
	if amount <= 0:
		hand_ready = true
		Events.player_hand_drawn.emit()
		return
	_draw_tween = create_tween()
	for i in range(amount):
		_draw_tween.tween_callback(draw_card)
		_draw_tween.tween_interval(Utils.presentation_duration(HAND_DRAW_INTERVAL))

	_draw_tween.finished.connect(func():
		_draw_tween = null
		if not _can_draw():
			return
		hand_ready = true
		Events.player_hand_drawn.emit())


func discard_cards() -> void:
	if player_hand.get_cards().size() == 0:
		Events.player_hand_discarded.emit()
		return
	
	var world_ui : CanvasLayer = get_tree().get_first_node_in_group("ui_layer")
	var discard_button: Control = null
	if world_ui:
		var candidate: Variant = world_ui.get("discard_pile_button")
		if candidate is Control:
			discard_button = candidate
	var discard_pile_position: Vector2 = Vector2.ZERO
	if discard_button:
		discard_pile_position = discard_button.get_global_rect().get_center()
	
	if player_hand.layout_tween and player_hand.layout_tween.is_valid():
		player_hand.layout_tween.kill()
	for card_ui: CardUI in player_hand.get_cards():
		# Animations can be interrupted; commit pile changes before advancing.
		var exhaust := card_ui.card.exhaust
		if exhaust:
			player_stats.exhaust_pile.add_card(card_ui.card)
		else:
			player_stats.discard.add_card(card_ui.card)
		card_ui.disabled = true
		if world_ui:
			card_ui.reparent(world_ui)
		else:
			card_ui.reparent(self)
		var card_ui_offset = Vector2(card_ui.global_position.x, card_ui.global_position.y - 100)
		card_ui.visuals.card_trail_fx.emitting = true
		card_ui.z_index += 1
		var tween := card_ui.create_tween()
		card_ui.set_inspected(false, true)
		card_ui.visuals.animation_player.play("swirl_out")
		tween.tween_property(card_ui,"global_position", card_ui_offset,.08)
		var target_position: Vector2 = discard_pile_position if discard_pile_position != Vector2.ZERO else card_ui_offset
		if exhaust and world_ui:
			var exhaust_button: Variant = world_ui.get("exhaust_pile_button")
			if exhaust_button is Control:
				target_position = exhaust_button.get_global_rect().get_center()
		tween.tween_property(card_ui,"global_position", target_position,.1)
		tween.parallel().tween_property(card_ui, "scale", Vector2.ZERO, Utils.presentation_duration(.12))
		tween.tween_callback(player_hand.discard_card.bind(card_ui))
	Events.player_hand_discarded.emit()


func reshuffle_deck_from_discard() -> void:
	if not player_stats.draw_pile.is_empty():
		return
	
	var world_ui := get_tree().get_first_node_in_group("ui_layer") as CanvasLayer

	while not player_stats.discard.is_empty():
		player_stats.draw_pile.add_card(player_stats.discard.draw_card())
		var hex_trail = HEX_TRAIL.instantiate()
		var tween = create_tween()
		if world_ui and world_ui.discard_pile_button and world_ui.draw_pile_button:
			var discard_pile_button: Control = world_ui.discard_pile_button
			var draw_pile_button: Control = world_ui.draw_pile_button
			discard_pile_button.add_child(hex_trail)
			hex_trail.global_position = discard_pile_button.get_global_rect().get_center()
			tween.tween_property(hex_trail, "global_position", draw_pile_button.get_global_rect().get_center(), Utils.presentation_duration(0.3))
		tween.tween_callback(hex_trail.queue_free)		

	player_stats.draw_pile.shuffle()
			
func _connect_obelisk_bonus() -> void:
	if not is_inside_tree():
		return
	var current_obelisk := get_tree().get_first_node_in_group("obelisk") as Obelisk
	if not current_obelisk:
		return
	obelisk = current_obelisk
	if not obelisk.damage_taken.is_connected(_on_obelisk_damage_taken):
		obelisk.damage_taken.connect(_on_obelisk_damage_taken)
	_configure_player_camera_targets()


func _disconnect_obelisk_signal() -> void:
	if obelisk and is_instance_valid(obelisk) and obelisk.damage_taken.is_connected(_on_obelisk_damage_taken):
		obelisk.damage_taken.disconnect(_on_obelisk_damage_taken)
	obelisk = null
	


func _on_obelisk_destroyed() -> void:
	_disconnect_obelisk_signal()
	


func _on_obelisk_damage_taken(amount: int) -> void:
	if amount <= 0:
		return
	if obelisk_first_hit_awarded:
		return
	if player_turn_count <= 0:
		return
	obelisk_first_hit_awarded = true
	_grant_energy_bonus(OBELISK_ENERGY_BONUS, OBELISK_FOCUS_LABEL)


func _grant_energy_bonus(amount: int, label: String) -> void:
	if amount <= 0:
		return
	if not player_stats:
		return
	player_stats.energy += amount
	var world_message := WorldMessageData.new("%s: +%s energy" % [label, amount], WorldMessageData.Priority.ROUTINE)
	Events.world_message_requested.emit(world_message)


func _refund_movement_energy(card: Card) -> void:
	if not free_movement_refund_available:
		return
	free_movement_refund_available = false
	var cost := card.last_energy_cost
	if cost <= 0:
		return
	_grant_energy_bonus(cost, MOMENTUM_FLOW_LABEL)


func _is_riftwalker() -> bool:
	return player_stats and player_stats.player_class_name == "Riftwalker"


func _on_card_played(card: Card) -> void:
	if not card_types_played.has(card.card_type):
		card_types_played.append(card.card_type)
	if card.card_type == Enums.CardType.MOVEMENT:
		_refund_movement_energy(card)
	if card.exhaust or card.card_type == Enums.CardType.POWER:
		player_stats.exhaust_pile.add_card(card)
		return

	player_stats.discard.add_card(card)


func _on_statuses_applied(type: Enums.StatusType) -> void:
	match type:
		Enums.StatusType.START_OF_TURN:
			draw_cards(player_stats.cards_per_turn)
		Enums.StatusType.END_OF_TURN:
			discard_cards()


func _on_relics_activated(type: Enums.RelicType) -> void:
	match type:
		Enums.RelicType.START_OF_TURN:
			player.status_handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
		Enums.RelicType.END_OF_TURN:
			player.status_handler.apply_statuses_by_type(Enums.StatusType.END_OF_TURN)


func _configure_player_camera_targets() -> void:
	if not is_instance_valid(player) or not is_instance_valid(player.phantom_camera_2d):
		return

	var targets: Array[Node2D] = [player]
	obelisk = get_tree().get_first_node_in_group("obelisk") as Obelisk
	if obelisk and is_instance_valid(obelisk):
		targets.append(obelisk)
	
	print("Configuring player camera targets: %s" % [targets])

	player.phantom_camera_2d.follow_mode = PhantomCamera2D.FollowMode.GROUP
	player.phantom_camera_2d.set_follow_targets(targets)
	player.phantom_camera_2d.set_auto_zoom(true)

	print("Player camera targets configured: %s" % [player.phantom_camera_2d.get_follow_targets()])
