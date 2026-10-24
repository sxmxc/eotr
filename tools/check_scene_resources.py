"""Check first-party resources, UI authoring and shared card projectile ownership."""

from pathlib import Path
import re
import sys


def check_resources(root: Path) -> list[str]:
    problems = []
    for directory in ("scenes", "resources", "ui"):
        for path in sorted((root / directory).rglob("*")):
            if path.suffix not in (".tscn", ".tres"):
                continue
            text = path.read_text(encoding="utf-8")
            relative = path.relative_to(root).as_posix()
            if "res://.godot/" in text:
                problems.append(f"{relative}: references generated .godot cache; reference the source asset")
            if len(text) > 1024 * 1024 and re.search(r"PackedByteArray\([^)]{1048576,}\)", text):
                problems.append(f"{relative}: large embedded byte array; save binary data as an external .res")
            if path.suffix == ".tscn":
                if re.search(r'^\[node name="[^"]*#[^"]*"', text, re.M):
                    problems.append(f"{relative}: generated attachment name; put the child in its owning component scene")
                if re.search(r"^(theme_override_|label_settings\s*=)", text, re.M):
                    problems.append(f"{relative}: use a variation in resources/themes/rift_ui.tres instead of per-node styling")
                for theme_path in re.findall(r'\[ext_resource type="Theme"[^\]]*path="([^"]+)"', text):
                    if theme_path != "res://resources/themes/rift_ui.tres":
                        problems.append(f"{relative}: use the shared Rift UI theme")
    for directory in ("scenes", "ui", "scripts"):
        for path in sorted((root / directory).rglob("*.gd")):
            if "tests" in path.relative_to(root).parts:
                continue
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if line.lstrip().startswith("#"):
                    continue
                if re.search(r"\b(Control|Label|RichTextLabel|Button|Panel|PanelContainer|AcceptDialog)\.new\(|\.add_theme_", line):
                    relative = path.relative_to(root).as_posix()
                    problems.append(f"{relative}:{line_number}: instantiate an authored UI scene or select a theme variation")
    problems.extend(check_card_projectiles(root))
    return problems


def check_card_projectiles(root: Path) -> list[str]:
    """Cards configure travel; CardFxRunner owns projectile instances and completion."""
    problems = []
    for path in sorted((root / "resources/data/cards").rglob("*.gd")):
        # Ignore comments so documentation can name the shared projectile type.
        source = "\n".join(line.split("#", 1)[0] for line in path.read_text(encoding="utf-8").splitlines())
        for pattern in (
            r"\bProjectileFX\b",
            r"\bprojectile_fx\s*\.\s*instantiate\s*\(",
            r"\bforce_complete(?:_deferred)?\b",
            r"[\"']res://[^\"']*projectile[^\"']*\.tscn[\"']\s*\)\s*\.\s*instantiate\s*\(",
        ):
            if re.search(pattern, source):
                relative = path.relative_to(root).as_posix()
                problems.append(f"{relative}: configure projectiles through CardEffectConfig; CardFxRunner owns instancing and completion")
                break
    return problems


if __name__ == "__main__":
    issues = check_resources(Path(__file__).resolve().parents[1])
    for issue in issues:
        print(issue)
    print(f"Scene resource check: {len(issues)} problems")
    sys.exit(bool(issues))
