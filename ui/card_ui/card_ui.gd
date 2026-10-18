class_name CardUI
extends Control

@warning_ignore("unused_signal")
signal reparent_requested(which_card_ui: CardUI)

const CARD_BURNABLE = preload("res://resources/materials/card_burnable.tres")
const KEYWORD_TOOLTIP_HELPER = preload("res://ui/tool_tip_ui/keyword_tooltip_helper.gd")

@export var player_modifiers: ModifierHandler
@export var card: Card:
	set = _set_card
@export var player_stats: PlayerStats:
	set = _set_player_stats
@export var hover_sound: AudioStream
@export var discard_sound: AudioStream
@export var clicked_sound: AudioStream
@export_group("Inspection and aiming")
@export var inspected_scale := Vector2.ONE
@export var inspected_offset := Vector2.ZERO
@export var inspection_duration := 0.12
@export var aim_bottom_inset := 28.0
@export var aim_cancel_margin := 60.0

@onready var drop_point_detector = $DropPointDetector
@onready var state = $DebugState
@onready var card_state_machine: CardStateMachine = $CardStateMachine
@onready var targets: Array[Node] = []
@onready var visuals: CardVisuals = %Visuals

var hover_tween: Tween
var original_index := 0
var parent: Control
var tween: Tween
var playable := true:
	set = _set_playable
var values_modified := false :
	set = _set_values_modified
var disabled := false
var _hovering := false


func _ready() -> void:
	Events.card_drag_started.connect(_on_card_drag_or_aiming_started)
	Events.card_drag_ended.connect(_on_card_drag_or_aiming_ended)
	Events.card_aim_started.connect(_on_card_drag_or_aiming_started)
	Events.card_aim_ended.connect(_on_card_drag_or_aiming_ended)
	card_state_machine.init(self)
	_refresh_interaction_visuals()


func _input(event):
	card_state_machine.on_input(event)


func animate_to_position(pos: Vector2, duration: float):
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", pos, duration)


func play() -> void:
	if not can_execute(targets):
		return
	var handler := get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if handler:
		handler.resolving_action = true
	disabled = true
	if parent is PlayerHand:
		parent.release_played_card(self)
	await card.play(targets, player_stats, player_modifiers)
	# Damage effects commit through tweens. Wait for their actual gameplay boundary.
	await get_tree().process_frame
	while _has_pending_effects(handler):
		await get_tree().process_frame
	if handler:
		handler.resolving_action = false
	var board := get_tree().get_first_node_in_group("map_layer")
	if board and board.get_parent() is GameWorld:
		board.get_parent().check_victory()
	burn_card()


func _has_pending_effects(handler: PlayerHandler) -> bool:
	if handler and not handler.hand_ready:
		return true
	for enemy: Enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.pending_damage > 0:
			return true
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.pending_effects > 0


func can_execute(selected_targets: Array[Node]) -> bool:
	if not card or disabled or not player_stats or not player_stats.can_play_card(card):
		return false
	var handler := get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if handler and (handler.resolving_action or not handler.hand_ready):
		return false
	if handler and is_instance_valid(handler.player) and handler.player.pending_effects > 0:
		return false
	var board := get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	if board:
		var owner_world := board.get_parent() as GameWorld
		if owner_world and (owner_world.battle_over_handled or owner_world.battle_state.phase != BattleStateController.Phase.PLAYER_TURN):
			return false
	if selected_targets.is_empty():
		return false
	if card.is_single_targeted():
		var target := selected_targets[0]
		if not is_instance_valid(target):
			return false
		var cell: Vector2i
		if target is Enemy:
			if target.is_dying or target.stats.health <= 0:
				return false
			cell = target.current_tile_position
		elif target is TilemapTarget:
			cell = target.tile_position
		else:
			return false
		if not card.get_valid_targets(self, player_modifiers).has(cell) or board.is_tile_behind_fog(cell):
			return false
	return card.is_valid_target(selected_targets, player_modifiers)


func get_active_enemy_modifiers() -> ModifierHandler:
	if targets.is_empty():
		return null
	if not is_instance_valid(targets[0]):
		return null
	elif targets.size() > 1:
		return null
	elif not targets[0] is Enemy:
		
		return null
	return targets[0].modifier_handler

func is_values_modified() -> bool:
	return card.is_card_modified(player_modifiers)

func request_description() -> void:
	if !is_instance_valid(card) or !is_instance_valid(player_modifiers):
		return
	var enemy_modifiers := get_active_enemy_modifiers()
	var modified_description := card.get_modified_description(player_modifiers, enemy_modifiers)
	var keyword_tooltips := KEYWORD_TOOLTIP_HELPER.build_keyword_tooltips(modified_description)
	var overflow := visuals.card_text_label.get_content_height() > visuals.card_text_label.size.y
	var tooltip_data := TooltipData.new(modified_description if overflow else "", keyword_tooltips)
	if keyword_tooltips.is_empty() and not overflow:
		Events.tooltip_hide_requested.emit()
		return
	Events.card_tooltip_requested.emit(tooltip_data)


