extends TextureButton
class_name CardPileButton

@onready var counter: Label = %Counter
@export var card_pile: CardPile : set = set_card_pile
const HOVER_MATERIAL_PATH := "res://resources/materials/blotchy_border.tres"

@onready var hover_material := preload(HOVER_MATERIAL_PATH)


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
	


func _on_mouse_exited() -> void:
	material = null

func _on_mouse_entered() -> void:
	material = hover_material
