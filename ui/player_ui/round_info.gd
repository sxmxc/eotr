extends Panel

@onready var turn_label: Label = %TurnLabel
@onready var void_label: Label = %VoidLabel

func _ready() -> void:
	Events.round_updated.connect(_on_round_updated)
	Events.rounds_until_shrink_updated.connect(_on_rounds_until_shrink_updated)
	
	
func _on_round_updated(new_round: int) -> void:
	turn_label.text = str(new_round)
	
func _on_rounds_until_shrink_updated(val: int) -> void:
	void_label.text = str(val)
