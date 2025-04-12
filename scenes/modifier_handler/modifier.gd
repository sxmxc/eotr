extends Node
class_name Modifier

@export var type: Enums.ModifierType


func get_value(source: String) -> ModifierValue:
	for value: ModifierValue in get_children():
		if value.source == source:
			return value

	return null


func add_new_value(value: ModifierValue) -> void:
	var modifier_value := get_value(value.source)
	if not modifier_value:
		add_child(value)
	else:
		modifier_value.flat_value = value.flat_value
		modifier_value.percent_value = value.percent_value


func remove_value(source: String) -> void:
	for value: ModifierValue in get_children():
		if value.source:
			value.queue_free()


func clear_values() -> void:
	for value: ModifierValue in get_children():
		value.queue_free()


func get_modified_value(base: int) -> int:
	var flat_result: int = base
	var percent_result: float = 1.0
	for value: ModifierValue in get_children():
		match value.type:
			Enums.ModifierValueType.FLAT:
				flat_result += value.flat_value
			Enums.ModifierValueType.PERCENT_BASED:
				percent_result += value.percent_value

	return floori(flat_result * percent_result)
