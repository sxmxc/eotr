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
@onready var background_texture: TextureRect = %CardBackgroundTexture
@onready var foreground_texture: TextureRect = %CardForegroundFrame
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


func _ready() -> void:
	if outline_overlay and outline_overlay.material:
		outline_material = outline_overlay.material.duplicate()
		outline_overlay.material = outline_material

	if card_art_texture:
		fallback_art_texture = card_art_texture.texture
	_base_background_material = background_texture.material
	if _base_background_material and _base_background_material.resource_local_to_scene:
		_base_background_material = _base_background_material.duplicate()
	_hover_background_material = HOVERED_MATERIAL.duplicate()
	_modified_background_material = MODIFIED_MATERIAL.duplicate()
	if _hover_background_material is ShaderMaterial:
		(_hover_background_material as ShaderMaterial).set_shader_parameter("rect_size", background_texture.size)
	if _modified_background_material is ShaderMaterial:
		(_modified_background_material as ShaderMaterial).set_shader_parameter("rect_size", background_texture.size)

	if outline_overlay:
		outline_overlay.visible = false
	_update_background_material()


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	set_cost(card.energy_cost)
	card_name_label.text = str(card.name)
	card_type_label.text = Enums.CardType.keys()[card.card_type].capitalize()
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
	if card and card.card_art:
		card_art_texture.texture = card.card_art
		card_art_texture.visible = true
	else:
		card_art_texture.texture = fallback_art_texture
		card_art_texture.visible = fallback_art_texture != null


func _update_background_material() -> void:
	if not background_texture:
		return
	var mat: Material = _base_background_material
	if _is_hovered and _hover_background_material:
		mat = _hover_background_material
	if _is_modified and _modified_background_material:
		mat = _modified_background_material
	background_texture.material = mat
