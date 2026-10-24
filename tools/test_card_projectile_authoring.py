"""Architectural guard fixtures; no project copy or engine/network required."""

from pathlib import Path
import tempfile
import unittest

from check_scene_resources import check_card_projectiles


class CardProjectileAuthoringTests(unittest.TestCase):
    def check_source(self, source: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cards = root / "resources/data/cards/example"
            cards.mkdir(parents=True)
            (cards / "example.gd").write_text(source, encoding="utf-8")
            return check_card_projectiles(root)

    def test_shared_configuration_is_allowed(self):
        self.assertEqual([], self.check_source('''extends Card
# CardFxRunner owns ProjectileFX instances.
func _sync_effect_configs() -> void:
	var config := CardEffectConfig.for_damage(7)
	config.projectile_fx = preload("res://ui/fx/fireball_projectile_fx.tscn")
	config.projectile_mode = CardEffectConfig.ProjectileMode.FIRST_TARGET_ONLY
	CardEffectConfigHelper.apply_card_defaults(self, config, false)
	effect_configs = [config]
'''))

    def test_bespoke_lifecycle_is_rejected(self):
        for source in (
            "var travel := ProjectileFX.new()",
            "var travel := projectile_fx.instantiate()",
            "var travel := config.projectile_fx\n\t.instantiate()",
            'var travel := preload("res://ui/fx/fireball_projectile_fx.tscn").instantiate()',
            "timer.timeout.connect(travel.force_complete_deferred)",
        ):
            with self.subTest(source=source):
                self.assertEqual(1, len(self.check_source(source)))


if __name__ == "__main__":
    unittest.main()
