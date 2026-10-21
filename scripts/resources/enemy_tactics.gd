extends Resource
class_name EnemyTactics

enum Role { HUNTER, NEEDLE, GUARDIAN, MENDER, SIPHON, REAVER, SCAVENGER, HEXER, DEBT_EATER }
@export var role: Role = Role.HUNTER
@export_range(1, 5) var preferred_range := 1
@export_range(1, 3) var steps := 1
@export_range(1, 12) var damage := 4
@export_range(1, 3) var hits := 1
@export_range(1, 5) var cadence := 2
@export_range(1, 8) var support_amount := 3
@export var protect_lowest_health := true
