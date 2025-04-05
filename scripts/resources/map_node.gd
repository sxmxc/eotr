extends Resource
class_name MapNode

@export var type: Enums.MapNodeType
@export var row: int
@export var column: int
@export var position: Vector2
@export var next_nodes: Array[MapNode]
@export var selected:= false
#only used by monster/boss types
@export var battle_stats: BattleStats

func _to_string() -> String:
	return "%s (%s)" % [column, Enums.MapNodeType.keys()[type][0]]
