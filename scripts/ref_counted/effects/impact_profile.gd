extends RefCounted
class_name ImpactProfile

enum Weight { LIGHT, MEDIUM, HEAVY }

const IMPACT_DECAL_SCENE := preload("res://ui/fx/impact_decal_fx.tscn")

var weight: Weight = Weight.MEDIUM
var shake_strength: float = 14.0
var shake_duration: float = 0.15
var hitstop_scale: float = 1.0
var hitstop_duration: float = 0.0
var tint_color: Color = Color.WHITE
var decal_scene: PackedScene
var decal_scale: float = 1.0


static func for_weight(weight: Weight) -> ImpactProfile:
	var profile := ImpactProfile.new()
	profile.weight = weight

	match weight:
		Weight.LIGHT:
			profile.shake_strength = 10.0
			profile.shake_duration = 0.12
			profile.hitstop_scale = 1.0
			profile.hitstop_duration = 0.0
			profile.tint_color = Color.WHITE
			profile.decal_scene = null
			profile.decal_scale = 0.8
		Weight.MEDIUM:
			profile.shake_strength = 14.0
			profile.shake_duration = 0.15
			profile.hitstop_scale = 0.9
			profile.hitstop_duration = 0.0
			profile.tint_color = Color(1, 0.95, 0.95, 1)
			profile.decal_scene = IMPACT_DECAL_SCENE
			profile.decal_scale = 1.0
		Weight.HEAVY:
			profile.shake_strength = 20.0
			profile.shake_duration = 0.18
			profile.hitstop_scale = 0.45
			profile.hitstop_duration = 0.08
			profile.tint_color = Color(1, 0.75, 0.75, 1)
			profile.decal_scene = IMPACT_DECAL_SCENE
			profile.decal_scale = 1.25

	return profile


static func for_damage(amount: int) -> ImpactProfile:
	if amount >= 18:
		return for_weight(Weight.HEAVY)
	if amount >= 10:
		return for_weight(Weight.MEDIUM)
	return for_weight(Weight.LIGHT)
