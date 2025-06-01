extends CardPileButton

func _on_card_pile_size_changed(amount: int) -> void:
	super._on_card_pile_size_changed(amount)
	visible = amount > 0
