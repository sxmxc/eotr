extends Resource
class_name MapNode

@export var type: Enums.MapNodeType
@export var row: int
@export var column: int
@export var position: Vector2
# An exported array of this same script retains its own GDScript at shutdown.
# Keep the stored edges resource-typed; graph consumers validate/use MapNode.
@export var next_nodes: Array[Resource] = []
@export var selected:= false

#only used by monster/boss types
@export var battle_stats: EncounterDefinition

func _to_string() -> String:
	return "%s (%s)" % [column, Enums.MapNodeType.keys()[type][0]]
