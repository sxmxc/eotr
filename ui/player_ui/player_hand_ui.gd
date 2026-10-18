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
const SPOTLIGHT_SLOT = preload("res://ui/player_ui/card_spotlight_slot.tscn")

var cards_played_this_turn := 0
var layout_tween: Tween


func _ready() -> void:
	Events.card_played.connect(_on_card_played)
	resized.connect(_update_cards)


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
	_update_cards()
	
func add_card_spotlight(card: Card) -> void:
	if not card_spotlight:
		add_card(card)
		return
	var new_card_ui := card_ui_scene.instantiate() as CardUI
	var spotlight_slot: Control = SPOTLIGHT_SLOT.instantiate()
	card_spotlight.add_child(spotlight_slot)

	spotlight_slot.add_child(new_card_ui)
	new_card_ui.card = card
	new_card_ui.parent = spotlight_slot
	new_card_ui.player_stats = player_stats
	new_card_ui.player_modifiers = player.modifier_handler
	new_card_ui.visuals.card_text_label.text = new_card_ui.get_description()
	new_card_ui.values_modified = new_card_ui.is_values_modified()
	new_card_ui.playable = player_stats.can_play_card(new_card_ui.card)
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

func release_played_card(card_ui: CardUI) -> void:
	# Played cards leave the logical hand before their burn animation. Otherwise a
	# fast end turn can discard an already played card a second time.
	var layer := get_tree().get_first_node_in_group("ui_layer")
	card_ui.reparent(layer if layer else get_tree().root)
	_update_cards()


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
	var count := get_child_count()
	if count == 0:
		return
	if layout_tween and layout_tween.is_valid():
		layout_tween.kill()
	layout_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var width := (get_child(0) as Control).get_combined_minimum_size().x
	var step := minf(width + x_sep, maxf(0.0, size.x - width) / maxf(1.0, count - 1.0))
	var offset := (size.x - width - step * (count - 1)) / 2.0
	for i in count:
		var card := get_child(i) as CardUI
		if not card:
			continue
		var sample := float(i) / float(count - 1) if count > 1 else 0.5
		var y := hand_curve.sample(sample) if hand_curve and count > 1 else 0.0
		var rotation_value := rotation_curve.sample(sample) if rotation_curve and count > 1 else 0.0
		card.original_index = i
		card.z_index = i
		layout_tween.tween_property(card, "position", Vector2(offset + step * i, y_min + y_max * y), 0.18)
		layout_tween.tween_property(card, "rotation_degrees", max_rotation_degrees * rotation_value, 0.18)

func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value


func _on_card_played(card: Card) -> void:
	TelemetryManager.track_event("card_played", {"card_name": card.name, "card_cost": card.last_energy_cost,
		"card_rarity": Enums.CardRarity.keys()[card.card_rarity], "card_type": Enums.CardType.keys()[card.card_type]})
	TelemetryManager.track_stat("cards_played")
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