func get_description() -> String:
	var enemy_modifiers := get_active_enemy_modifiers()
	return card.get_modified_description(player_modifiers, enemy_modifiers)


func burn_card() -> void:
	var world_ui := get_tree().get_first_node_in_group("ui_layer") as CanvasLayer
	var discard_pile_position := Vector2.ZERO
	if world_ui:
		var pile_button: Control = world_ui.exhaust_pile_button if card.exhaust else world_ui.discard_pile_button
		if pile_button:
			discard_pile_position = pile_button.get_global_rect().get_center()
	if discard_pile_position == Vector2.ZERO:
		discard_pile_position = global_position
	var target_offset : Vector2 = Vector2(size.x /2, size.y / 2)
	var center_of_screen = get_viewport().get_visible_rect().size / 2
	if visuals.has_method("set_boosted_effect"):
		visuals.set_boosted_effect(false)
	visuals.card_trail_fx.show()
	visuals.card_trail_fx.emitting = true
	visuals.material = CARD_BURNABLE.duplicate()
	tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	visuals.animation_player.play("swirl_out")
	tween.tween_property(self, "global_position", center_of_screen - target_offset, 0.16)
	tween.tween_property(self, "global_position", discard_pile_position - target_offset, 0.14)
	tween.parallel().tween_property(visuals, "scale", Vector2(0.22, 0.22), 0.14)
	tween.parallel().tween_method(set_burn_shader_parameter, 0.0, 1.6, 0.45)
	tween.tween_callback(_stop_trail_fx)
	tween.tween_callback(queue_free)
	if discard_sound:
		SoundManager.play_ui_sound_random_pitch(discard_sound)


func set_burn_shader_parameter(value: float) -> void:
	if visuals.material:
		visuals.material.set_shader_parameter("radius", value)


func _stop_trail_fx() -> void:
	visuals.card_trail_fx.emitting = false
	visuals.card_trail_fx.hide()


func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	_hovering = true
	if visuals.has_method("set_hover_outline"):
		visuals.set_hover_outline(playable and not disabled)
	card_state_machine.on_mouse_entered()


func _on_mouse_exited() -> void:
	_hovering = false
	if visuals.has_method("set_hover_outline"):
		visuals.set_hover_outline(false)
	card_state_machine.on_mouse_exited()


func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	visuals.player_modifiers = player_modifiers
	visuals.card = value
	_update_cost_label()
	


func _set_playable(value: bool) -> void:
	playable = value
	visuals.card_cost_label.theme_type_variation = &"CardCost" if playable else &"CardCostUnavailable"
	_refresh_interaction_visuals()
		

func _set_values_modified(value: bool) -> void:
	values_modified = value
	if visuals.has_method("set_boosted_effect"):
		visuals.set_boosted_effect(values_modified)

func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value
	player_stats.stats_changed.connect(_on_char_stats_changed)
	_update_cost_label()


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)


func _on_drop_point_detector_area_exited(area):
	targets.erase(area)


func _on_card_drag_or_aiming_started(used_card: CardUI) -> void:
	if used_card == self:
		return
	disabled = true
	_refresh_interaction_visuals()


func _on_card_drag_or_aiming_ended(_card: CardUI) -> void:
	disabled = false
	self.playable = player_stats.can_play_card(card)
	_update_cost_label()
	_refresh_interaction_visuals()


func _on_char_stats_changed() -> void:
	self.playable = player_stats.can_play_card(card)
	visuals.card_text_label.text = get_description()
	values_modified = is_values_modified()
	_update_cost_label()

func _update_cost_label() -> void:
	if not visuals or not card:
		return
	var cost := card.energy_cost
	if is_instance_valid(player_stats):
		cost = card.get_energy_cost(player_stats)
	visuals.set_cost(cost)


func _refresh_interaction_visuals() -> void:
	if not visuals or not visuals.is_node_ready():
		return
	var active := playable and not disabled
	if visuals.has_method("set_interactable"):
		visuals.set_interactable(active)
	if not active and visuals.has_method("set_hover_outline"):
		visuals.set_hover_outline(false)
	elif _hovering and visuals.has_method("set_hover_outline"):
		visuals.set_hover_outline(true)


func set_inspected(inspected: bool, immediate: bool = false) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	var target_scale := inspected_scale if inspected else Vector2.ONE
	var target_position := inspected_offset if inspected else Vector2.ZERO
	if immediate:
		visuals.scale = target_scale
		visuals.position = target_position
		return
	hover_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(visuals, "scale", target_scale, inspection_duration)
	hover_tween.tween_property(visuals, "position", target_position, inspection_duration)
