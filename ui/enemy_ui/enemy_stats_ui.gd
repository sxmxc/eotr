class_name EnemyStatsUI
extends Panel

@export var enemy_stats : EnemyStats

@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var shield_label: Label = %ShieldLabel
@onready var shield_container: Control = %Shield
@onready var status_handler: StatusHandler = %StatusHandler
@onready var intent_ui: IntentUI = %IntentUI
@onready var bouncer: Bouncer = %Bouncer
@onready var focus_indicator: TextureRect = %FocusIndicator


func _ready():
	Events.enemy_selected.connect(_on_enemy_selected)
	Events.enemy_updated.connect(_on_enemy_updated)
	for child in status_handler.get_children():
		child.queue_free()
	intent_ui.hide()
	focus_indicator.hide()
	hide()

func setup_enemy_ui(enemy: Enemy) -> void:
	if not self.is_node_ready():
		await ready
	enemy_name_label.text = enemy.name
	enemy.stats_ui = self
	enemy.status_handler = status_handler
	status_handler.status_owner = enemy
	health_bar.max_value = enemy.stats.max_health
	enemy.stats.stats_changed.connect(update_stats.bind(enemy.stats))
	enemy.tree_exiting.connect(queue_free)

func update_stats(stats: EnemyStats) -> void:
	if not self.is_node_ready():
		await ready
	shield_label.text = str(stats.block)
	health_label.text = str(stats.health)
	health_bar.value = stats.health
	
	shield_container.visible = !stats.block <= 0
	
func _on_enemy_selected(enemy: Enemy) -> void:
	if not enemy_stats:
		return
	if enemy == enemy_stats.owner:
		show()
		grab_focus()
	else:
		hide()


func _on_enemy_updated(_enemy: Enemy) -> void:
	pass


func _on_focus_entered() -> void:
	bouncer.Start()
	focus_indicator.show()


func _on_focus_exited() -> void:
	bouncer.stop()
	focus_indicator.hide()
	
