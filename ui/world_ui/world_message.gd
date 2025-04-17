extends PanelContainer
class_name WorldMessage

@export var fade_seconds := 0.2

@onready var message_text_label = %MessageTextLabel

var tween: Tween
var _visible: bool

func _ready() -> void:
	modulate = Color.TRANSPARENT
	
func show_message(data: WorldMessageData) -> void:
	_visible = true
	if tween:
		tween.kill()
		
	message_text_label.text = data.message
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)
	get_tree().create_timer(2).timeout.connect(hide_message)

func hide_message() -> void:
	_visible = false
	if tween:
		tween.kill()
		
	get_tree().create_timer(fade_seconds,false).timeout.connect(hide_animation)
	
func hide_animation() -> void:
	if !_visible:
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
		tween.tween_callback(queue_free)
