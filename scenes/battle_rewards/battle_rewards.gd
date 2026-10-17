class_name BattleRewards
extends Control

const REWARD_BUTTON := preload("res://scenes/battle_rewards/reward_button.tscn")
const GOLD_ICON := preload("res://assets/icons/two-coins.svg")
const GOLD_TEXT := "%s gold"
const RESOURCE_ICON := preload("res://assets/icons/metal-bar-fg-only.svg")
const RESOURCE_TEXT := "%s resources"
const CARD_ICON = preload("res://assets/icons/card-random.svg")
const CARD_TEXT = "New Card"
const CARD_REWARD_SCENE = preload("res://scenes/battle_rewards/card_rewards.tscn")

@export var run_stats: RunStats
@export var player_stats: PlayerStats
@export var relic_handler: RelicHandler
@export var card_registry: CardRegistry
@export var card_reward_tags: Array[String] = []

@onready var rewards: VBoxContainer = %Rewards
@onready var enemy_rewards: VBoxContainer = %EnemyRewards
@onready var ui_layer: CanvasLayer = $UILayer
@onready var reward_label: Label = %RewardLabel
@onready var enemy_reward_label: Label = %EnemyRewardLabel
@onready var empty_label: Label = %EmptyLabel

var card_reward_total_weight := 0.0
var card_rarity_weights := {
	Enums.CardRarity.COMMON: 0.0, Enums.CardRarity.UNCOMMON: 0.0, Enums.CardRarity.RARE: 0.0
}


func _ready() -> void:
	for node: Node in rewards.get_children():
		node.queue_free()
	for node: Node in enemy_rewards.get_children():
		node.queue_free()
	rewards.child_order_changed.connect(_on_reward_order_changed)
	enemy_rewards.child_order_changed.connect(_on_enemy_reward_order_changed)
	%RewardScroll.get_child(0).minimum_size_changed.connect(_resize_reward_list)
	_resize_reward_list.call_deferred()
	_on_reward_order_changed()
	_on_enemy_reward_order_changed()

func add_gold_reward(amount: int) -> void:
	var gold_reward := REWARD_BUTTON.instantiate() as RewardButton
	gold_reward.reward_icon = GOLD_ICON
	gold_reward.reward_text = GOLD_TEXT % amount
	gold_reward.pressed.connect(_on_gold_reward_taken.bind(amount))
	rewards.add_child.call_deferred(gold_reward)
	
func add_enemy_gold_reward(amount: int) -> void:
	if amount <= 0:
		return
	var gold_reward := REWARD_BUTTON.instantiate() as RewardButton
	gold_reward.reward_icon = GOLD_ICON
	gold_reward.reward_text = GOLD_TEXT % amount
	gold_reward.pressed.connect(_on_gold_reward_taken.bind(amount))
	enemy_rewards.add_child.call_deferred(gold_reward)


func add_resource_reward(amount: int) -> void:
	var resource_reward := REWARD_BUTTON.instantiate() as RewardButton
	resource_reward.reward_icon = RESOURCE_ICON
	if amount > 1:
		resource_reward.reward_text = RESOURCE_TEXT % amount
	else:
		resource_reward.reward_text = "%s resource" % amount
	resource_reward.pressed.connect(_on_resource_reward_taken.bind(amount))
	rewards.add_child.call_deferred(resource_reward)

func add_enemy_resource_reward(amount: int) -> void:
	if amount <= 0:
		return
	var resource_reward := REWARD_BUTTON.instantiate() as RewardButton
	resource_reward.reward_icon = RESOURCE_ICON
	if amount > 1:
		resource_reward.reward_text = RESOURCE_TEXT % amount
	else:
		resource_reward.reward_text = "%s resource" % amount
	resource_reward.pressed.connect(_on_resource_reward_taken.bind(amount))
	enemy_rewards.add_child.call_deferred(resource_reward)
	

func add_card_reward() -> void:
	var card_reward := REWARD_BUTTON.instantiate() as RewardButton
	card_reward.reward_icon = CARD_ICON
	card_reward.reward_text = CARD_TEXT
	card_reward.pressed.connect(_show_card_rewards)
	rewards.add_child.call_deferred(card_reward)


func add_relic_reward(relic: Relic) -> void:
	if not relic:
		return

	var relic_reward := REWARD_BUTTON.instantiate() as RewardButton
	relic_reward.reward_icon = relic.icon
	relic_reward.reward_text = relic.relic_name
	relic_reward.pressed.connect(_on_relic_reward_taken.bind(relic))
	rewards.add_child.call_deferred(relic_reward)

func _on_reward_order_changed() -> void:
	if (
		!is_instance_valid(rewards)
		or !is_instance_valid(enemy_rewards)
		or !is_instance_valid(empty_label)
		or !is_instance_valid(reward_label)
	):
		return
	if rewards.get_child_count() <= 0:
		reward_label.hide()
		if enemy_rewards.get_child_count() <= 0:
			empty_label.show()
		else:
			empty_label.hide()
	else:
		reward_label.show()
		empty_label.hide()
		
