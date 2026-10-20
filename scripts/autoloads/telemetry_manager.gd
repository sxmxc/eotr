extends Node

const Client = preload("res://addons/godot_telemetry/core/client.gd")
const Config = preload("res://addons/godot_telemetry/resources/telemetry_config.gd")
var suspended := false
var _quitting := false
var client: Node
var qa_upload: Node
var _configured_settings: Resource
var session_start_ms := 0
var _qa_run_id := ""
var qa_turns := 0

func _ready() -> void:
	session_start_ms = Time.get_ticks_msec()
	client = Client.new()
	add_child(client)
	var config_path: String = ProjectSettings.get_setting("telemetry/config_path", "res://telemetry/config/production.tres")
	if OS.get_cmdline_user_args().has("--validation-local"):
		config_path = "res://scripts/tests/telemetry_null.tres"
	if config_path.is_empty():
		config_path = "res://telemetry/config/production.tres"
	var settings: Resource = load(config_path) if ResourceLoader.exists(config_path) else Config.new()
	_configured_settings = settings.duplicate(true)
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

func track_event(event_name: String, props: Dictionary = {}, version: int = 1) -> void:
	if not suspended:
		if event_name == "run_started":
			set_context({"run_id": _qa_run_id if not _qa_run_id.is_empty() else client.new_id()})
		if event_name == "player_turn_started" and not _qa_run_id.is_empty():
			qa_turns += 1
		client.record(event_name, props, version)
		if is_instance_valid(qa_upload):
			qa_upload.record(event_name, props, version)

func begin_qa_simulation() -> String:
	_qa_run_id = client.new_id()
	qa_turns = 0
	set_context({"run_id": _qa_run_id})
	return _qa_run_id

func set_context(values: Dictionary) -> void:
	client.set_context(values)
	if is_instance_valid(qa_upload):
		qa_upload.set_context(values)

func track_stat(stat_name: String, change: float = 1.0) -> void:
	track_event("stat_changed", {"stat": stat_name, "change": change})

func _on_telemetry_changed(enabled: bool) -> void:
	client.set_consent(enabled)
	if is_instance_valid(qa_upload):
		qa_upload.set_consent(enabled)

func configure_qa(path: String, upload_settings: Resource = null) -> void:
	_qa_run_id = ""
	qa_turns = 0
	if is_instance_valid(qa_upload):
		qa_upload.set_consent(false)
		qa_upload.queue_free()
	qa_upload = null
	var configured: Resource = upload_settings if upload_settings != null else _configured_settings
	var settings: Resource = configured.duplicate(true)
	settings.enabled = true
	settings.consent_required = false
	if settings.game_id.is_empty():
		settings.game_id = "echoes_of_the_rift"
	settings.environment = "qa"
	settings.profile = "qa"
	settings.transport = "jsonl"
	settings.output_path = path
	settings.max_file_bytes = mini(settings.max_file_bytes, 8 * 1024 * 1024)
	client.configure(settings)
	# One JSONL belongs to one session; repeated launches must not append old samples.
	var local_file := FileAccess.open(path, FileAccess.WRITE)
	if local_file:
		local_file.close()
	client.diagnostics = {"recorded": 0, "dropped": 0, "rejected": 0, "delivered": 0, "last_error": ""}
	if configured.enabled and configured.transport == "http" and not OS.get_cmdline_user_args().has("--telemetry-local"):
		var remote: Resource = configured.duplicate(true)
		remote.environment = "qa"
		remote.profile = "qa"
		qa_upload = Client.new()
		add_child(qa_upload)
		qa_upload.configure(remote)
		qa_upload.schemas = client.schemas.duplicate(true)
		qa_upload.session_id = client.session_id
		qa_upload.set_consent(GameSettings.telemetry_enabled)
	set_context({"source_type": "bot", "run_id": "", "build_version": ProjectSettings.get_setting("application/config/version", "unknown")})
	print("AutoWalker telemetry: local JSONL + configured backend" if is_instance_valid(qa_upload) else "AutoWalker telemetry: local JSONL only")
	track_event("session_started")

func flush() -> void:
	client.flush()
	if is_instance_valid(qa_upload):
		qa_upload.flush()

func health() -> Dictionary:
	var upload := {"enabled": false}
	if is_instance_valid(qa_upload):
		upload = qa_upload.health()
		upload.merge({"enabled": qa_upload.config.enabled, "consent": qa_upload.consent})
	return {"local": client.health(), "upload": upload}

func flush_pending(timeout_seconds: float = 15.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		flush()
		var pending: bool = client.busy or not client.queue.is_empty()
		if is_instance_valid(qa_upload):
			pending = pending or qa_upload.busy or not qa_upload.queue.is_empty()
		if not pending:
			return true
		await get_tree().process_frame
	push_warning("Telemetry flush deadline reached; local QA files remain available. " + JSON.stringify(health()))
	return false

func request_quit() -> void:
	if _quitting:
		return
	_quitting = true
	track_event("session_ended", {"duration_ms": Time.get_ticks_msec() - session_start_ms})
	await flush_pending()
	await Utils.stop_audio_for_shutdown()
	get_tree().quit()
