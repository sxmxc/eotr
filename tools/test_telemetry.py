"""Verify telemetry against the original project with disposable user data."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="eotr-telemetry-") as directory:
    env = os.environ.copy()
    for name in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        env[name] = directory
    result = subprocess.run([
        args.godot, "--headless", "--path", str(root),
        "--script", "res://scripts/tests/telemetry_test.gd",
        "--log-file", str(Path(directory) / "test.log"), "--", "--validation-local",
    ], env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30)
    output = result.stdout + result.stderr
    print(output)
raise SystemExit(0 if result.returncode == 0 and "Telemetry tests: 0 failures" in output and "SCRIPT ERROR" not in output else 1)
