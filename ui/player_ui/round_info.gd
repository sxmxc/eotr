extends Panel

@onready var turn_label: Label = %TurnLabel

func _ready() -> void:
	Events.round_updated.connect(_on_round_updated)
	
func _on_round_updated(new_round: int) -> void:
	turn_label.text = str(new_round)
