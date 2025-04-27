class_name IntentUI
extends Control

@onready var intent_icon: TextureRect = $IntentIcon
@onready var intent_label: Label = $IntentLabel

func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return
	intent_icon.texture = intent.icon
	intent_icon.visible = intent_icon.texture != null
	
	intent_label.text = str(intent.current_text)
	intent_label.visible = intent.current_text.length() > 0
	show()
