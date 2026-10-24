extends PanelContainer
class_name WorldMessage

@export var fade_seconds := 0.35

@onready var message_text_label: RichTextLabel = %MessageTextLabel

var tween: Tween
var _visible: bool
var _data: WorldMessageData

func _ready() -> void:
	modulate = Color.TRANSPARENT
	
func show_message(data: WorldMessageData) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(message_text_label):
		return
	_data = data
	_visible = true
	if tween:
		tween.kill()
		
	message_text_label.text = data.message
	theme_type_variation = &"CombatEvent" if data.priority == WorldMessageData.Priority.ROUTINE else &"CombatEventImportant"
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)
	if data.priority == WorldMessageData.Priority.ROUTINE:
		get_tree().create_timer(data.lifetime, false).timeout.connect(hide_message)

func hide_message() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_visible = false
	if tween:
		tween.kill()
		
	get_tree().create_timer(fade_seconds,false).timeout.connect(hide_animation)
	
func hide_animation() -> void:
	if is_inside_tree() and not is_queued_for_deletion() and not _visible:
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
		tween.tween_callback(queue_free)

func get_priority() -> int:
	if _data == null:
		return WorldMessageData.Priority.ROUTINE
	return _data.priority

func get_lifetime() -> float:
	return _data.lifetime if _data else 3.0
