class_name EnemyInfoUI
extends Panel

const STATUS_UI = preload("res://ui/status_ui/status_ui.tscn")

@onready var health_label: Label = %HealthLabel
@onready var shield_label: Label = %ShieldLabel
@onready var status_list := %StatusList
@onready var name_label: Label = $MainMargin/Panel/BodyMargin/VBoxContainer/NameLabel


func _ready():
	Events.enemy_selected.connect(_on_enemy_selected)
	Events.enemy_updated.connect(_on_enemy_updated)
	Events.enemy_info_hide_requested.connect(hide)
	hide()


func _on_enemy_selected(enemy_stats: Enemy) -> void:
	update_info(enemy_stats)
	show()


func _on_enemy_updated(enemy: Enemy) -> void:
	if str(enemy.name) != name_label.text:
		return
	update_info(enemy)


func update_info(enemy: Enemy) -> void:
	if not self.is_node_ready():
		await ready
	for child in status_list.get_children():
		child.queue_free()
	name_label.text = enemy.name
	health_label.text = str(enemy.stats.health)
	shield_label.text = str(enemy.stats.block)
	for status: Status in enemy.status_handler._get_all_statuses():
		var new_status_ui := STATUS_UI.instantiate() as StatusUI
		status_list.add_child(new_status_ui)
		new_status_ui.status = status
