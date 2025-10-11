extends RefCounted
class_name WorldMessageData

enum Priority {
	ROUTINE,
	IMPORTANT,
	CRITICAL,
}

const DEFAULT_LIFETIMES := {
	Priority.ROUTINE: 1.2,
	Priority.IMPORTANT: 2.2,
	Priority.CRITICAL: 3.0,
}

var message: String
var priority: Priority
var lifetime: float

func _init(
	data: String,
	message_priority: Priority = Priority.ROUTINE,
	custom_lifetime: float = -1.0
):
	message = data
	priority = message_priority
	lifetime = _resolve_lifetime(custom_lifetime)

func _resolve_lifetime(custom_lifetime: float) -> float:
	if custom_lifetime > 0.0:
		return custom_lifetime
	return DEFAULT_LIFETIMES.get(priority, DEFAULT_LIFETIMES[Priority.ROUTINE])
