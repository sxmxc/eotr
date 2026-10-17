"""Check first-party text resources for cache dependencies and embedded binary bloat."""

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
    return problems


if __name__ == "__main__":
    issues = check_resources(Path(__file__).resolve().parents[1])
    for issue in issues:
        print(issue)
    print(f"Scene resource check: {len(issues)} problems")
    sys.exit(bool(issues))
