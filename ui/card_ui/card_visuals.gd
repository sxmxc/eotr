extends Control
class_name CardVisuals

@export var card: Card : set = set_card

@onready var panel: Panel = %Panel
@onready var card_cost_label: Label = %CardCostLabel
@onready var card_name_label: Label = %CardNameLabel
@onready var card_type_label: Label = %CardTypeLabel
@onready var card_text_label: RichTextLabel = %CardTextLabel
@onready var rarity: TextureRect = %Rarity
@onready var card_boosted_effect: ColorRect = %CardBoostedEffect

var player_modifiers: ModifierHandler

func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
		
	card = value
	card_cost_label.text = str(card.energy_cost)
	card_name_label.text = str(card.name)
	card_type_label.text = Enums.CardType.keys()[card.card_type].capitalize()
	card_text_label.text = str(card.description)
	rarity.modulate = Card.RARITY_COLORS[card.card_rarity]
	
