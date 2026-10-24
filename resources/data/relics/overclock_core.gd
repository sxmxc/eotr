class_name OverclockCore
extends Relic

var turn := 0

func get_description() -> String:
	return description + "\nCycle: %d/4. Next Overclock in %d turn(s)." % [turn % 4, 4 - turn % 4]

