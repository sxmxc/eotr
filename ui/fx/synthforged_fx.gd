class_name SynthforgedFX
extends VisualFX
## Cosmetic machinery and diagnostic feedback. No gameplay callbacks or RNG.
@export var mode := "pulse_rifle"
@export var duration := 0.38
var caster: Node2D
var progress := 0.0
var source := Vector2.ZERO
const AMBER := Color(1.0, 0.64, 0.18)
const IVORY := Color(0.96, 0.9, 0.72)
const RED := Color(1.0, 0.25, 0.16)

static func play_on(target: Node2D, ability: String) -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(target): return
	var fx := load("res://ui/fx/synthforged/%s.tscn" % ability) as PackedScene
	if not fx: return
	var instance := fx.instantiate() as VisualFX
	target.add_child(instance)
	instance.execute()

func execute() -> void:
	var anchor := get_parent().get_node_or_null("ImpactAnchor") as Node2D
	if anchor: global_position = anchor.global_position
	var player := caster if is_instance_valid(caster) else get_tree().get_first_node_in_group("player") as Node2D
	if player and player != get_parent():
		var origin := player.get_node_or_null("SpellOrigin") as Node2D
		source = to_local(origin.global_position if origin else player.global_position)
	var tween := create_tween()
	tween.tween_method(_animate, 0.0, 1.0, Utils.presentation_duration(duration))
	tween.finished.connect(queue_free)

func _animate(value: float) -> void:
	progress = value
	queue_redraw()

func _draw() -> void:
	var alpha := sin(progress * PI)
	var amber := Color(AMBER, alpha)
	var ivory := Color(IVORY, alpha)
	var red := Color(RED, alpha)
	var reach := lerpf(30.0, 18.0, minf(progress * 3.0, 1.0))
	if mode in ["target_scan", "wideband_scan", "threat_assessment", "combat_network"]:
		# Four converging angular corners, followed by a downward scan line.
		for i in 4:
			var corner := Vector2(-1 if i % 2 == 0 else 1, -1 if i < 2 else 1) * reach
			draw_line(corner, corner - Vector2(signf(corner.x) * 9, 0), red, 1.5, true)
			draw_line(corner, corner - Vector2(0, signf(corner.y) * 9), red, 1.5, true)
		var y := lerpf(-20, 20, progress)
		draw_line(Vector2(-16, y), Vector2(16, y), red, 1, true)
	elif mode in ["reactive_plating", "ablative_array", "fortress_protocol", "deploy_bastion"]:
		# Discrete armor segments close around the beneficiary, leaving the body open.
		for i in 4:
			var x := (-1 if i % 2 == 0 else 1) * reach
			var y := -14.0 + (i / 2) * 22.0
			draw_polygon(PackedVector2Array([Vector2(x, y - 9), Vector2(x + signf(x) * 9, y - 5), Vector2(x + signf(x) * 8, y + 7), Vector2(x, y + 9)]), PackedColorArray([ivory]))
	elif mode in ["vector_boost", "thruster_assault", "redeployment"]:
		for i in 3:
			var offset := Vector2(-28 - progress * 28, -9 + i * 9)
			draw_line(offset, offset + Vector2(24 * alpha, -3), amber, 3.0 - i * 0.5, true)
	elif mode in ["field_repairs", "efficient_fabrication", "salvage_probe", "deploy_sentry", "deploy_pike", "deploy_siege_platform"]:
		# Tool arms hinge inward; small sparks fall away from the work point.
		for side in [-1.0, 1.0]:
			var joint := Vector2(side * reach, 8)
			draw_polyline(PackedVector2Array([Vector2(side * 30, 20), joint, Vector2(side * 5, -6)]), ivory, 2, true)
		for i in 7:
			var direction := Vector2.from_angle(i * 0.91)
			var start := direction * progress * 22 + Vector2(0, progress * progress * 8)
			draw_line(start, start + direction * 4, amber, 1, true)
	elif mode in ["reserve_capacitor", "reactor_release", "overclock"]:
		# Three rising battery rails; no full-screen flash.
		for i in 3:
			var x := -12 + i * 12
			draw_line(Vector2(x, 16), Vector2(x, 16 - 40 * alpha), amber, 4, true)
			draw_rect(Rect2(-21, -24, 42, 46), ivory, false, 1)
	elif mode in ["tactical_cache", "fire_command"]:
		for i in 3:
			var y := 8 - i * 11 - progress * 10
			draw_polyline(PackedVector2Array([Vector2(-12, y + 5), Vector2(0, y), Vector2(12, y + 5)]), red if mode == "fire_command" else ivory, 2, true)
	else:
		# Physical weapon contact: short tracers, directional fragments, central peak.
		var heavy := mode in ["rail_lance", "execution_algorithm", "siege_attack"]
		if source != Vector2.ZERO and mode not in ["servo_strike", "construct_death", "pike_attack", "bastion_attack"]:
			draw_line(source.lerp(Vector2.ZERO, progress * 0.6), Vector2(8, -2), amber, 3 if heavy else 1.5, true)
		for i in (10 if heavy else 6):
			var direction := Vector2.from_angle(i * 2.399)
			draw_line(direction * progress * 24, direction * (progress * 24 + 7 * alpha), amber, 2, true)
		if progress < 0.5:
			draw_line(Vector2(-5, -10), Vector2(5, 10), ivory, 3, true)
			draw_line(Vector2(-10, 3), Vector2(10, -3), ivory, 2, true)
