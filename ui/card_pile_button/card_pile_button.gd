extends TextureButton
class_name CardPileButton

@export var counter: Label
@export var card_pile: CardPile : set = set_card_pile
const HOVER_MATERIAL_PATH := "res://resources/materials/blotchy_border.tres"

@onready var hover_material := preload(HOVER_MATERIAL_PATH)


func set_card_pile(new_value: CardPile) -> void:
	card_pile = new_value
	
	if not card_pile.card_pile_Size_changed.is_connected(_on_card_pile_size_changed):
		card_pile.card_pile_Size_changed.connect(_on_card_pile_size_changed)
		_on_card_pile_size_changed(card_pile.cards.size())
		
func _on_card_pile_size_changed(amount: int) -> void:
	counter.text = str(amount)
	


func _on_mouse_exited() -> void:
	material = null
	pass # Replace with function body.

func _on_mouse_entered() -> void:
	material = hover_material
	pass # Replace with function body.