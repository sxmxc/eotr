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

@onready var rewards: VBoxContainer = %Rewards
@onready var ui_layer: CanvasLayer = $UILayer

var card_reward_total_weight := 0.0
var card_rarity_weights := {
	Enums.CardRarity.COMMON: 0.0, Enums.CardRarity.UNCOMMON: 0.0, Enums.CardRarity.RARE: 0.0
}


func _ready() -> void:
	for node: Node in rewards.get_children():
		node.queue_free()


func add_gold_reward(amount: int) -> void:
	var gold_reward := REWARD_BUTTON.instantiate() as RewardButton
	gold_reward.reward_icon = GOLD_ICON
	gold_reward.reward_text = GOLD_TEXT % amount
	gold_reward.pressed.connect(_on_gold_reward_taken.bind(amount))
	rewards.add_child.call_deferred(gold_reward)


func add_resource_reward(amount: int) -> void:
	var resource_reward := REWARD_BUTTON.instantiate() as RewardButton
	resource_reward.reward_icon = RESOURCE_ICON
	if amount > 1:
		resource_reward.reward_text = RESOURCE_TEXT % amount
	else:
		resource_reward.reward_text = "%s resource" % amount
	resource_reward.pressed.connect(_on_resource_reward_taken.bind(amount))
	rewards.add_child.call_deferred(resource_reward)


func _on_gold_reward_taken(amount: int) -> void:
	if not run_stats:
		return
	var event_props := {
		"gold_amount" : amount
	}
	Talo.events.track("gold_prize_taken", event_props)
	Talo.stats.track("gold_won", amount)
	run_stats.gold += amount


func _on_resource_reward_taken(amount: int) -> void:
	if not run_stats:
		return
	var event_props := {
		"resource_amount" : amount
	}
	Talo.events.track("resource_prize_taken", event_props)
	Talo.stats.track("resources_won", amount)
	run_stats.resources += amount


func _on_card_reward_taken(card: Card) -> void:
	if not player_stats or not card:
		return
	var event_props := {
		"card_taken" : card.name
	}
	Talo.events.track("card_prize_taken", event_props)
	Talo.stats.track("cards_won")
	player_stats.deck.add_card(card)


func _on_relic_reward_taken(relic: Relic) -> void:
	if not relic or not relic_handler:
		return
	var event_props := {
		"relic" : relic.relic_name
	}
	Talo.events.track("relic_prize_taken", event_props)
	Talo.stats.track("treasure_taken")
	relic_handler.add_relic(relic)


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


func _show_card_rewards() -> void:
	if not run_stats or not player_stats:
		return

	var card_rewards := CARD_REWARD_SCENE.instantiate() as CardRewards
	ui_layer.add_child(card_rewards)
	card_rewards.card_reward_selected.connect(_on_card_reward_taken)

	var card_rewards_array: Array[Card] = []
	var available_cards: Array[Card] = player_stats.draftable_cards.duplicate_cards()

	for i in run_stats.card_rewards:
		_setup_card_chances()
		var roll := RNG.instance.randf_range(0.0, card_reward_total_weight)

		for rarity: Enums.CardRarity in card_rarity_weights:
			if card_rarity_weights[rarity] > roll:
				_modify_weights(rarity)
				var picked_card := _get_random_available_card(available_cards, rarity)
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


func _on_back_button_pressed() -> void:
	Events.battle_reward_exited.emit()
