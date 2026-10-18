"""Run the migration smoke scene with isolated saves and offline Talo settings.

Usage: python tools/validate_project.py --godot /path/to/godot[.exe]
Requires an editor import of the real project first. Does not modify project.godot.
"""

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

from check_scene_resources import check_resources


def link_directory(source: Path, destination: Path) -> None:
    if destination.exists():
        if destination.resolve() != source.resolve():
            raise RuntimeError(f"Unexpected existing directory: {destination}")
        return
    if os.name == "nt":
        subprocess.run(
            ["cmd", "/c", "mklink", "/J", str(destination), str(source)],
            check=True, capture_output=True,
        )
    else:
        destination.symlink_to(source, target_is_directory=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot"))
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--combat-automation", action="store_true")
    parser.add_argument("--capture-ui", action="store_true", help="Run the native renderer offscreen and save UI captures")
    parser.add_argument("--ui-transactions-only", action="store_true", help="Run only reward and shop interaction checks")
    args = parser.parse_args()
    if not args.godot or Path(args.godot).suffix.lower() in (".cmd", ".bat"):
        parser.error("Pass --godot with the Godot 4.7.2 executable path")
    root = Path(__file__).resolve().parents[1]
    issues = check_resources(root)
    if issues:
        print("\n".join(issues))
        return 1
    validation = root / "build" / "compatibility-validation"
    cache = validation / ".godot"
    cache.mkdir(parents=True, exist_ok=True)
    (root / "build" / ".gdignore").touch()
    for directory in ("addons", "assets", "resources", "scenes", "scripts", "ui", "telemetry"):
        link_directory(root / directory, validation / directory)
    link_directory(root / ".godot" / "imported", cache / "imported")
    for filename in ("uid_cache.bin", "global_script_class_cache.cfg"):
        source = root / ".godot" / filename
        if not source.exists():
            raise RuntimeError("Import the project in Godot before running validation")
        shutil.copy2(source, cache / filename)
    for filename in ("default_bus_layout.tres", "icon.svg", "icon.svg.import"):
        shutil.copy2(root / filename, validation / filename)
    config = (root / "project.godot").read_text(encoding="utf-8")
    config = re.sub(r'^config/name=.*$', 'config/name="eotr_compatibility_validation"', config, flags=re.M)
    config = re.sub(r'^config/(use_custom_user_dir|custom_user_dir)=.*\n?', '', config, flags=re.M)
    config = re.sub(r'^settings/settings_path=.*\n?', '', config, flags=re.M)
    config += '\n[talo]\n\nsettings/settings_path="res://scripts/tests/talo_offline.cfg"\n'
    (validation / "project.godot").write_text(config, encoding="utf-8")
    env = os.environ.copy()
    user_data = root / "build" / "compatibility-userdata"
    user_data.mkdir(exist_ok=True)
    for variable in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[variable] = str(user_data)
    log_path = root / "build" / "compatibility-smoke.log"
    display_args = ["--windowed", "--position", "-32000,-32000", "--resolution", "1920x1080"] if args.capture_ui else ["--headless"]
    user_args = (["--capture-ui"] if args.capture_ui else []) + (["--ui-transactions-only"] if args.ui_transactions_only else [])
    result = subprocess.run([
        args.godot, *display_args, "--path", str(validation),
        "res://scripts/tests/combat_automation_test.tscn" if args.combat_automation else "res://scripts/tests/compatibility_smoke.tscn", "--quit-after", "20000",
        "--log-file", str(log_path),
    ] + (["--verbose"] if args.verbose else []) + (["--", *user_args] if user_args else []), env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
    output = result.stdout + result.stderr
    print(output)
    # Godot can report a script failure and still return exit code zero.
    success = ("Combat automation tests: 0 failures" if args.combat_automation else "Compatibility smoke test: 0 failures") in output
    allowed_errors = (
        'Condition "!actions.custom_samplers.has(function->arguments[j].tex_builtin)" is true.',
        "Failed to read the root certificate store.",
        "1 resources still in use at exit",
    )
    unexpected_errors = [line for line in output.splitlines() if "ERROR:" in line and not any(
        allowed in line for allowed in allowed_errors
    )]
    return 0 if result.returncode == 0 and success and not unexpected_errors else 1


if __name__ == "__main__":
    sys.exit(main())
