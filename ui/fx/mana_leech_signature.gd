extends "res://ui/fx/spell_signature.gd"

func execute() -> void:
	super.execute()
	if DisplayServer.get_name() == "headless":
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var anchor := player.get_node_or_null("ImpactAnchor") as Node2D
	var destination := anchor.global_position if anchor else player.global_position
	for child in get_children():
		if child.name.begins_with("StolenMana"):
			child.drift = to_local(destination) - child.position
