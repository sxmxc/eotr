import json
from pathlib import Path
import tempfile
import unittest

from compare_autowalker import compare, read


class LoadoutComparisonTests(unittest.TestCase):
    def test_different_loadouts_are_not_matched(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            record = dict(seed=1, encounter='battle', policy='greedy', policy_version='1',
                          mode='encounter', metrics_version=2, outcome='win')
            for name, fingerprint in [('before', 'starter'), ('after', 'tier_2')]:
                folder = root / name
                folder.mkdir()
                (folder / 'simulation-1.json').write_text(json.dumps(dict(record, loadout_fingerprint=fingerprint)))
            result = compare(read(root / 'before'), read(root / 'after'))
            self.assertEqual(result['matched_simulations'], 0)
            self.assertEqual(result['unmatched_before'], 1)
            self.assertEqual(compare(read(root / 'before'), read(root / 'before'))['matched_simulations'], 1)