func _on_enemy_reward_order_changed() -> void:
	if (
		!is_instance_valid(enemy_rewards)
		or !is_instance_valid(rewards)
		or !is_instance_valid(empty_label)
		or !is_instance_valid(enemy_reward_label)
	):
		return
	if enemy_rewards.get_child_count() <= 0:
		enemy_reward_label.hide()
		if rewards.get_child_count() <= 0:
			empty_label.show()
		else:
			empty_label.hide()
	else:
		enemy_reward_label.show()
		empty_label.hide()

func _on_gold_reward_taken(amount: int) -> void:
	if not run_stats:
		return
	var event_props := {
		"gold_amount" : amount
	}
	TelemetryManager.track_event("gold_prize_taken", event_props)
	TelemetryManager.track_stat("gold_won", amount)
	run_stats.gold += amount


func _on_resource_reward_taken(amount: int) -> void:
	if not run_stats:
		return
	var event_props := {
		"resource_amount" : amount
	}
	TelemetryManager.track_event("resource_prize_taken", event_props)
	TelemetryManager.track_stat("resources_won", amount)
	run_stats.resources += amount


func _on_card_reward_taken(card: Card) -> void:
	if not player_stats or not card:
		return
	var event_props := {
		"card_taken" : card.name
	}
	TelemetryManager.track_event("card_prize_taken", event_props)
	TelemetryManager.track_stat("cards_won")
	player_stats.deck.add_card(card)


func _on_relic_reward_taken(relic: Relic) -> void:
	if not relic or not relic_handler:
		return
	var event_props := {
		"relic" : relic.relic_name
	}
	TelemetryManager.track_event("relic_prize_taken", event_props)
	TelemetryManager.track_stat("treasure_taken")
	relic_handler.add_relic(relic)

func _show_card_rewards() -> void:
	if not run_stats or not player_stats:
		return
	if card_registry and card_registry.entries.is_empty():
		card_registry.clear_entries()
		card_registry.build_from_card_pile(
			player_stats.draftable_cards, card_reward_tags, player_stats.player_class_name
		)

	var card_rewards := CARD_REWARD_SCENE.instantiate() as CardRewards
	ui_layer.add_child(card_rewards)
	card_rewards.card_reward_selected.connect(_on_card_reward_taken)

	var card_rewards_array: Array[Card] = []
	var available_cards: Array[Card] = []
	if card_registry:
		available_cards = card_registry.get_all_cards(player_stats.player_class_name)
	else:
		available_cards = player_stats.draftable_cards.duplicate_cards()

	for i in run_stats.card_rewards:
		_setup_card_chances()
		var roll := RNG.instance.randf_range(0.0, card_reward_total_weight)

		for rarity: Enums.CardRarity in card_rarity_weights:
			if card_rarity_weights[rarity] > roll:
				_modify_weights(rarity)
				var picked_card := _pick_card_reward(
					rarity,
					available_cards,
					card_rewards_array,
					player_stats.player_class_name,
					card_reward_tags
				)
				if picked_card:
					card_rewards_array.append(picked_card)
					available_cards.erase(picked_card)
				break
	card_rewards.rewards = card_rewards_array
	card_rewards.show()


func _setup_card_chances() -> void:
	card_reward_total_weight = (
		run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight
	)
	card_rarity_weights[Enums.CardRarity.COMMON] = run_stats.common_weight
	card_rarity_weights[Enums.CardRarity.UNCOMMON] = (
		run_stats.uncommon_weight + run_stats.common_weight
	)
	card_rarity_weights[Enums.CardRarity.RARE] = card_reward_total_weight


func _modify_weights(rarity: Enums.CardRarity) -> void:
	if rarity == Enums.CardRarity.RARE:
		run_stats.rare_weight = RunStats.BASE_RARE_WEIGHT
	else:
		run_stats.rare_weight = clampf(run_stats.rare_weight + .3, run_stats.BASE_RARE_WEIGHT, 5.0)


func _get_random_available_card(available_cards: Array[Card], rarity: Enums.CardRarity) -> Card:
	var all_possible_cards := available_cards.filter(
		func(card: Card): return card.card_rarity == rarity
	)
	return RNG.array_pick_random(all_possible_cards)


func _pick_card_reward(
	rarity: Enums.CardRarity,
	available_cards: Array[Card],
	current_rewards: Array[Card],
	player_class: String,
	tags: Array[String] = []
) -> Card:
	if card_registry:
		var picked_from_registry := card_registry.pick_random_card(
			rarity, current_rewards, player_class, tags, true, RNG.instance
		)
		if picked_from_registry:
			return picked_from_registry

	return _get_random_available_card(available_cards, rarity)


func _on_back_button_pressed() -> void:
	Events.battle_reward_exited.emit()


func _resize_reward_list() -> void:
	var scroll := %RewardScroll as ScrollContainer
	scroll.custom_minimum_size.y = minf(480.0, scroll.get_child(0).get_combined_minimum_size().y)
