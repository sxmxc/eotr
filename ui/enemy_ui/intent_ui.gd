class_name IntentUI
extends Control

@onready var intent_icon: TextureRect = $IntentIcon
@onready var intent_label: Label = $IntentLabel

var _intent : Intent

func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return
	_intent = intent
	intent_icon.texture = intent.icon
	intent_icon.visible = intent_icon.texture != null
	
	intent_label.text = str(intent.current_text)
	intent_label.visible = intent.current_text.length() > 0
	show()

func _get_tooltip(_at_position: Vector2) -> String:
	if _intent.current_text.length() > 0:
		return _intent.tooltip_text % str(_intent.current_text)
	return _intent.tooltip_text
