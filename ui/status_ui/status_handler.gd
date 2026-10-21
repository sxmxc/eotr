extends GridContainer
class_name StatusHandler

signal statuses_applied(type: Enums.StatusType)
signal status_added

const STATUS_APPLY_INTERVAL := 0.25

@export var status_owner: Node2D
@export var status_ui_scene: PackedScene = preload("res://ui/status_ui/status_ui.tscn")

var _application_tween: Tween


func cancel_application() -> void:
	if _application_tween and _application_tween.is_valid():
		_application_tween.kill()
	_application_tween = null


func _exit_tree() -> void:
	cancel_application()
	for status: Status in _get_all_statuses():
		_release_status(status)


func apply_statuses_by_type(type: Enums.StatusType) -> void:
	if type == Enums.StatusType.EVENT_BASED:
		return
	cancel_application()

	var status_queue: Array[Status] = _get_all_statuses().filter(
		func(status: Status): return status.type == type
	)

	if status_queue.is_empty():
		statuses_applied.emit(type)
		return

	_application_tween = create_tween()
	for status: Status in status_queue:
		_application_tween.tween_callback(_apply_status.bind(status))
		_application_tween.tween_interval(Utils.presentation_duration(STATUS_APPLY_INTERVAL))

	_application_tween.finished.connect(func():
		_application_tween = null
		statuses_applied.emit(type)
	)


func add_status(status: Status) -> void:
	var stackable := status.stack_type != Enums.StatusStackType.NONE

	if not _has_status(status.id):
		if status.is_expired():
			return
		var new_status_ui := status_ui_scene.instantiate() as StatusUI
		add_child(new_status_ui)
		new_status_ui.status = status
		new_status_ui.status.status_applied.connect(_on_status_applied)
		new_status_ui.status.initialize_status(status_owner)
		status.status_changed.connect(_on_status_changed.bind(status))
		status_added.emit()
		return

	if not status.can_expire and not stackable:
		return

	if status.can_expire and status.stack_type == Enums.StatusStackType.DURATION:
		_get_status(status.id).duration += status.duration
		status_added.emit()
		return

	if status.stack_type == Enums.StatusStackType.INTENSITY:
		_get_status(status.id).stacks += status.stacks
		status_added.emit()
	

func remove_status(id: String) -> void:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			_release_status(status_ui.status)
			remove_child(status_ui)
			status_ui.queue_free()
			return


func _release_status(status: Status) -> void:
	var changed_callback := _on_status_changed.bind(status)
	if status.status_changed.is_connected(changed_callback):
		status.status_changed.disconnect(changed_callback)
	if status.status_applied.is_connected(_on_status_applied):
		status.status_applied.disconnect(_on_status_applied)
	status.remove_status(status_owner)


func _on_status_changed(status: Status) -> void:
	if status.is_expired():
		remove_status(status.id)


func _apply_status(status: Status) -> void:
	if _get_status(status.id) == status:
		status.apply_status(status_owner)


func _has_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return true
	return false


func _get_status(id: String) -> Status:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return status_ui.status
	return null


func _get_all_statuses() -> Array[Status]:
	var statuses: Array[Status] = []
	for status_ui: StatusUI in get_children():
		statuses.append(status_ui.status)
	return statuses


func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		Events.status_tooltip_requested.emit(_get_all_statuses())
