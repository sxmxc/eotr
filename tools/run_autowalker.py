"""Run actual Godot AutoWalker with isolated saves, local reports and configured telemetry."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid
import tempfile
from qa_storage import MAX_LOG_BYTES, maintain_qa


def wait_for_exit(process, timeout, maintenance=None):
    deadline = None if timeout is None else time.monotonic() + timeout
    next_maintenance = time.monotonic() + 5
    while True:
        returncode = process.poll()
        if returncode is not None:
            return returncode
        remaining = None if deadline is None else deadline - time.monotonic()
        if remaining is not None and remaining <= 0:
            raise subprocess.TimeoutExpired(process.args, timeout)
        if maintenance and time.monotonic() >= next_maintenance:
            maintenance()
            next_maintenance = time.monotonic() + 5
        # Python 3.10's Windows wait() can turn a Ctrl+C retry into a negative
        # native wait timeout. Poll instead so interruption stays under our control.
        time.sleep(0.1 if remaining is None else min(0.1, remaining))


def run_godot(command, env, timeout, stop_file, maintenance=None):
    # Let Python handle Ctrl+C; Godot must leave through its normal SceneTree shutdown.
    isolation = {"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP} if os.name == "nt" else {"start_new_session": True}
    process = subprocess.Popen(command, env=env, **isolation)
    try:
        return wait_for_exit(process, timeout, maintenance)
    except KeyboardInterrupt:
        print("\nAutoWalker interrupted. Closing Godot; completed reports are preserved.", file=sys.stderr)
        stop_file.touch()
        try:
            wait_for_exit(process, 20)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            print("Godot did not finish closing; terminating the process.", file=sys.stderr)
            process.kill()
            process.wait()
        return 130
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        raise
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        stop_file.unlink(missing_ok=True)


def run(temporary):
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
    parser.add_argument("--output", default="qa/autowalker")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    project = root
    userdata = temporary / "userdata"
    userdata.mkdir()
    env = os.environ.copy()
    for name in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[name] = str(userdata)
    output = (root / args.output).resolve()
    if root / 'qa' not in output.parents and output != root / 'qa':
        parser.error('--output must be inside the repository qa/ directory for bounded retention')
    output.mkdir(parents=True, exist_ok=True)
    stop_file = output / f".stop-{uuid.uuid4().hex}"
    storage_stop_at = None

    def maintenance(active=True):
        nonlocal storage_stop_at
        # Never truncate a file while Godot's writer still owns its seek offset.
        maintain_qa(root / 'qa', output, args.replay, trim_log=not active)
        log = output / 'godot.log'
        if active and log.exists() and log.stat().st_size > MAX_LOG_BYTES:
            if storage_stop_at is None:
                storage_stop_at = time.monotonic()
                print('QA log reached 8 MiB; requesting shutdown before trimming it.', file=sys.stderr)
                stop_file.touch()
            elif time.monotonic() - storage_stop_at > 20:
                raise subprocess.TimeoutExpired('Godot log storage limit', 20)

    maintenance(active=False)
    command = [args.godot, *( ["--windowed", "--resolution", "1920x1080"] if args.watch or args.verify_watch else ["--headless"] ), "--path", str(project),
               "res://scenes/developer/autowalker/watch.tscn", "--log-file", str(output / "godot.log"), "--", "--autostart"]
    for key in ("mode", "seed", "policy", "count", "max_turns", "max_actions", "timeout", "encounter"):
        command.append(f"--{key.replace('_', '-')}={getattr(args, key)}")
    command.append(f"--output={output.as_posix()}")
    if args.telemetry_local:
        command.append("--telemetry-local")
        command.append("--validation-local")
    if args.replay:
        command.append(f"--replay={Path(args.replay).resolve().as_posix()}")
    if args.verify_watch:
        command.append("--verify-watch")
    command.append(f"--stop-file={stop_file.as_posix()}")
    started_ns = time.time_ns()
    try:
        returncode = run_godot(command, env, None if args.watch else args.count * (args.timeout + 20) + 30, stop_file, maintenance)
        maintenance(active=False)
    except subprocess.TimeoutExpired:
        maintenance(active=False)
        failure = {"seed": args.seed, "policy": args.policy, "policy_version": "1.0.0", "encounter": args.encounter,
                   "mode": args.mode, "outcome": "launcher_storage_limit" if storage_stop_at is not None else "launcher_timeout",
                   "reason": "Godot exceeded the log storage shutdown deadline" if storage_stop_at is not None else "Godot exceeded the launcher deadline", "trace": []}
        (output / "launcher-failure.json").write_text(json.dumps(failure, indent=2), encoding="utf-8")
        return 2
    if storage_stop_at is not None:
        failure = {"outcome": "launcher_storage_limit", "reason": "Godot log exceeded 8 MiB; completed reports preserved"}
        (output / 'launcher-failure.json').write_text(json.dumps(failure, indent=2), encoding='utf-8')
        return 2
    if returncode == 130:
        return 130
    if not args.watch:
        if not (output / "summary.json").exists() or (output / "summary.json").stat().st_mtime_ns < started_ns:
            return 1
        summary = json.loads((output / "summary.json").read_text(encoding="utf-8"))
        if summary.get("failures", 0):
            return 1
        log = (output / "godot.log").read_text(encoding="utf-8", errors="replace")
        if "SCRIPT ERROR:" in log:
            return 1
    return returncode


def main():
    with tempfile.TemporaryDirectory(prefix="eotr-autowalker-") as directory:
        return run(Path(directory))


if __name__ == "__main__":
    sys.exit(main())
