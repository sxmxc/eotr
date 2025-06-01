extends Stats
class_name EnemyStats

@export var enemy_name : String = ""
@export var board_icon: Texture2D
@export var ai: PackedScene
@export var call_sound: AudioStream
@export var flying: bool
@export var gold_value: int
@export var resource_value_max: int
