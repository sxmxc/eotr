class_name ProjectileFX
extends Node2D

signal complete

@export var visual_fx: VisualFX
var _completed := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# The impact visual is instantiated before it is transferred to a target.
		# Skipped/interrupted projectiles still own that otherwise orphaned node.
		if is_instance_valid(visual_fx) and visual_fx.get_parent() == null:
			visual_fx.free()


func execute(_target: Node, _source: Node = null) -> void:
	force_complete_deferred()


func resolve_start(source: Node = null) -> Vector2:
	if source is Node2D:
		return (source as Node2D).global_position
	var anchor := _get_projectile_anchor()
	if anchor is Node2D:
		return (anchor as Node2D).global_position
	if anchor is Control:
		return (anchor as Control).global_position
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player:
		return player.global_position
	return global_position


func resolve_end(target: Node, fallback_start: Vector2) -> Vector2:
	if target is Node2D:
		return (target as Node2D).global_position
	var anchor := _get_projectile_anchor()
	if anchor and anchor.has_method("get_global_mouse_position"):
		return anchor.get_global_mouse_position()
	if anchor is Node2D:
		return (anchor as Node2D).global_position
	if anchor is Control:
		return (anchor as Control).global_position
	return fallback_start


func play_visual_on_target(target: Node) -> void:
	if not visual_fx or not target:
		return
	target.add_child(visual_fx)
	if visual_fx.has_method("execute"):
		visual_fx.execute()


func mark_complete() -> void:
	if _completed:
		return
	_completed = true
	complete.emit()


func force_complete_deferred() -> void:
	if _completed:
		return
	call_deferred("mark_complete")


func _get_projectile_anchor() -> Node:
	if not get_tree():
		return null
	return get_tree().get_first_node_in_group("projectile_start")
