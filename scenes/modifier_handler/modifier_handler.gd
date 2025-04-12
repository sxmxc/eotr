extends Node
class_name ModifierHandler

func has_modifier(type: Enums.ModifierType) -> bool:
	for modifier: Modifier in get_children():
		if modifier.type == type:
			return true
	return false
	
func get_modifier(type: Enums.ModifierType) -> Modifier:
	for modifier: Modifier in get_children():
		if modifier.type == type:
			return modifier	
	return null
	
func get_modified_value(base: int, type: Enums.ModifierType) -> int:
	var modifier := get_modifier(type)
	if not modifier:
		return base
	return modifier.get_modified_value(base)
