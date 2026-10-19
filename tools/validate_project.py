"""Run the migration smoke scene with isolated saves and Null telemetry delivery.

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
from qa_storage import maintain_qa

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
    parser.add_argument("--battlefield-only", action="store_true", help="Focused grid and Phantom Camera checks; one capture with --capture-ui")
    parser.add_argument("--terrain-only", action="store_true", help="Native terrain boundary and collapse validation")
    parser.add_argument("--motion-review", action="store_true", help="Record bounded native combat and collapse at 60 fps")
    parser.add_argument("--utility-review", action="store_true", help="Focused actual Phase Step and translucent shield review")
    parser.add_argument("--vfx-only", action="store_true", help="Focused ambient, transition, shader alpha and resource checks")
    parser.add_argument("--map-only", action="store_true", help="Focused route readability and connection checks")
    parser.add_argument("--autowalker-controls", action="store_true")
    parser.add_argument("--autowalker-telemetry", action="store_true", help="Test bot upload/local routing with a fake transport; no backend access")
    parser.add_argument("--capture-ui", action="store_true", help="Run the native renderer offscreen and save UI captures")
    parser.add_argument("--ui-transactions-only", action="store_true", help="Run only reward and shop interaction checks")
    parser.add_argument("--event-room-only", action="store_true", help="Run only event choice and affordability checks")
    args = parser.parse_args()
    if args.terrain_only and not args.capture_ui:
        parser.error("--terrain-only requires --capture-ui for the native breakup checks")
    if args.motion_review and not (args.capture_ui and args.combat_automation):
        parser.error("--motion-review requires --capture-ui and --combat-automation")
    if not args.godot or Path(args.godot).suffix.lower() in (".cmd", ".bat"):
        parser.error("Pass --godot with the Godot 4.7.2 executable path")
    root = Path(__file__).resolve().parents[1]
    maintain_qa(root / '.qa-tmp')
    issues = check_resources(root)
    if issues:
        print("\n".join(issues))
        return 1
    validation = root / ".qa-tmp" / "compatibility-validation"
    cache = validation / ".godot"
    cache.mkdir(parents=True, exist_ok=True)
    (root / ".qa-tmp" / ".gdignore").touch()
    (validation / "qa").mkdir(exist_ok=True)
    (validation / "qa" / ".gdignore").touch()
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
    config = re.sub(r'^\[telemetry\]\n.*?(?=^\[|\Z)', '', config, flags=re.M | re.S)
    config += '\n[telemetry]\n\nconfig_path="res://scripts/tests/telemetry_null.tres"\n'
    (validation / "project.godot").write_text(config, encoding="utf-8")
    env = os.environ.copy()
    user_data = root / ".qa-tmp" / "compatibility-userdata"
    user_data.mkdir(exist_ok=True)
    for variable in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[variable] = str(user_data)
    log_path = root / ".qa-tmp" / "compatibility-smoke.log"
    display_args = ["--windowed", "--position", "-32000,-32000", "--resolution", "1920x1080"] if args.capture_ui else ["--headless"]
    if args.motion_review:
        display_args = ["--windowed", "--position", "-32000,-32000", "--resolution", "1280x720", "--write-movie", str(root / ".qa-tmp/combat-motion.avi"), "--fixed-fps", "60"]
    user_args = (["--capture-ui"] if args.capture_ui else []) + (["--ui-transactions-only"] if args.ui_transactions_only else [])
    if args.event_room_only:
        user_args.append("--event-room-only")
    if args.battlefield_only:
        user_args.append("--battlefield-only")
    if args.terrain_only:
        user_args.extend(["--battlefield-only", "--terrain-only"])
    if args.motion_review:
        user_args.extend(["--battlefield-only", "--motion-review"])
    if args.utility_review:
        user_args.extend(["--battlefield-only", "--utility-review"])
    if args.vfx_only:
        user_args.append("--vfx-only")
    if args.map_only:
        user_args.append("--map-only")
    if args.autowalker_telemetry:
        user_args.append("--telemetry-only")
    result = subprocess.run([
        args.godot, *display_args, "--path", str(validation),
        "res://scripts/tests/autowalker_controls_test.tscn" if args.autowalker_controls or args.autowalker_telemetry else ("res://scripts/tests/combat_automation_test.tscn" if args.combat_automation else "res://scripts/tests/compatibility_smoke.tscn"), "--quit-after", "20000",
        "--log-file", str(log_path),
    ] + (["--verbose"] if args.verbose else []) + (["--", *user_args] if user_args else []), env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
    output = result.stdout + result.stderr
    print(output)
    maintain_qa(root / '.qa-tmp')
    # Godot can report a script failure and still return exit code zero.
    success = ("AutoWalker telemetry tests: 0 failures" if args.autowalker_telemetry else ("AutoWalker controls tests: 0 failures" if args.autowalker_controls else ("Combat automation tests: 0 failures" if args.combat_automation else "Compatibility smoke test: 0 failures"))) in output
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
