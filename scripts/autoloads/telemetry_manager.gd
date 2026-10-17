extends Node

var suspended := false
var _identifying := false
var _web_identifier := ""
var _quitting := false


func _ready() -> void:
	GameSettings.telemetry_changed.connect(_on_telemetry_changed)
	_on_telemetry_changed(GameSettings.telemetry_enabled)


func track_event(event_name: String, props: Dictionary = {}) -> void:
	if not _can_track():
		return
	# Talo 1.x requires string keys and values, including numeric gameplay data.
	var string_props: Dictionary[String, String] = {}
	for key: Variant in props:
		string_props[str(key)] = str(props[key])
	Talo.events.track(event_name, string_props)


func track_stat(stat_name: String, change: float = 1.0) -> void:
	if _can_track():
		Talo.stats.track(stat_name, change)


func _can_track() -> bool:
	return GameSettings.telemetry_enabled and not suspended and Talo.has_identity()


func generate_random_ident() -> void:
	if _web_identifier.is_empty():
		var cached_alias := TaloPlayerAlias.get_offline_alias()
		_web_identifier = cached_alias.identifier if cached_alias else Talo.players.generate_identifier()
	await _identify("random_username", _web_identifier)


func generate_host_unique_ident() -> void:
	if not GameSettings.telemetry_enabled or suspended or Talo.has_identity() or _identifying:
		return
	if OS.has_feature("web"):
		await generate_random_ident()
		return
	var identifier := OS.get_unique_id()
	if identifier.is_empty():
		await generate_random_ident()
	else:
		await _identify("host", identifier)


func _identify(service: String, identifier: String) -> void:
	if not GameSettings.telemetry_enabled or suspended or Talo.has_identity() or _identifying:
		return
	_identifying = true
	await Talo.players.identify(service, identifier)
	_identifying = false
	# Settings may have changed while the request was in flight.
	if not GameSettings.telemetry_enabled:
		_on_telemetry_changed(false)


func _on_telemetry_changed(enabled: bool) -> void:
	if not enabled:
		Talo.events.clear_queue()
		# Avoid resetting the socket (and opening a new connection) during opt-out.
		Talo.player_auth.session_manager.clear_session(false)
		Talo.players.identity_cleared.emit()
		Talo.socket.close_connection()


func request_quit() -> void:
	if _quitting:
		return
	_quitting = true
	# Let Talo flush pending events just as it does for the window close button.
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
	
