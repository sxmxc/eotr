class_name ActDefinition
extends Resource

@export var act_id: String
@export var title: String
@export_multiline var description: String
@export_range(15, 17) var floors := 15
@export var encounters: EncounterRegistry
@export var early_tier := 0
@export var late_tier := 1
@export var boss_tier := 2
@export var recovery_rows: PackedInt32Array = [4, 13]
@export var background: Texture2D
@export var music: AudioStream
@export var boss_relic: Relic

static func campaign() -> Array[ActDefinition]:
	return [load("res://resources/data/acts/fracture.tres"), load("res://resources/data/acts/corruption.tres"), load("res://resources/data/acts/unmaking.tres")]
