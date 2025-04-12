class_name Relic
extends Resource

@export var relic_name: String
@export var id: String
@export var type: Enums.RelicType
@export var character_type: Enums.RelicCharacterType
@export var starter_relic: bool = false
@export var icon: Texture
@export_multiline var description: String


func initialize_relic(_owner: RelicUI) -> void:
	pass


func deactivate_relic(_owner: RelicUI) -> void:
	pass


func get_description() -> String:
	return description


func can_appear_as_reward(player: PlayerStats) -> bool:
	if starter_relic:
		return false

	if character_type == Enums.RelicCharacterType.ALL:
		return true

	var relic_player_name: String = Enums.RelicCharacterType.keys()[character_type].to_lower()
	var player_name := player.player_class_name.to_lower()

	return relic_player_name == player_name
