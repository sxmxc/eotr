class_name CardUI
extends Control

const CARD_UI_SIZE := Vector2(180,240)

@warning_ignore("unused_signal")
signal reparent_requested(which_card_ui: CardUI)

const CARD_BURNABLE = preload("res://resources/materials/card_burnable.tres")
const COST_FONT_COLOR_WHITE = Color(0.824, 0.788, 0.647)
const COST_FONT_COLOR_RED = Color(0.682, 0.365, 0.251)
const KEYWORD_TOOLTIP_HELPER = preload("res://ui/tool_tip_ui/keyword_tooltip_helper.gd")

@export var player_modifiers: ModifierHandler
@export var card: Card:
	set = _set_card
@export var player_stats: PlayerStats:
	set = _set_player_stats
@export var hover_sound: AudioStream
@export var discard_sound: AudioStream
@export var clicked_sound: AudioStream

@onready var drop_point_detector = $DropPointDetector
@onready var state = $DebugState
@onready var card_state_machine: CardStateMachine = $CardStateMachine
@onready var targets: Array[Node] = []
@onready var visuals: CardVisuals = %Visuals

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
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", pos, duration)


func play() -> void:
	if not card:
		return

	card.play(targets, player_stats, player_modifiers)
	burn_card()


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
	var tooltip_data := TooltipData.new(modified_description, keyword_tooltips)
	Events.card_tooltip_requested.emit(tooltip_data)


func get_description() -> String:
	var enemy_modifiers := get_active_enemy_modifiers()
	return card.get_modified_description(player_modifiers, enemy_modifiers)


func burn_card() -> void:
	var world_ui :GameWorldUI = get_tree().get_first_node_in_group("ui_layer")
	
	var target_offset : Vector2 = Vector2(size.x /2, size.y / 2)
	var discard_pile_position = Vector2(
		world_ui.discard_pile_button.global_position.x + world_ui.discard_pile_button.size.x / 2, 
		world_ui.discard_pile_button.global_position.y + world_ui.discard_pile_button.size.y / 2
		)
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
	if not playable:
		visuals.card_cost_label.add_theme_color_override("font_color", Color.RED)
	else:
		visuals.card_cost_label.add_theme_color_override("font_color", COST_FONT_COLOR_WHITE)
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
