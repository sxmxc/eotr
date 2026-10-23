extends RefCounted
class_name CardEffectConfigHelper

# Applies common VFX/SFX/projectile defaults from a Card to a CardEffectConfig.
# Keeps visual sourcing DRY and prevents double-spawned FX by toggling attach flags.
static func apply_card_defaults(
	card: Card, config: CardEffectConfig, attach_visual_to_effect: bool = false
) -> void:
	if not card or not config:
		return

	config.attach_visual_to_effect = attach_visual_to_effect

	if not config.sound_fx:
		config.sound_fx = card.sound_fx

	# Route visuals to either the projectile or the effect, not both.
	if attach_visual_to_effect:
		if not config.visual_fx:
			config.visual_fx = card.visual_fx
		config.projectile_visual_fx = null
	else:
		if not config.projectile_visual_fx:
			config.projectile_visual_fx = card.visual_fx
		config.visual_fx = null

	if not config.projectile_fx:
		config.projectile_fx = card.projectile_fx
