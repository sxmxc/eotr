extends Control
class_name CardVisuals

@export var card: Card : set = set_card

const MODIFIED_MATERIAL := preload("res://resources/materials/card_modified_material.tres")
const HOVERED_MATERIAL := preload("res://resources/materials/card_hovered_material.tres")

@onready var card_cost_label: Label = %CardCostLabel
@onready var card_name_label: AutoSizeLabel = %CardNameLabel
@onready var card_type_label: Label = %CardTypeLabel
@onready var card_text_label: RichTextLabel = %CardTextLabel
@onready var rarity: TextureRect = %Rarity
@onready var card_trail_fx: GPUParticles2D = %CardTrailFX
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var background_texture: Panel = %CardBackgroundTexture
@onready var foreground_texture: Control = %CardForegroundFrame
@onready var outline_overlay: TextureRect = %OutlineOverlay
@onready var card_art_texture: TextureRect = %CardArt

var player_modifiers: ModifierHandler
var outline_material: ShaderMaterial
var fallback_art_texture: Texture2D
var _base_background_material: Material
var _hover_background_material: Material
var _modified_background_material: Material
var _is_hovered := false
var _is_modified := false


var _face_style: StyleBoxFlat

func _ready() -> void:
	_face_style = background_texture.get_theme_stylebox("panel").duplicate()
	background_texture.add_theme_stylebox_override("panel", _face_style)
	_update_background_material()


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	set_cost(card.energy_cost)
	card_name_label.text = str(card.name)
	card_type_label.text = Enums.CardType.keys()[card.card_type] + (" · EXHAUST" if card.exhaust else "")
	card_text_label.text = str(card.description)
	rarity.modulate = Card.RARITY_COLORS[card.card_rarity]
	_apply_card_art()


func set_cost(cost: int) -> void:
	card_cost_label.text = str(cost)


func set_hover_outline(enabled: bool) -> void:
	_is_hovered = enabled
	if outline_overlay:
		outline_overlay.visible = enabled and outline_overlay.material != null
	_update_background_material()


func set_boosted_effect(enabled: bool) -> void:
	_is_modified = enabled
	_update_background_material()


func set_interactable(active: bool) -> void:
	var tint := 1.0 if active else 0.65
	if background_texture:
		background_texture.modulate = Color(tint, tint, tint, 1.0)
	if foreground_texture:
		foreground_texture.modulate = Color(tint, tint, tint, foreground_texture.modulate.a)
	if card_art_texture:
		card_art_texture.modulate = Color(tint, tint, tint, card_art_texture.modulate.a)


func _apply_card_art() -> void:
	var authored_art := card.card_art if card else null
	if authored_art and not authored_art.resource_path.ends_with("default_card_image.jpg"):
		card_art_texture.texture = authored_art
		card_art_texture.modulate = Color.WHITE
	else:
		var path := "res://assets/icons/cross-flare.svg"
		match card.card_type:
			Enums.CardType.ATTACK:
				path = "res://assets/icons/piercing-sword.svg"
			Enums.CardType.DEFENSE:
				path = "res://assets/icons/shield.png"
			Enums.CardType.MOVEMENT:
				path = "res://assets/icons/wingfoot.svg"
			Enums.CardType.RESOURCE:
				path = "res://assets/icons/metal-bar-fg-only.svg"
		card_art_texture.texture = load(path)
		card_art_texture.modulate = Color("81bcb7")
	card_art_texture.show()


func _update_background_material() -> void:
	if not _face_style:
		return
	_face_style.border_color = Color("66d9c7") if _is_hovered else Color("415462")
	if _is_modified:
		_face_style.border_color = Color("d9b76f")
	_face_style.set_border_width_all(2 if _is_hovered else 1)
