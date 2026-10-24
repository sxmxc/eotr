"""Run the migration smoke scene with isolated saves and Null telemetry delivery.

Usage: python tools/validate_project.py --godot /path/to/godot[.exe]
Requires an editor import of the real project first. Does not modify project.godot.
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from check_scene_resources import check_resources


def run_validation(temporary: Path) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot"))
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--combat-automation", action="store_true")
    parser.add_argument("--synthforged", action="store_true", help="Synthforged card, Overclock, Analyze and construct lifecycle checks")
    parser.add_argument("--status-lifecycle", action="store_true", help="Focused status expiration and modifier cleanup checks")
    parser.add_argument("--board-queries", action="store_true", help="Profile real encounter occupancy and movement queries")
    parser.add_argument("--attack-cancellation-only", action="store_true", help="Focused lunge cancellation checks; requires --combat-automation")
    parser.add_argument("--card-lifecycle-only", action="store_true", help="Lethal movement card teardown regression")
    parser.add_argument("--mana-wells-only", action="store_true", help="Focused mana well visibility and native visual review")
    parser.add_argument("--battlefield-only", action="store_true", help="Focused grid and Phantom Camera checks; one capture with --capture-ui")
    parser.add_argument("--terrain-only", action="store_true", help="Native terrain boundary and collapse validation")
    parser.add_argument("--motion-review", action="store_true", help="Record bounded native combat and collapse at 60 fps")
    parser.add_argument("--utility-review", action="store_true", help="Focused actual Phase Step and translucent shield review")
    parser.add_argument("--vfx-only", action="store_true", help="Focused ambient, transition, shader alpha and resource checks")
    parser.add_argument("--map-only", action="store_true", help="Focused route readability and connection checks")
    parser.add_argument("--autowalker-controls", action="store_true")
    parser.add_argument("--autowalker-telemetry", action="store_true", help="Test bot upload/local routing with a fake transport; no backend access")
    parser.add_argument("--capture-ui", action="store_true", help="Run the native renderer offscreen and save UI captures")
    parser.add_argument("--settings-rail-only", action="store_true", help="Settings persistence, pause access, fog placeholders and enemy rail checks")
    parser.add_argument("--ui-transactions-only", action="store_true", help="Run only reward and shop interaction checks")
    parser.add_argument("--event-room-only", action="store_true", help="Run only event choice and affordability checks")
    args = parser.parse_args()
    if args.attack_cancellation_only and not args.combat_automation:
        parser.error("--attack-cancellation-only requires --combat-automation")
    if args.terrain_only and not args.capture_ui:
        parser.error("--terrain-only requires --capture-ui for the native breakup checks")
    if args.motion_review and not (args.capture_ui and args.combat_automation):
        parser.error("--motion-review requires --capture-ui and --combat-automation")
    if not args.godot or Path(args.godot).suffix.lower() in (".cmd", ".bat"):
        parser.error("Pass --godot with the Godot 4.7.2 executable path")
    root = Path(__file__).resolve().parents[1]
    issues = check_resources(root)
    if issues:
        print("\n".join(issues))
        return 1
    env = os.environ.copy()
    user_data = temporary / "userdata"
    user_data.mkdir(exist_ok=True)
    for variable in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[variable] = str(user_data)
    log_path = temporary / "compatibility-smoke.log"
    display_args = ["--windowed", "--position", "-32000,-32000", "--resolution", "1920x1080"] if args.capture_ui else ["--headless"]
    if args.motion_review:
        display_args = ["--windowed", "--position", "-32000,-32000", "--resolution", "1280x720", "--write-movie", str(temporary / "combat-motion.avi"), "--fixed-fps", "60"]
    user_args = (["--capture-ui"] if args.capture_ui else []) + (["--ui-transactions-only"] if args.ui_transactions_only else [])
    if args.attack_cancellation_only:
        user_args.append("--attack-cancellation-only")
    if args.card_lifecycle_only:
        user_args.append("--card-lifecycle-only")
    if args.mana_wells_only:
        user_args.append("--mana-wells-only")
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
    if args.settings_rail_only:
        test_scene, success_marker = "settings_rail_test", "Settings and rail tests: 0 failures"
    elif args.synthforged:
        test_scene, success_marker = "synthforged_test", "Synthforged tests: 0 failures"
    elif args.board_queries:
        test_scene, success_marker = "board_queries_test", "Board query tests: 0 failures"
    elif args.status_lifecycle:
        test_scene, success_marker = "status_lifecycle_test", "Status lifecycle tests: 0 failures"
    elif args.autowalker_telemetry:
        test_scene, success_marker = "autowalker_controls_test", "AutoWalker telemetry tests: 0 failures"
    elif args.autowalker_controls:
        test_scene, success_marker = "autowalker_controls_test", "AutoWalker controls tests: 0 failures"
    elif args.combat_automation:
        test_scene, success_marker = "combat_automation_test", "Combat automation tests: 0 failures"
    else:
        test_scene, success_marker = "compatibility_smoke", "Compatibility smoke test: 0 failures"
    result = subprocess.run([
        args.godot, *display_args, "--path", str(root),
        f"res://scripts/tests/{test_scene}.tscn", "--quit-after", "20000",
        "--log-file", str(log_path),
    ] + (["--verbose"] if args.verbose else []) + ["--", "--validation-local", *user_args], env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
    output = result.stdout + result.stderr
    print(output)
    # Godot can report a script failure and still return exit code zero.
    success = success_marker in output
    allowed_errors = (
        'Condition "!actions.custom_samplers.has(function->arguments[j].tex_builtin)" is true.',
        "Failed to read the root certificate store.",
        "1 resources still in use at exit",
    )
    unexpected_errors = [line for line in output.splitlines() if "ERROR:" in line and not any(
        allowed in line for allowed in allowed_errors
    )]
    return 0 if result.returncode == 0 and success and not unexpected_errors else 1


def main() -> int:
    # Run the actual project. Only disposable user data and logs need isolation.
    with tempfile.TemporaryDirectory(prefix="eotr-validation-") as directory:
        return run_validation(Path(directory))


if __name__ == "__main__":
    sys.exit(main())
