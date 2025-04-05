extends TextureButton
class_name CardPileButton

@export var counter: Label
@export var card_pile: CardPile : set = set_card_pile

func set_card_pile(new_value: CardPile) -> void:
	card_pile = new_value
	
	if not card_pile.card_pile_Size_changed.is_connected(_on_card_pile_size_changed):
		card_pile.card_pile_Size_changed.connect(_on_card_pile_size_changed)
		_on_card_pile_size_changed(card_pile.cards.size())
		
func _on_card_pile_size_changed(amount: int) -> void:
	counter.text = str(amount)
