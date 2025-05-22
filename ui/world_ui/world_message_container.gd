class_name WorldMessageContainer
extends VBoxContainer

const WORLD_MESSAGE = preload("res://ui/world_ui/world_message.tscn")

func _ready() -> void:
	Events.world_message_requested.connect(show_message)
	_clear_children()
	
func show_message(data: WorldMessageData) -> void:
	var message : WorldMessage = WORLD_MESSAGE.instantiate()
	Events.world_message_hide_requested.connect(message.hide_message)
	add_child(message)
	message.show_message(data)

func _clear_children():
	for child in get_children():
		child.queue_free()
