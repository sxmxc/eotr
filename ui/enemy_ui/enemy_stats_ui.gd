extends Panel
class_name EnemyStatsUI


@onready var health_label := %HealthLabel
@onready var block_label := %BlockLabel
@onready var health_container:= %Health
@onready var block_container:= %Block

func update_stats(stats: EnemyStats) -> void:
	if not self.is_node_ready():
		await ready
	block_label.text = str(stats.block)
	health_label.text = str(stats.health)
	
	block_container.visible = !stats.block <= 0
