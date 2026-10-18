"""Run actual Godot AutoWalker with isolated saves, local reports and configured telemetry."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from validate_project import link_directory


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--telemetry-local", action="store_true", help="Keep QA telemetry local without contacting the configured backend")
    parser.add_argument("--verify-watch", action="store_true", help="Run rendered playback, save a capture and exit after the simulation")
    parser.add_argument("--mode", choices=["encounter", "run"], default="encounter")
    parser.add_argument("--replay")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--policy", choices=["random", "greedy", "stress"], default="greedy")
    parser.add_argument("--count", type=int, default=1)
    parser.add_argument("--max-turns", type=int, default=50)
    parser.add_argument("--max-actions", type=int, default=500)
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--encounter", default="res://resources/data/battles/tier_1_channelers_bulwark.tres")
    parser.add_argument("--output", default="build/autowalker")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    project = root / "build/autowalker-project"
    cache = project / ".godot"
    cache.mkdir(parents=True, exist_ok=True)
    (root / "build/.gdignore").touch()
    for directory in ("addons", "assets", "resources", "scenes", "scripts", "ui", "telemetry"):
        link_directory(root / directory, project / directory)
    link_directory(root / ".godot/imported", cache / "imported")
    for filename in ("uid_cache.bin", "global_script_class_cache.cfg"):
        shutil.copy2(root / ".godot" / filename, cache / filename)
    for filename in ("default_bus_layout.tres", "icon.svg", "icon.svg.import"):
        shutil.copy2(root / filename, project / filename)
    config = (root / "project.godot").read_text(encoding="utf-8")
    config = re.sub(r'^config/name=.*$', 'config/name="eotr_autowalker"', config, flags=re.M)
    config = re.sub(r'^config/(use_custom_user_dir|custom_user_dir)=.*\n?', '', config, flags=re.M)
    if args.telemetry_local:
        config = re.sub(r'^\[telemetry\]\n.*?(?=^\[|\Z)', '', config, flags=re.M | re.S)
        config += '\n[telemetry]\n\nconfig_path="res://scripts/tests/telemetry_null.tres"\n'
    (project / "project.godot").write_text(config, encoding="utf-8")
    userdata = root / "build/autowalker-userdata"
    userdata.mkdir(exist_ok=True)
    env = os.environ.copy()
    for name in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[name] = str(userdata)
    output = (root / args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    command = [args.godot, *( ["--windowed", "--resolution", "1920x1080"] if args.watch or args.verify_watch else ["--headless"] ), "--path", str(project),
               "res://scenes/developer/autowalker/watch.tscn", "--log-file", str(output / "godot.log"), "--", "--autostart"]
    for key in ("mode", "seed", "policy", "count", "max_turns", "max_actions", "timeout", "encounter"):
        command.append(f"--{key.replace('_', '-')}={getattr(args, key)}")
    command.append(f"--output={output.as_posix()}")
    if args.telemetry_local:
        command.append("--telemetry-local")
    if args.replay:
        command.append(f"--replay={Path(args.replay).resolve().as_posix()}")
    if args.verify_watch:
        command.append("--verify-watch")
    started_ns = time.time_ns()
    try:
        result = subprocess.run(command, env=env, timeout=None if args.watch else args.count * (args.timeout + 20) + 30)
    except subprocess.TimeoutExpired:
        failure = {"seed": args.seed, "policy": args.policy, "policy_version": "1.0.0", "encounter": args.encounter,
                   "mode": args.mode, "outcome": "launcher_timeout", "reason": "Godot exceeded the launcher deadline", "trace": []}
        (output / "launcher-failure.json").write_text(json.dumps(failure, indent=2), encoding="utf-8")
        return 2
    if not args.watch:
        if not (output / "summary.json").exists() or (output / "summary.json").stat().st_mtime_ns < started_ns:
            return 1
        summary = json.loads((output / "summary.json").read_text(encoding="utf-8"))
        if summary.get("failures", 0):
            return 1
        log = (output / "godot.log").read_text(encoding="utf-8", errors="replace")
        if "SCRIPT ERROR:" in log:
            return 1
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
