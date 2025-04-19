class_name Shop
extends Control

const SHOP_CARD = preload("res://scenes/shop/shop_card.tscn")
const SHOP_RELIC = preload("res://scenes/shop/shop_relic.tscn")

@export var shop_relics: Array[Relic]
@export var player_stats: PlayerStats
@export var run_stats: RunStats
@export var relic_handler: RelicHandler

@onready var cards: HBoxContainer = %Cards
@onready var relics: HBoxContainer = %Relics
@onready var shop_icon_animation: AnimationPlayer = %ShopIconAnimation
@onready var card_popup: CardPopup = %CardPopup
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var item_bought : bool = false


func _ready() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.queue_free()

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.queue_free()

	Events.shop_card_bought.connect(_on_shop_card_bought)
	Events.shop_relic_bought.connect(_on_shop_relic_bought)

	shop_icon_animation.play("pulse")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and card_popup.visible:
		card_popup.hide_popup()


func populate_shop() -> void:
	_generate_shop_cards()
	_generate_shop_relics()


func _generate_shop_cards() -> void:
	var shop_card_array: Array[Card] = []
	var available_cards := player_stats.draftable_cards.duplicate_cards()
	RNG.array_shuffle(available_cards)
	shop_card_array = available_cards.slice(0, 3)

	for card: Card in shop_card_array:
		var new_shop_card := SHOP_CARD.instantiate() as ShopCard
		cards.add_child(new_shop_card)
		new_shop_card.card = card
		new_shop_card.current_card_ui.tooltip_requested.connect(card_popup.show_popup)
		new_shop_card.gold_cost = _get_updated_shop_cost(new_shop_card.gold_cost)
		new_shop_card.update(run_stats)


func _generate_shop_relics() -> void:
	var shop_relics_array: Array[Relic] = []
	var available_relics := shop_relics.filter(
		func(relic: Relic):
			var can_appear := relic.can_appear_as_reward(player_stats)
			var already_had_it := relic_handler.has_relic(relic.id)
			return can_appear and not already_had_it
	)

	RNG.array_shuffle(available_relics)
	shop_relics_array = available_relics.slice(0, 3)

	for relic: Relic in shop_relics_array:
		var new_shop_relic := SHOP_RELIC.instantiate() as ShopRelic
		relics.add_child(new_shop_relic)
		new_shop_relic.relic = relic
		new_shop_relic.resource_cost = _get_updated_shop_cost(new_shop_relic.resource_cost)
		new_shop_relic.update(run_stats)


func _update_items() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.update(run_stats)


func _get_updated_shop_cost(original_cost: int) -> int:
	return modifier_handler.get_modified_value(original_cost, Enums.ModifierType.SHOP_COST)


func _update_item_costs() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.gold_cost = _get_updated_shop_cost(shop_card.gold_cost)
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.resource_cost = _get_updated_shop_cost(shop_relic.resource_cost)
		shop_relic.update(run_stats)


func _on_leave_button_pressed() -> void:
	if !item_bought:
		var event_props := {
			"player_gold": run_stats.gold,
			"player_resources": run_stats.resources
		}
		Talo.events.track("shop_left_empty_handed", event_props)
	Events.shop_exited.emit()


func _on_shop_card_bought(card: Card, gold_cost: int) -> void:
	item_bought = true
	var stat_props := {
		"card" : card.name,
		"cost" : gold_cost
	}
	Talo.events.track("card_bought_in_shop", stat_props)
	Talo.stats.track("cards_purchased")
	player_stats.deck.add_card(card)
	run_stats.gold -= gold_cost
	_update_items()


func _on_shop_relic_bought(relic: Relic, resource_cost: int) -> void:
	item_bought = true
	var stat_props := {
		"relic" : relic.relic_name,
		"cost" : resource_cost
	}
	Talo.events.track("relic_bought_in_shop", stat_props)
	Talo.stats.track("relics_purchased")
	relic_handler.add_relic(relic)
	run_stats.resources -= resource_cost

	if relic is TraderBadgeRelic:
		var traderbadge_props := {
			"cost": resource_cost
		}
		Talo.events.track("traderbadge_bought_in_shop", traderbadge_props)
		Talo.stats.track("traderbadges_bought")
		var discount_relic := relic as TraderBadgeRelic
		discount_relic.add_shop_modifier(self)
		_update_item_costs()
	else:
		_update_items()
