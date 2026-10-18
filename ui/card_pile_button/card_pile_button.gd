extends ThemedIconButton
class_name CardPileButton

@onready var counter: Label = %Counter
@export var card_pile: CardPile : set = set_card_pile


func set_card_pile(new_value: CardPile) -> void:
	if card_pile and card_pile.card_pile_Size_changed.is_connected(_on_card_pile_size_changed):
		card_pile.card_pile_Size_changed.disconnect(_on_card_pile_size_changed)
	card_pile = new_value
	if not is_node_ready():
		await ready
	if not card_pile:
		counter.text = "0"
		return
	card_pile.card_pile_Size_changed.connect(_on_card_pile_size_changed)
	_on_card_pile_size_changed(card_pile.cards.size())
		
func _on_card_pile_size_changed(amount: int) -> void:
	counter.text = str(amount)
