class_name EnemyStatsUI
extends PanelContainer

var bound_enemy: Enemy
var inspection_pinned := false
var _aiming := false

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
	bound_enemy = enemy
	enemy_stats = enemy.stats
	enemy_name_label.text = enemy.stats.enemy_name if enemy.stats.enemy_name else str(enemy.name)
	enemy.stats_ui = self
	enemy.status_handler = status_handler
	status_handler.status_owner = enemy
	health_bar.max_value = enemy.stats.max_health
	enemy.stats.stats_changed.connect(update_stats.bind(enemy.stats))
	enemy.tree_exiting.connect(queue_free)

func update_stats(stats: EnemyStats) -> void:
	if not self.is_node_ready():
		await ready
	shield_label.text = "Block %d" % stats.block
	health_label.text = "%d / %d HP" % [stats.health, stats.max_health]
	health_bar.value = stats.health
	
	shield_container.visible = !stats.block <= 0
	
func _on_enemy_selected(enemy: Enemy) -> void:
	if not enemy_stats or _aiming:
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
	if visible and _aiming:
		hide()
