class_name Intent
extends Resource

@export var base_text: String
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var accent_color: Color = Color(0.7, 0.9, 1.0, 1.0)

var current_text: String
var secondary_icon: Texture2D
var secondary_text := ""
var detail_text := ""


func get_description() -> String:
	var description := detail_text if not detail_text.is_empty() else tooltip_text
	if description.contains("%s"):
		# Actions briefly restore their format template while resolving. Never
		# expose that template as a combat number or invent an unresolved amount.
		description = description % ("…" if current_text.contains("%s") else current_text)
	return description.trim_prefix("Plans to ").capitalize()


func get_display_text() -> String:
	if not secondary_text.is_empty() and not current_text.contains("%s"):
		return current_text.get_slice("/", 0)
	var description := tooltip_text.to_lower()
	if "raise" in description or "spawn" in description or "summon" in description:
		return "Summon"
	if not current_text.strip_edges().is_empty() and not current_text.contains("%s"):
		return current_text.strip_edges().get_slice("\n", 0)
	if "move" in description or "reposition" in description:
		return "Move"
	if "deliberate" in description or "wait" in description:
		return "Wait"
	if "block" in description or "plating" in description:
		return "Guard"
	if "empower" in description or "buff" in description:
		return "Buff"
	if "weaken" in description:
		return "Weaken"
	return "Attack" if "attack" in description else "Prepare"


func get_display_icon() -> Texture2D:
	var description := tooltip_text.to_lower()
	if "raise" in description or "spawn" in description or "summon" in description:
		return preload("res://assets/rift/ui/summon.svg")
	if "deliberate" in description or "wait" in description:
		return preload("res://assets/rift/ui/wait.svg")
	if "weaken" in description:
		return preload("res://assets/rift/ui/weakened.svg")
	if icon:
		return icon
	return preload("res://assets/rift/ui/attack.svg")
