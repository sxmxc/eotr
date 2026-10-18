extends Panel

@onready var turn_label: Label = %TurnLabel
@onready var void_label: Label = %VoidLabel

func _ready() -> void:
	Events.round_updated.connect(_on_round_updated)
	Events.rounds_until_shrink_updated.connect(_on_rounds_until_shrink_updated)
	
	
func _on_round_updated(new_round: int) -> void:
	turn_label.text = "ROUND %02d" % new_round
	
func _on_rounds_until_shrink_updated(val: int) -> void:
	void_label.text = "Collapse in %d round%s" % [val, "" if val == 1 else "s"]
	void_label.theme_type_variation = &"CollapseDanger" if val <= 1 else &"CollapseLabel"
	tooltip_text = "Outer hexes collapse in %d round(s). Units on collapsing tiles take lethal direct damage. Move inward before the countdown ends." % val
