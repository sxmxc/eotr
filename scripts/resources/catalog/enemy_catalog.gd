extends Resource
class_name EnemyCatalog

@export var entries: Array[Dictionary] = []


func add_entry(scene: PackedScene, stats: EnemyStats, label: String, tags: Array[String] = []) -> void:
	if not scene or not stats:
		return
	entries.append({
		"scene": scene,
		"stats": stats,
		"label": label,
		"tags": tags.duplicate()
	})


func list_entries() -> Array[Dictionary]:
	return entries.duplicate()
