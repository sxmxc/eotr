extends Node
class_name ModifierValue

@export var type: Enums.ModifierValueType
@export var percent_value: float
@export var flat_value: int
@export var source: String

static func create_new_modifier(modifier_source: String, what_type: Enums.ModifierValueType) -> ModifierValue:
	var new_modifier := new()
	new_modifier.source = modifier_source
	new_modifier.type = what_type
	
	return new_modifier
