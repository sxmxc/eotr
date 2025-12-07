extends Control
class_name PlayerHand

@export var player: Player
@export var player_stats: PlayerStats:
	set = _set_player_stats
	
@export var hand_curve: Curve
@export var rotation_curve: Curve

@export var max_rotation_degrees := 5
@export var x_sep := -10
@export var y_min := 0
@export var y_max := -15

@export var card_spotlight : HBoxContainer


@onready var card_ui_scene = preload("res://ui/card_ui/card_ui.tscn")

var cards_played_this_turn := 0


func _ready() -> void:
	Events.card_played.connect(_on_card_played)


func add_card(card: Card) -> void:
	var new_card_ui := card_ui_scene.instantiate() as CardUI
	new_card_ui.original_index = get_child_count()

	add_child(new_card_ui)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.parent = self
	new_card_ui.player_stats = player_stats
	new_card_ui.player_modifiers = player.modifier_handler
	new_card_ui.visuals.card_text_label.text = new_card_ui.get_description()
	new_card_ui.values_modified = new_card_ui.is_values_modified()
	new_card_ui.playable = player_stats.can_play_card(new_card_ui.card)
	new_card_ui.size = CardUI.CARD_UI_SIZE
	_update_cards()
	
func add_card_spotlight(card: Card) -> void:
	var new_card_ui := card_ui_scene.instantiate() as CardUI
	var spotlight_slot := Control.new()

	spotlight_slot.custom_minimum_size = CardUI.CARD_UI_SIZE
	spotlight_slot.size = CardUI.CARD_UI_SIZE
	spotlight_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_spotlight.add_child(spotlight_slot)

	spotlight_slot.add_child(new_card_ui)
	new_card_ui.position = Vector2.ZERO
	new_card_ui.card = card
	new_card_ui.parent = spotlight_slot
	new_card_ui.player_stats = player_stats
	new_card_ui.player_modifiers = player.modifier_handler
	new_card_ui.visuals.card_text_label.text = new_card_ui.get_description()
	new_card_ui.values_modified = new_card_ui.is_values_modified()
	new_card_ui.playable = player_stats.can_play_card(new_card_ui.card)
	new_card_ui.size = CardUI.CARD_UI_SIZE
	await get_tree().create_timer(1).timeout
	var tween = create_tween()
	var target_position := new_card_ui.position - Vector2(0, new_card_ui.size.y)
	tween.tween_property(new_card_ui, "position", target_position, 0.3)
	await tween.finished

	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.original_index = get_child_count()
	new_card_ui.reparent(self)
	new_card_ui.parent = self
	spotlight_slot.queue_free()
	_update_cards()


func get_cards() -> Array:
	return get_children()


func discard_card(card: CardUI) -> void:
	if card.reparent_requested.is_connected(_on_card_ui_reparent_requested):
		card.reparent_requested.disconnect(_on_card_ui_reparent_requested)
	card.reparent(get_tree().root)
	card.queue_free()
	_update_cards()


func disable_hand() -> void:
	for card: CardUI in get_children():
		card.disabled = true

func _update_cards() -> void:
	var card_count : int = get_child_count()
	var all_cards_size := CardUI.CARD_UI_SIZE.x * card_count + x_sep * (card_count-1)
	var final_x_sep : float = x_sep
	
	if all_cards_size > size.x:
		final_x_sep = (size.x - CardUI.CARD_UI_SIZE.x * card_count) / (card_count - 1)
		all_cards_size = size.x
		
	var offset := (size.x - all_cards_size) / 2
	
	for i in card_count:
		var card := get_child(i)
		var y_multiplier := hand_curve.sample(1.0 / (card_count-1) * i)
		var rot_multiplier := rotation_curve.sample(1.0 / (card_count-1) * i)
		
		if card_count == 1:
			y_multiplier = 0.0
			rot_multiplier = 0.0
			
		var final_x : float = offset + CardUI.CARD_UI_SIZE.x * i + final_x_sep * i
		var final_y : float = y_min + y_max * y_multiplier
		
		card.position = Vector2(final_x, final_y)
		card.rotation_degrees = max_rotation_degrees * rot_multiplier

func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value


func _on_card_played(card: Card) -> void:
	var event_props:= {
		"card_name" : card.name,
		"card_cost" : card.last_energy_cost,
		"card_rarity" : Enums.CardRarity.keys()[card.card_rarity],
		"card_type": Enums.CardType.keys()[card.card_type]
	}
	Talo.events.track("card_played", event_props)
	Talo.stats.track("cards_played")
	cards_played_this_turn += 1
	_update_cards()

func _on_status_added() -> void:
	player_stats.stats_changed.emit()
	_update_cards()

func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	if child.get_parent() != self:
		child.reparent(self)

	var max_index: int = max(get_child_count() - 1, 0)
	var new_index := clampi(child.original_index, 0, max_index)
	if child.get_index() != new_index:
		move_child(child, new_index)

	child.set_deferred("disabled", false)
	_update_cards()
