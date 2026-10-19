"""Rendered Movie Writer capture using the existing AutoWalker, with isolated saves."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import hashlib

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from validate_project import link_directory


def capture(scenario, output, godot):
    if sys.platform.startswith("linux") and not (os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY")):
        raise RuntimeError("No display: run under xvfb-run -a with Mesa/OpenGL installed. Headless does not capture VFX.")
    # Fail before an expensive capture if a vendor-trimmed FFmpeg lacks required features.
    project = output / "project"
    cache = project / ".godot"
    cache.mkdir(parents=True)
    for name in ("addons", "assets", "resources", "scenes", "scripts", "ui", "telemetry"):
        link_directory(ROOT / name, project / name)
    if not (ROOT / ".godot/global_script_class_cache.cfg").exists():
        raise RuntimeError("Open this project in Godot and complete imports first.")
    link_directory(ROOT / ".godot/imported", cache / "imported")
    for name in ("uid_cache.bin", "global_script_class_cache.cfg"):
        shutil.copy2(ROOT / ".godot" / name, cache / name)
    for name in ("icon.svg", "icon.svg.import", "default_bus_layout.tres"):
        shutil.copy2(ROOT / name, project / name)
    config = (ROOT / "project.godot").read_text(encoding="utf-8")
    config = re.sub(r'^config/name=.*$', 'config/name="eotr_visual"', config, flags=re.M)
    config = re.sub(r'^config/(use_custom_user_dir|custom_user_dir)=.*\n?', '', config, flags=re.M)
    config = re.sub(r'^\[telemetry\]\n.*?(?=^\[|\Z)', '', config, flags=re.M | re.S)
    config += '\n[telemetry]\nconfig_path="res://scripts/tests/telemetry_null.tres"\n'
    (project / "project.godot").write_text(config, encoding="utf-8")
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[key] = str(output / "userdata")
    command = [godot, "--path", str(project), "--windowed", "--resolution", "1280x720",
               "--write-movie", str(output / "capture.avi"), "--fixed-fps", str(scenario["fps"]),
               "--log-file", str(output / "godot.log"),
               "res://scenes/developer/visual_test/visual_test.tscn", "--", "--telemetry-local",
               f"--output={output.as_posix()}"]
    for key in ("seed", "encounter", "policy", "duration"):
        command.append(f"--{key}={scenario[key]}")
    if scenario.get("replay"):
        replay = Path(scenario["replay"]).resolve()
        command.append(f"--replay={replay.as_posix()}")
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
