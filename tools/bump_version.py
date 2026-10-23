"""Synchronize export versions without committing, tagging or exporting."""
from __future__ import annotations

import argparse
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
VERSION = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")
FIELDS = {
    "application/file_version": "windows",
    "application/product_version": "windows",
    "application/short_version": "semantic",
    "application/version": "semantic",
}


def current_version(text: str) -> tuple[int, ...]:
    # Windows is the existing source used by the version provider. Other presets
    # may be stale; synchronize them rather than selecting a version by filename.
    match = re.search(r'^application/file_version="([^"]+)"\r?$', text, re.M)
    if not match or not (parsed := VERSION.fullmatch(match[1])):
        raise ValueError("Expected application/file_version=\"MAJOR.MINOR.PATCH.REVISION\"")
    return tuple(int(part) for part in parsed.groups())


def bump(text: str, part: str, prerelease: str | None = None) -> tuple[str, str]:
    numbers = list(current_version(text))
    index = ("major", "minor", "patch", "revision").index(part)
    numbers[index] += 1
    numbers[index + 1:] = [0] * (3 - index)
    if any(number > 65535 for number in numbers):
        raise ValueError("Windows version components must be at most 65535")
    if prerelease is None:
        path = re.search(r'^export_path="[^"]*_v[0-9.]+(?:-([0-9A-Za-z.-]+?))?\.windows\.[^"]+"\r?$', text, re.M)
        if not path:
            raise ValueError("Expected a versioned Windows export path")
        prerelease = path[1] or ""
    if prerelease and not all(
        re.fullmatch(r"[0-9A-Za-z-]+", identifier)
        and not (identifier.isdigit() and len(identifier) > 1 and identifier[0] == "0")
        for identifier in prerelease.split(".")
    ):
        raise ValueError("Invalid SemVer prerelease (example: alpha.1 or rc.2)")
    core = ".".join(map(str, numbers))
    semantic = core + (f"-{prerelease}" if prerelease else "")
    changed_paths = 0
    changed_fields: set[str] = set()
    output = []
    for line in text.splitlines(keepends=True):
        match = re.fullmatch(r'([^=\r\n]+)="([^"\r\n]*)"(\r?\n)?', line)
        if match:
            key, value, newline = match.groups()
            if key in FIELDS:
                # Apple native bundle versions use three numeric components.
                value = core if FIELDS[key] == "windows" else ".".join(map(str, numbers[:3]))
                changed_fields.add(key)
            elif key == "export_path":
                value, count = re.subn(
                    r"(?<=_v)[0-9]+\.[0-9]+\.[0-9]+(?:\.[0-9]+)?"
                    r"(?:-[0-9A-Za-z.-]+)?(?=\.(?:windows|linux|mac)\.)",
                    semantic, value,
                )
                if count != 1:
                    raise ValueError(f"Expected one version token in export_path: {value}")
                changed_paths += count
            line = f'{key}="{value}"{newline or ""}'
        output.append(line)
    if changed_paths != 3 or changed_fields != set(FIELDS):
        raise ValueError("Expected three export paths and all Windows/macOS version fields")
    return "".join(output), semantic


def update_project(text: str, version: str) -> str:
    core = version.split("-", 1)[0]
    updated, count = re.subn(r'(?m)^config/version="[^"\r\n]*"',
                             f'config/version="{core}"', text)
    if count != 1:
        raise ValueError("Expected exactly one config/version in project.godot")
    return updated


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("part", choices=("major", "minor", "patch", "revision"),
                        help="breaking change: major; feat: minor; fix: patch; rebuild: revision")
    suffix = parser.add_mutually_exclusive_group()
    suffix.add_argument("--prerelease", metavar="LABEL",
                        help="filename/tag suffix, e.g. alpha.1 (default: preserve Windows suffix)")
    suffix.add_argument("--stable", action="store_true", help="remove the filename/tag suffix")
    parser.add_argument("--dry-run", action="store_true", help="preview without writing")
    args = parser.parse_args()
    path = ROOT / "export_presets.cfg"
    project = ROOT / "project.godot"
    try:
        original = path.read_bytes().decode("utf-8")
        updated, version = bump(original, args.part, "" if args.stable else args.prerelease)
        project_original = project.read_bytes().decode("utf-8")
        project_updated = update_project(project_original, version)
        if not args.dry_run:
            path.write_bytes(updated.encode("utf-8"))
            try:
                project.write_bytes(project_updated.encode("utf-8"))
            except OSError:
                # Avoid leaving presets bumped when the project cannot be saved.
                path.write_bytes(original.encode("utf-8"))
                raise
    except (OSError, UnicodeError, ValueError) as error:
        parser.exit(1, f"error: {error}\n")
    print(f'{"Would set" if args.dry_run else "Set"} export version to {version}')
    print(f"Suggested commit: chore(release): bump version to {version}")
    print(f"Release tag: v{version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
