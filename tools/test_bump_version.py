"""Offline version bump regressions using the real export preset as input."""
from pathlib import Path
import re
import tempfile
import unittest
from unittest.mock import patch

import bump_version
from bump_version import bump, main, update_project


class BumpVersionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = (Path(__file__).resolve().parents[1] / "export_presets.cfg").read_bytes().decode("utf-8")
        cls.original = re.sub(r'(?m)^application/file_version="[^"]+"',
                              'application/file_version="0.3.0.0"', cls.original)

    def test_bump_levels_reset_lower_components(self):
        fixture = self.original.replace('application/file_version="0.3.0.0"',
                                        'application/file_version="2.3.4.5"')
        for part, expected in (("major", "3.0.0.0"), ("minor", "2.4.0.0"),
                               ("patch", "2.3.5.0"), ("revision", "2.3.4.6")):
            with self.subTest(part=part):
                self.assertEqual(bump(fixture, part, "")[1], expected)

    def test_sync_preserves_unrelated_content_and_line_endings(self):
        updated, version = bump(self.original, "patch", "alpha.1")
        self.assertEqual(version, "0.3.1.0-alpha.1")
        for platform in ("windows.exe", "linux.zip", "mac.zip"):
            self.assertIn(f"eotr_v{version}.{platform}", updated)
        self.assertIn('application/file_version="0.3.1.0"', updated)
        self.assertIn('application/product_version="0.3.1.0"', updated)
        self.assertIn('application/short_version="0.3.1"', updated)
        self.assertIn('application/version="0.3.1"', updated)
        old_lines = self.original.splitlines(keepends=True)
        new_lines = updated.splitlines(keepends=True)
        self.assertEqual(len(old_lines), len(new_lines))
        for before, after in zip(old_lines, new_lines):
            if before != after:
                self.assertTrue(before.startswith(("export_path=", "application/file_version=",
                    "application/product_version=", "application/short_version=", "application/version=")))
                self.assertEqual(before.endswith("\r\n"), after.endswith("\r\n"))

    def test_repeated_bump_and_stable_suffix(self):
        first, _ = bump(self.original, "patch", "alpha")
        retained, retained_version = bump(first, "revision")
        self.assertEqual(retained_version, "0.3.1.1-alpha")
        self.assertIn('application/file_version="0.3.1.1"', retained)
        second, version = bump(first, "patch", "")
        self.assertEqual(version, "0.3.2.0")
        self.assertIn("eotr_v0.3.2.0.windows.exe", second)

    def test_project_matches_addon_numeric_version(self):
        original = '[application]\r\nconfig/version="0.1.0.0"\r\nconfig/build="abc123"\r\n'
        self.assertEqual(update_project(original, "0.3.1.2-alpha"),
                         original.replace("0.1.0.0", "0.3.1.2"))
        with self.assertRaises(ValueError):
            update_project('[application]\n', "0.3.1.2")

    def test_cli_dry_run_and_write(self):
        # Only two config fixtures, never a copied Godot project or runtime.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            presets = root / "export_presets.cfg"
            project = root / "project.godot"
            presets.write_bytes(self.original.encode("utf-8"))
            project.write_bytes(b'[application]\r\nconfig/version="0.3.0.0"\r\n')
            initial = (presets.read_bytes(), project.read_bytes())
            with patch.object(bump_version, "ROOT", root), patch("builtins.print"):
                with patch("sys.argv", ["bump_version.py", "revision", "--dry-run"]):
                    self.assertEqual(main(), 0)
                self.assertEqual((presets.read_bytes(), project.read_bytes()), initial)
                with patch("sys.argv", ["bump_version.py", "revision", "--stable"]):
                    self.assertEqual(main(), 0)
                self.assertIn(b'application/file_version="0.3.0.1"', presets.read_bytes())
                self.assertIn(b'config/version="0.3.0.1"', project.read_bytes())

    def test_windows_overflow_fails(self):
        fixture = self.original.replace('application/file_version="0.3.0.0"',
                                        'application/file_version="0.3.0.65535"')
        with self.assertRaises(ValueError):
            bump(fixture, "revision")

    def test_invalid_input_fails(self):
        for label in ("alpha.01", "alpha..1", "hello world", "alpha/1"):
            with self.subTest(label=label), self.assertRaises(ValueError):
                bump(self.original, "patch", label)
        with self.assertRaises(ValueError):
            bump(self.original.replace("eotr_v", "game_"), "patch")


if __name__ == "__main__":
    unittest.main()
