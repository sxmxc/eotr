class_name EnemyStatsUI
extends PanelContainer

var bound_enemy: Enemy
var inspection_pinned := false
var _aiming := false
var _bound_board: ProcGenTilemap

@export var enemy_stats : EnemyStats

@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var shield_label: Label = %ShieldLabel
@onready var shield_container: Control = %Shield
@onready var status_handler: StatusHandler = %StatusHandler
@onready var bouncer: Bouncer = %Bouncer
@onready var focus_indicator: TextureRect = %FocusIndicator
@onready var plan_label: Label = %Plan


func _ready():
	Events.enemy_selected.connect(_on_enemy_selected)
	Events.card_drag_started.connect(_suspend)
	Events.card_aim_started.connect(_suspend)
	Events.card_drag_ended.connect(_resume_inspection)
	Events.card_aim_ended.connect(_resume_inspection)
	visibility_changed.connect(_visibility_changed)
	Events.enemy_info_hide_requested.connect(close_inspection)
	Events.enemy_updated.connect(_on_enemy_updated)
	for child in status_handler.get_children():
		child.queue_free()
	focus_indicator.hide()
	hide()

func setup_enemy_ui(enemy: Enemy) -> void:
	if not self.is_node_ready():
		await ready
	_unbind()
	bound_enemy = enemy
	_bound_board = enemy.tilemap
	if is_instance_valid(_bound_board):
		_bound_board.presentation_changed.connect(_refresh_visibility)
	enemy_stats = enemy.stats
	enemy.stats_ui = self
	enemy.status_handler = status_handler
	status_handler.status_owner = enemy
	enemy.tree_exiting.connect(queue_free)
	_on_enemy_updated(enemy)

func update_stats(stats: EnemyStats) -> void:
	if not self.is_node_ready():
		await ready
	enemy_stats = stats
	enemy_name_label.text = stats.enemy_name if stats.enemy_name else str(bound_enemy.name)
	health_bar.max_value = stats.max_health
	shield_label.text = "Block %d" % stats.block
	health_label.text = "%d / %d HP" % [stats.health, stats.max_health]
	health_bar.value = stats.health
	var encounter_health := is_instance_valid(bound_enemy) and bound_enemy.has_meta("encounter_health")
	health_bar.visible = not encounter_health
	health_label.visible = not encounter_health
	
	shield_container.visible = !stats.block <= 0
	
func _on_enemy_selected(enemy: Enemy) -> void:
	if not enemy_stats or _aiming or not _can_inspect():
		return
	inspection_pinned = enemy == bound_enemy
	if inspection_pinned:
		_on_enemy_updated(bound_enemy)
		show()
		grab_focus()
	else:
		hide()


func _on_enemy_updated(enemy: Enemy) -> void:
	if enemy != bound_enemy:
		return
	update_stats(enemy.stats)
	_refresh_visibility()
	if enemy.current_action and enemy.current_action.intent:
		var plan := enemy.current_action.intent
		plan_label.text = plan.get_description()
	else:
		plan_label.text = "Considering…"


func close_inspection() -> void:
	inspection_pinned = false
	hide()
	release_focus()


func _suspend(_card: CardUI) -> void:
	_aiming = true
	close_inspection()

func _resume_inspection(_card: CardUI) -> void:
	_aiming = false

func _visibility_changed() -> void:
	if visible and (_aiming or not _can_inspect()):
		hide()


func _can_inspect() -> bool:
	return is_instance_valid(bound_enemy) and not bound_enemy.is_dying and (not is_instance_valid(_bound_board) or not _bound_board.is_tile_behind_fog(bound_enemy.current_tile_position))


func _refresh_visibility() -> void:
	if not _can_inspect():
		close_inspection()


func _exit_tree() -> void:
	_unbind()


func _unbind() -> void:
	if is_instance_valid(_bound_board) and _bound_board.presentation_changed.is_connected(_refresh_visibility):
		_bound_board.presentation_changed.disconnect(_refresh_visibility)
	if is_instance_valid(bound_enemy):
		if bound_enemy.tree_exiting.is_connected(queue_free):
			bound_enemy.tree_exiting.disconnect(queue_free)
		if bound_enemy.stats_ui == self:
			bound_enemy.stats_ui = null
	_bound_board = null
	bound_enemy = null
