extends Control
# The map needs only a toggle, not the former third-party container API.
@onready var content: Control = $MarginContainer
@onready var toggle: Button = $Panel/MarginContainer/Panel/HBoxContainer/Label
@onready var entries: VBoxContainer = %VBoxContainer

func _ready() -> void:
	toggle.toggled.connect(_set_expanded)
	_set_expanded(false)
	theme_changed.connect(_sync_icons)
	_sync_icons()


func _sync_icons() -> void:
	if not is_node_ready():
		return
	for row: HBoxContainer in entries.get_children():
		var kind: StringName = row.get_meta("map_node_type")
		(row.get_node("TextureRect") as TextureRect).texture = get_theme_icon(kind, &"MapNode")

func _set_expanded(expanded: bool) -> void:
	content.visible = expanded
	toggle.text = "Encounter legend  -" if expanded else "Encounter legend  +"
