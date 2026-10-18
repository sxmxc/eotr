extends RefCounted

static func errors(properties: Dictionary, schema: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in schema.get("required", []):
		if not properties.has(key):
			result.append("Missing property: " + str(key))
	for key in properties:
		var rule: Dictionary = schema.get("properties", {}).get(key, {})
		if rule.is_empty():
			if not schema.get("additionalProperties", false):
				result.append("Unknown property: " + str(key))
			continue
		var value: Variant = properties[key]
		var valid := true
		match rule.get("type", ""):
			"string": valid = value is String
			"integer": valid = (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))
			"number": valid = (value is int or value is float) and is_finite(float(value))
			"boolean": valid = value is bool
			"object": valid = value is Dictionary
			"array": valid = value is Array
			"null": valid = value == null
		if not valid:
			result.append("Invalid type: " + str(key))
		elif rule.has("enum") and not value in rule.enum:
			result.append("Invalid enum: " + str(key))
		elif (value is int or value is float) and float(value) < float(rule.get("minimum", -INF)):
			result.append("Below minimum: " + str(key))
		elif value is String and value.length() > int(rule.get("maxLength", 4096)):
			result.append("String too long: " + str(key))
	return result
