extends Node

const Client = preload("res://addons/godot_telemetry/core/client.gd")
const Config = preload("res://addons/godot_telemetry/resources/telemetry_config.gd")
var suspended := false
var _quitting := false
var client: Node
var session_start_ms := 0

func _ready() -> void:
	session_start_ms = Time.get_ticks_msec()
	client = Client.new()
	add_child(client)
	var config_path: String = ProjectSettings.get_setting("telemetry/config_path", "res://telemetry/config/production.tres")
	if config_path.is_empty():
		config_path = "res://telemetry/config/production.tres"
	var settings: Resource = load(config_path) if ResourceLoader.exists(config_path) else Config.new()
	client.configure(settings)
	client.set_context({"build_version": ProjectSettings.get_setting("application/config/version", "unknown")})
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://telemetry/schemas/events.json"))
	for event_name in definitions.events:
		var definition: Dictionary = definitions.events[event_name]
		if definition.has("versions"):
			for version in definition.versions.values():
				client.register_schema(event_name, version)
		else:
			client.register_schema(event_name, definition)
	GameSettings.telemetry_changed.connect(_on_telemetry_changed)
	_on_telemetry_changed(GameSettings.telemetry_enabled)
	Events.enemy_decision_rejected.connect(func(enemy: Enemy, reason: String): track_event("enemy_waited", {"enemy": enemy.stats.enemy_name, "reason": reason}))
	track_event("session_started")

func track_event(event_name: String, props: Dictionary = {}) -> void:
	if not suspended:
		if event_name == "run_started":
			client.set_context({"run_id": client.new_id()})
		client.record(event_name, props)

func track_stat(stat_name: String, change: float = 1.0) -> void:
	track_event("stat_changed", {"stat": stat_name, "change": change})

# Compatibility entry points. Telemetry needs neither a Talo identity nor host ID.
func generate_random_ident() -> void:
	pass

func generate_host_unique_ident() -> void:
	pass

func _on_telemetry_changed(enabled: bool) -> void:
	client.set_consent(enabled)
	if not enabled:
		Talo.events.clear_queue()
		Talo.player_auth.session_manager.clear_session(false)
		Talo.players.identity_cleared.emit()
		Talo.socket.close_connection()

func configure_qa(path: String) -> void:
	var settings := Config.new()
	settings.enabled = true
	settings.consent_required = false
	settings.game_id = "echoes_of_the_rift"
	settings.environment = "qa"
	settings.profile = "qa"
	settings.transport = "jsonl"
	settings.output_path = path
	client.configure(settings)
	client.set_context({"source_type": "bot", "build_version": ProjectSettings.get_setting("application/config/version", "unknown")})

func request_quit() -> void:
	if _quitting:
		return
	_quitting = true
	track_event("session_ended", {"duration_ms": Time.get_ticks_msec() - session_start_ms})
	client.shutdown()
	var deadline := Time.get_ticks_msec() + 1500
	while client.busy and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	get_tree().quit()
