extends RefCounted
class_name WorldMessageData

enum Priority {
	ROUTINE,
	IMPORTANT,
	CRITICAL,
}

const DEFAULT_LIFETIMES := {
	Priority.ROUTINE: 3.0,
	Priority.IMPORTANT: 8.0,
	Priority.CRITICAL: 10.0,
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
	return maxf(DEFAULT_LIFETIMES.get(priority, 3.0), message.length() / 18.0)
