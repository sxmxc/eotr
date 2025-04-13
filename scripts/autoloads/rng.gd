extends Node

var instance: RandomNumberGenerator


func _ready() -> void:
	initialize()
	#LimboConsole.register_command(roll, "roll", "Roll a d20")
	#LimboConsole.add_argument_autocomplete_source("roll", 1, func(): return [20, 1])


func initialize() -> void:
	instance = RandomNumberGenerator.new()
	instance.randomize()


func set_from_save_data(which_seed: int, state: int) -> void:
	instance = RandomNumberGenerator.new()
	instance.seed = which_seed
	instance.state = state


func array_pick_random(array: Array) -> Variant:
	if array.is_empty():
		return null

	return array[instance.randi() % array.size()]


func array_shuffle(array: Array) -> void:
	if array.size() < 2:
		return

	for i in range(array.size() - 1, 0, -1):
		var j := instance.randi() % (i + 1)
		var tmp = array[j]
		array[j] = array[i]
		array[i] = tmp


func roll(faces: int = 20, amount: int = 1) -> int:
	if faces <= 0 or amount <= 0:
		return 1
	var outcome := 0
	for x in range(amount):
		var result = instance.randi_range(1, faces)
		outcome += result
		LimboConsole.print_line(str(result))
	LimboConsole.print_line("Total: %s" % str(outcome))
	LimboConsole.print_boxed("Total: %s" % str(outcome))
	return outcome
