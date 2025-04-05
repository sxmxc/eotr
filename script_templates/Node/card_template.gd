# meta-name: Card Logic
# meta-description: What happens when a card is played
extends Card

@export var optional_sound_fx: AudioStream

func apply_effects(targets: Array[Node]) -> void:
	print("Card logic not implemented")
	print("Targets: %s" % targets)
