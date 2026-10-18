class_name RunTimerUI
extends HBoxContainer

@onready var label: Label = $Label
@onready var update_timer: Timer = $UpdateTimer

# Monotonic active-run time: unscaled, paused with the run, never offline time.
var _accumulated := 0.0
var _started_usec := 0
var elapsed_time: float:
	get:
		if is_running and is_inside_tree() and not get_tree().paused:
			return _accumulated + (Time.get_ticks_usec() - _started_usec) / 1000000.0
		return _accumulated
	set(value):
		_accumulated = maxf(value, 0.0)
		_started_usec = Time.get_ticks_usec()
var is_running := false

func _ready() -> void:
	update_timer.timeout.connect(_update_label)
	_update_label()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_running:
		_accumulated += (Time.get_ticks_usec() - _started_usec) / 1000000.0
	elif what == NOTIFICATION_UNPAUSED:
		_started_usec = Time.get_ticks_usec()

func start() -> void:
	resume_from(0.0)

func stop() -> void:
	elapsed_time = elapsed_time
	is_running = false
	update_timer.stop()
	_update_label()

func resume() -> void:
	_started_usec = Time.get_ticks_usec()
	is_running = true
	update_timer.start()

func resume_from(time: float) -> void:
	elapsed_time = time
	resume()
	_update_label()

func reset() -> void:
	stop()
	elapsed_time = 0.0
	_update_label()

func get_pretty_time() -> String:
	var seconds := int(elapsed_time)
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds % 3600) / 60, seconds % 60]

func _update_label() -> void:
	var text := get_pretty_time()
	if label.text != text:
		label.text = text
