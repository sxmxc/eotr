extends Relic

enum Gift { FRACTURE_COMPASS, MEMORY_SIEVE }
@export var gift: Gift
var owner_ui: RelicUI
var available := true

func initialize_relic(owner: RelicUI) -> void:
	owner_ui = owner
	Events.player_turn_started.connect(_reset)
	Events.card_played.connect(_played)

func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_turn_started.is_connected(_reset): Events.player_turn_started.disconnect(_reset)
	if Events.card_played.is_connected(_played): Events.card_played.disconnect(_played)
	owner_ui = null

func _reset() -> void:
	available = true

func _played(card: Card) -> void:
	if not available or not is_instance_valid(owner_ui): return
	var expected := Enums.CardType.MOVEMENT if gift == Gift.FRACTURE_COMPASS else Enums.CardType.SKILL
	if card.card_type != expected: return
	available = false
	owner_ui.flash()
	var handler := owner_ui.get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if not is_instance_valid(handler): return
	if gift == Gift.FRACTURE_COMPASS:
		var effect := BlockEffect.new()
		effect.amount = 3
		effect.execute([handler.player])
	else:
		handler.draw_card.call_deferred()
