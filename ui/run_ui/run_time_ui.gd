class_name RunTimerUI
extends HBoxContainer

@onready var label: Label = $Label

@onready var update_timer: Timer = Timer.new()

var elapsed_time: float = 0.0
var is_running: bool = false

func _ready() -> void:
	label.text = "00:00:00"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Setup update timer (every 0.1s)
	update_timer.wait_time = 0.1
	update_timer.one_shot = false
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)

func start() -> void:
	elapsed_time = 0.0
	is_running = true
	update_timer.start()

func stop() -> void:
	is_running = false
	update_timer.stop()

func resume() -> void:
	is_running = true
	update_timer.start()

func resume_from(time: float) -> void:
	elapsed_time = time
	is_running = true
	update_timer.start()

func reset() -> void:
	elapsed_time = 0.0
	is_running = false
	update_timer.stop()
	_update_label()

func get_pretty_time() -> String:
	var total_seconds := int(elapsed_time)
	@warning_ignore("integer_division")
	var hours := int(total_seconds / 3600)
	@warning_ignore("integer_division")
	var minutes := int((total_seconds % 3600) / 60)
	var seconds := int(total_seconds % 60)
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _on_update_timer_timeout() -> void:
	if is_running:
		elapsed_time += update_timer.wait_time
		_update_label()

func _update_label() -> void:
	label.text = get_pretty_time()
