extends Stats
class_name PlayerStats

@export_group("Visuals")
@export var board_icon: Texture2D
@export var player_class_name: String
@export_multiline var player_class_description: String

@export_group("Gameplay Data")
@export var starting_deck: CardPile
@export var draftable_cards: CardPile
@export var cards_per_turn: int
@export var max_energy: int


var energy: int : set = set_energy
var resources: int : set = set_resources
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile

func set_resources(value: int) -> void:
	resources = value
	stats_changed.emit()

func add_resource(amount: int) -> void:
	self.resources += amount

func set_energy(value: int) -> void:
	energy = value
	stats_changed.emit()

func reset_energy() -> void:
	self.energy = max_energy
	
func can_play_card(card: Card) -> bool:
	return energy >= card.energy_cost

func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if health < initial_health:
		Events.player_hit.emit()

func create_instance() -> Resource:
	var instance: PlayerStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_energy()
	instance.deck = instance.starting_deck.duplicate()
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	return instance
