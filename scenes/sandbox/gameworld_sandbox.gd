extends GameWorld

@export var sandbox_stats: BattleStats

func _ready() -> void:
	super._ready()
	if not LimboConsole.has_command("generate_map"):
		LimboConsole.register_command(generate_sandbox_map, "generate_map", "Hide resource counts")

func generate_sandbox_map():
	tilemap.generate_tilemap(sandbox_stats)
