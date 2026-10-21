"""Rendered Movie Writer capture using the existing AutoWalker, with isolated saves."""
import json
import os
from pathlib import Path
import tempfile
import subprocess
import sys
import hashlib

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))


def _capture(scenario, output, godot, temporary):
    if sys.platform.startswith("linux") and not (os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY")):
        raise RuntimeError("No display: run under xvfb-run -a with Mesa/OpenGL installed. Headless does not capture VFX.")
    project = ROOT
    if not (ROOT / ".godot/global_script_class_cache.cfg").exists():
        raise RuntimeError("Open this project in Godot and complete imports first.")
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[key] = str(temporary)
    command = [godot, "--path", str(project), "--windowed", "--resolution", "1280x720",
               "--write-movie", str(output / "capture.avi"), "--fixed-fps", str(scenario["fps"]),
               "--log-file", str(output / "godot.log"),
               "res://scenes/developer/visual_test/visual_test.tscn", "--", "--telemetry-local", "--validation-local",
               f"--output={output.as_posix()}"]
    for key in ("seed", "encounter", "policy", "duration"):
        command.append(f"--{key}={scenario[key]}")
    if scenario.get("replay"):
        replay = Path(scenario["replay"]).resolve()
        command.append(f"--replay={replay.as_posix()}")
    if scenario.get("fixture"):
        if scenario["fixture"] != "ruin":
            raise ValueError("Unknown visual fixture")
        command.append("--fixture=ruin")
    (output / "command.json").write_text(json.dumps(command, indent=2))
    with (output / "console.log").open("w") as log:
        subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT,
                       timeout=max(120, scenario["duration"] * 20), check=True)
    log = (output / "godot.log").read_text(encoding="utf-8", errors="replace")
    if "SCRIPT ERROR:" in log or not (output / "timing.json").exists():
        raise RuntimeError(f"Capture failed; inspect {output / 'godot.log'}")
    data = json.loads((output / "timing.json").read_text())
    data["fps"] = scenario["fps"]
    data["scenario"] = scenario
    data["source_hashes"] = {str(p.relative_to(ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest()
                             for base in ("ui/fx", "scripts/shaders") for p in (ROOT / base).glob("*") if p.is_file()}
    data["git_commit"] = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    (output / "timing.json").write_text(json.dumps(data, indent=2))
    return data


def capture(scenario, output, godot):
    with tempfile.TemporaryDirectory(prefix="eotr-capture-") as directory:
        return _capture(scenario, output, godot, Path(directory))
