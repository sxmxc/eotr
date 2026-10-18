extends Control
# The map needs only a toggle, not the former third-party container API.
@onready var content: Control = $MarginContainer
@onready var toggle: Button = $Panel/MarginContainer/Panel/HBoxContainer/Label

func _ready() -> void:
	toggle.toggled.connect(_set_expanded)
	_set_expanded(false)

func _set_expanded(expanded: bool) -> void:
	content.visible = expanded
	toggle.text = "Encounter legend  -" if expanded else "Encounter legend  +"
