extends Node

class StatusOwner extends Node2D:
	signal damage_taken(amount: int)
	var modifier_handler: ModifierHandler

class CountingStatus extends Status:
	var applications := 0
	var before_apply: Callable

	func apply_status(target: Node) -> void:
		applications += 1
		if before_apply.is_valid():
			before_apply.call()
		super.apply_status(target)

var failures := 0


func _ready() -> void:
	run.call_deferred()


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)


func run() -> void:
	var owner := StatusOwner.new()
	owner.modifier_handler = ModifierHandler.new()
	owner.add_child(owner.modifier_handler)
	for type: Enums.ModifierType in [Enums.ModifierType.DMG_DEALT, Enums.ModifierType.DMG_TAKEN]:
		var modifier := Modifier.new()
		modifier.type = type
		owner.modifier_handler.add_child(modifier)
	add_child(owner)
	var handler := StatusHandler.new()
	handler.status_owner = owner
	owner.add_child(handler)
	var dealt := owner.modifier_handler.get_modifier(Enums.ModifierType.DMG_DEALT)
	var taken := owner.modifier_handler.get_modifier(Enums.ModifierType.DMG_TAKEN)
	var unrelated := ModifierValue.create_new_modifier("unrelated", Enums.ModifierValueType.FLAT)
	unrelated.flat_value = 2
	taken.add_new_value(unrelated)

	var weakened: Status = load("res://resources/data/statuses/weakened.tres").duplicate()
	weakened.duration = 1
	handler.add_status(weakened)
	var mirror: StatusUI = load("res://ui/status_ui/status_ui.tscn").instantiate()
	add_child(mirror)
	mirror.status = weakened
	check(taken.get_modified_value(10) == 18, "Weakened applies alongside another source")
	handler.apply_statuses_by_type(weakened.type)
	await handler.statuses_applied
	check(taken.get_modified_value(10) == 12, "Expiration preserves unrelated modifier")
	check(handler.get_child_count() == 0, "Expiration removes status UI")
	check(taken.get_value("weakened") == null, "Expired modifier is detached")
	check(not mirror.visible and not mirror.is_queued_for_deletion(), "Inspection views hide expired status without owning removal")
	mirror.queue_free()
	weakened.duration = 2
	check(taken.get_value("weakened") == null, "Removed resource cannot restore a modifier")
	handler.add_status(weakened)
	weakened.duration = 0
	check(taken.get_modified_value(10) == 12, "Direct expiration affects calculations immediately")
	var replacement: Status = load("res://resources/data/statuses/weakened.tres").duplicate()
	handler.add_status(replacement)
	check(handler.get_child_count() == 1 and taken.get_modified_value(10) == 18, "Same-frame reapplication starts fresh")
	handler.remove_status("weakened")
	handler.remove_status("weakened")
	check(taken.get_value("unrelated") == unrelated, "Repeated removal is harmless")

	for path: String in ["strength", "attunement"]:
		var status: Status = load("res://resources/data/statuses/" + path + ".tres").duplicate()
		status.stacks = 3
		handler.add_status(status)
		check(dealt.get_modified_value(10) == 13, path + " applies")
		status.stacks = -1
		check(dealt.get_modified_value(10) == 10, path + " cleans up negative stacks immediately")
		status.stacks = 4
		check(dealt.get_modified_value(10) == 10, path + " disconnects updates on removal")
		handler.add_status(status)
		status.stacks = 0
		check(dealt.get_value(path) == null, path + " cleans up zero stacks")

	var armored: Status = load("res://resources/data/statuses/armored.tres").duplicate()
	armored.stacks = 2
	handler.add_status(armored)
	owner.damage_taken.emit(3)
	check(handler.get_child_count() == 0, "Armored removes on over-depletion")
	var exhausted_stacks := armored.stacks
	owner.damage_taken.emit(3)
	check(armored.stacks == exhausted_stacks, "Removed Armored disconnects damage signal")

	var first := CountingStatus.new()
	first.id = "first"
	var second := CountingStatus.new()
	second.id = "second"
	var next_second := CountingStatus.new()
	next_second.id = "second"
	first.before_apply = func():
		handler.remove_status("second")
		handler.add_status(next_second)
	handler.add_status(first)
	handler.add_status(second)
	handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
	await handler.statuses_applied
	check(first.applications == 1 and second.applications == 0, "Queued removed statuses do not apply")
	check(next_second.applications == 0, "Replacement is not applied by stale queued callback")
	handler.remove_status("first")
	handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
	await handler.statuses_applied
	check(next_second.applications == 1, "Replacement applies in next batch")
	handler.remove_status("second")

	var strength: Status = load("res://resources/data/statuses/strength.tres").duplicate()
	handler.add_status(strength)
	armored.stacks = 2
	handler.add_status(armored)
	owner.remove_child(handler)
	handler.queue_free()
	check(dealt.get_value("strength") == null, "Handler teardown cleans modifiers on surviving owner")
	owner.damage_taken.emit(1)
	check(armored.stacks == 2, "Handler teardown disconnects event statuses")
	strength.stacks = 9
	check(dealt.get_value("strength") == null, "Handler teardown disconnects resource updates")
	owner.queue_free()
	await get_tree().process_frame
	print("Status lifecycle tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
