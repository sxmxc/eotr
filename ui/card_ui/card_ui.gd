class_name CardUI
extends Control

const CARD_UI_SIZE := Vector2(180,240)

@warning_ignore("unused_signal")
signal reparent_requested(which_card_ui: CardUI)

const STYLE_BASE = preload("res://resources/themes/card_panel_base.tres")
const STYLE_DRAGGING = preload("res://resources/themes/card_panel_dragging.tres")
const STYLE_HOVER = preload("res://resources/themes/card_panel_hover.tres")
const CARD_BURNABLE = preload("res://resources/materials/card_burnable.tres")
const COST_FONT_COLOR_WHITE = Color(0.824, 0.788, 0.647)
const COST_FONT_COLOR_RED = Color(0.682, 0.365, 0.251)

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


func _ready() -> void:
	Events.card_drag_started.connect(_on_card_drag_or_aiming_started)
	Events.card_drag_ended.connect(_on_card_drag_or_aiming_ended)
	Events.card_aim_started.connect(_on_card_drag_or_aiming_started)
	Events.card_aim_ended.connect(_on_card_drag_or_aiming_ended)
	card_state_machine.init(self)


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
	var enemy_modifiers := get_active_enemy_modifiers()
	var modified_description := card.get_modified_description(player_modifiers, enemy_modifiers)
	var tooltip_data := TooltipData.new(modified_description)
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
	visuals.card_boosted_effect.hide()
	visuals.card_attention_fx.hide()
	visuals.card_trail_fx.show()
	visuals.card_trail_fx.emitting = true
	visuals.material = CARD_BURNABLE.duplicate()
	tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	visuals.animation_player.play("swirl_out")
	tween.tween_property(self, "global_position", center_of_screen - target_offset, .25)
	tween.tween_property(self, "global_position", discard_pile_position - target_offset, .12)
	tween.parallel().tween_property(visuals, "scale", Vector2(.25,.25), .12)
	tween.tween_callback(visuals.card_trail_fx.hide)
	tween.tween_method(set_burn_shader_parameter, 0.0, 2.0, 1.5)
	tween.tween_callback(queue_free)
	SoundManager.play_sound_random_pitch(discard_sound)


func set_burn_shader_parameter(value: float) -> void:
	if visuals.material:
		visuals.material.set_shader_parameter("radius", value)


func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()


func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()


func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	visuals.player_modifiers = player_modifiers
	visuals.card = value
	


func _set_playable(value: bool) -> void:
	playable = value
	if not playable:
		visuals.card_cost_label.add_theme_color_override("font_color", Color.RED)
		visuals.card_attention_fx.hide()
		visuals.card_attention_fx.emitting = false
	else:
		visuals.card_cost_label.add_theme_color_override("font_color", COST_FONT_COLOR_WHITE)
		visuals.card_attention_fx.emitting = true
		visuals.card_attention_fx.show()
		

func _set_values_modified(value: bool) -> void:
	values_modified = value
	if not values_modified:
		visuals.card_boosted_effect.hide()
	else:
		visuals.card_boosted_effect.show()

func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value
	player_stats.stats_changed.connect(_on_char_stats_changed)


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)


func _on_drop_point_detector_area_exited(area):
	targets.erase(area)


func _on_card_drag_or_aiming_started(used_card: CardUI) -> void:
	if used_card == self:
		return
	visuals.card_attention_fx.hide()
	disabled = true


func _on_card_drag_or_aiming_ended(_card: CardUI) -> void:
	disabled = false
	self.playable = player_stats.can_play_card(card)


func _on_char_stats_changed() -> void:
	self.playable = player_stats.can_play_card(card)
	visuals.card_text_label.text = get_description()
	values_modified = is_values_modified()
