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
	_apply_accent()
	_pulse()
	intent_icon.texture = intent.icon
	intent_icon.visible = intent_icon.texture != null
	
	intent_label.text = str(intent.current_text)
	intent_label.visible = intent.current_text.length() > 0
	show()

func _get_tooltip(_at_position: Vector2) -> String:
	if _intent.tooltip_text.find("%") != -1:
		return _intent.tooltip_text % str(_intent.current_text)
	if _intent.tooltip_text.length() > 0:
		return _intent.tooltip_text
	return str(_intent.current_text)


func _apply_accent() -> void:
	if not _intent:
		return

	var default_color := get_theme_color(&"default", &"IntentPalette")
	var accent := _intent.accent_color
	if accent == default_color:
		var tip := _intent.tooltip_text.to_lower()
		if tip.find("attack") != -1:
			accent = get_theme_color(&"attack", &"IntentPalette")
		elif tip.find("block") != -1 or tip.find("defend") != -1 or tip.find("heal") != -1:
			accent = get_theme_color(&"defense", &"IntentPalette")
		elif tip.find("move") != -1:
			accent = get_theme_color(&"movement", &"IntentPalette")
		elif tip.find("buff") != -1 or tip.find("empower") != -1 or tip.find("raise") != -1 or tip.find("spawn") != -1:
			accent = get_theme_color(&"support", &"IntentPalette")
		elif tip.find("wait") != -1 or tip.find("deliberate") != -1:
			accent = get_theme_color(&"idle", &"IntentPalette")

	intent_label.modulate = accent
	intent_icon.modulate = accent


func _pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
