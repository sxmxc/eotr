class_name WorldMessageContainer
extends VBoxContainer

const WORLD_MESSAGE = preload("res://ui/world_ui/world_message.tscn")
const MAX_HISTORY := 40
var history: Array[WorldMessageData] = []
var _generation := 0
var _player_control := false

func _ready() -> void:
	for child in get_children():
		if child is WorldMessage:
			remove_child(child)
			child.queue_free()
	Events.world_message_requested.connect(show_message)
	Events.player_turn_started.connect(_on_player_turn_started)
	Events.player_turn_ended.connect(_on_player_turn_ended)
	$HistoryToggle.toggled.connect(_toggle_history)

func show_message(data: WorldMessageData) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if data.priority == WorldMessageData.Priority.ROUTINE and not history.is_empty():
		var previous := history.back() as WorldMessageData
		if previous.priority == data.priority and previous.message == data.message:
			return
	history.append(data)
	if history.size() > MAX_HISTORY:
		var remove_index := 0
		for index in history.size():
			if history[index].priority == WorldMessageData.Priority.ROUTINE:
				remove_index = index
				break
		history.remove_at(remove_index)
	var lines := PackedStringArray()
	for event in history:
		lines.append(event.message)
	$HistoryScroll/HistoryText.text = "\n\n".join(lines)
	var rows: Array[WorldMessage] = []
	for child in $LiveScroll/LiveRows.get_children():
		if child is WorldMessage and not child.is_queued_for_deletion():
			rows.append(child)
	var routine := data.priority == WorldMessageData.Priority.ROUTINE
	# Routine narration never displaces an outcome. History retains all entries.
	if routine:
		for row in rows:
			if row.get_priority() == WorldMessageData.Priority.ROUTINE:
				row.hide_message()
		if rows.size() >= 4:
			return
	elif rows.size() >= 4:
		var oldest := rows[0]
		for row in rows:
			if row.get_priority() == WorldMessageData.Priority.ROUTINE:
				oldest = row
				break
		$LiveScroll/LiveRows.remove_child(oldest)
		oldest.queue_free()
	var message := WORLD_MESSAGE.instantiate() as WorldMessage
	$LiveScroll/LiveRows.add_child(message)
	_scroll_to_latest_message.call_deferred()
	message.show_message(data)

	if _player_control and not routine:
		_expire_message(message, _generation)

func _scroll_to_latest_message() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	# Bursts can evict earlier rows before deferred layout work runs.
	var rows := $LiveScroll/LiveRows.get_children()
	for index in range(rows.size() - 1, -1, -1):
		var row := rows[index] as WorldMessage
		if row and not row.is_queued_for_deletion():
			$LiveScroll.ensure_control_visible(row)
			return

func _on_player_turn_ended() -> void:
	_player_control = false
	_generation += 1

func _on_player_turn_started() -> void:
	_player_control = true
	_generation += 1
	for row in $LiveScroll/LiveRows.get_children():
		if row is WorldMessage:
			_expire_message(row, _generation)

func _expire_message(row: WorldMessage, generation: int) -> void:
	# Read time begins after control returns, independent of animation speed.
	await get_tree().create_timer(maxf(10.0, row.get_lifetime()), false).timeout
	if generation == _generation and is_instance_valid(row):
		row.hide_message()

func _toggle_history(open: bool) -> void:
	$HistoryScroll.visible = open
	$LiveScroll.visible = not open
	if open:
		await get_tree().process_frame
		if $HistoryToggle.button_pressed:
			$HistoryScroll.scroll_vertical = int($HistoryScroll.get_v_scroll_bar().max_value)
