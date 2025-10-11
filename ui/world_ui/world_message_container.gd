class_name WorldMessageContainer
extends VBoxContainer

const WORLD_MESSAGE = preload("res://ui/world_ui/world_message.tscn")
const MAX_ROUTINE_MESSAGES := 2

func _ready() -> void:
	Events.world_message_requested.connect(show_message)
	_clear_children()
	
func show_message(data: WorldMessageData) -> void:
	_trim_queue_for(data)
	var message : WorldMessage = WORLD_MESSAGE.instantiate()
	Events.world_message_hide_requested.connect(message.hide_message)
	add_child(message)
	if data.priority != WorldMessageData.Priority.ROUTINE:
		move_child(message, 0)
	message.show_message(data)

func _clear_children():
	for child in get_children():
		child.queue_free()

func _trim_queue_for(data: WorldMessageData) -> void:
	var children := get_children()
	if data.priority == WorldMessageData.Priority.ROUTINE:
		var routine_messages: Array = []
		for child in children:
			if child is WorldMessage and child.get_priority() == WorldMessageData.Priority.ROUTINE:
				routine_messages.append(child)
		while routine_messages.size() >= MAX_ROUTINE_MESSAGES:
			var oldest: WorldMessage = routine_messages.pop_front()
			oldest.hide_message()
	else:
		for child in children:
			if child is WorldMessage and child.get_priority() < data.priority:
				child.hide_message()
