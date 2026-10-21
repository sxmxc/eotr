extends Control
class_name CardVisuals

@export var card: Card : set = set_card
@export_group("Face states")
@export var hovered_face: StringName = &"CardFaceHovered"
@export var modified_face: StringName = &"CardFaceModified"
@export var modified_hovered_face: StringName = &"CardFaceModifiedHovered"

@onready var card_cost_label: Label = %CardCostLabel
@onready var card_name_label: AutoSizeLabel = %CardNameLabel
@onready var card_type_label: Label = %CardTypeLabel
@onready var card_text_label: RichTextLabel = %CardTextLabel
@onready var rarity: Control = %Rarity
@onready var card_trail_fx: GPUParticles2D = %CardTrailFX
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var background_texture: Panel = %CardBackgroundTexture
@onready var card_art_texture: TextureRect = %CardArt

var player_modifiers: ModifierHandler
var _is_hovered := false
var _is_modified := false
var _authored_face: StringName
var _rules_text := ""


func _ready() -> void:
	_authored_face = background_texture.theme_type_variation
	_update_face_style()

func _process(_delta: float) -> void:
	if card_text_label.text != _rules_text:
		_rules_text = card_text_label.text
		_fit_rules.call_deferred()

func _fit_rules() -> void:
	# Actual shaped text chooses shared typography roles, including modified rules.
	for role: StringName in [&"CardRules", &"CardRulesCompact", &"CardRulesDense"]:
		card_text_label.theme_type_variation = role
		if card_text_label.get_content_height() <= card_text_label.size.y:
			break


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	set_cost(card.energy_cost)
	card_name_label.text = str(card.name)
	card_type_label.text = Enums.CardType.keys()[card.card_type] + (" · EXHAUST" if card.exhaust else "")
	card_text_label.text = card.get_default_description()
	rarity.modulate = get_theme_color(Enums.CardRarity.keys()[card.card_rarity], &"CardRarity")
	_apply_card_art()


func set_cost(cost: int) -> void:
	card_cost_label.text = str(cost)


func set_hover_outline(enabled: bool) -> void:
	_is_hovered = enabled
	_update_face_style()


func set_boosted_effect(enabled: bool) -> void:
	_is_modified = enabled
	_update_face_style()


func set_interactable(active: bool) -> void:
	var tint := get_theme_color("active" if active else "inactive", "CardVisuals")
	if background_texture:
		background_texture.modulate = tint
	if card_art_texture:
		card_art_texture.modulate = Color(tint, card_art_texture.modulate.a)


func _apply_card_art() -> void:
	var authored_art := card.card_art if card else null
	if authored_art:
		card_art_texture.texture = authored_art
		card_art_texture.modulate = Color.WHITE
	else:
		var icon_key: StringName = Enums.CardType.keys()[card.card_type]
		if not has_theme_icon(icon_key, &"CardVisuals"):
			icon_key = &"fallback"
		card_art_texture.texture = get_theme_icon(icon_key, &"CardVisuals")
		card_art_texture.modulate = get_theme_color("fallback_art", "CardVisuals")
	card_art_texture.show()


func _update_face_style() -> void:
	if not background_texture:
		return
	if _is_modified:
		background_texture.theme_type_variation = modified_hovered_face if _is_hovered else modified_face
	else:
		background_texture.theme_type_variation = hovered_face if _is_hovered else _authored_face
