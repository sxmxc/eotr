"""Verify the addon in an isolated Godot project containing no game/autoload code."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
from validate_project import link_directory
from qa_storage import maintain_qa

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
maintain_qa(root / 'qa')
project = root / "qa/telemetry-standalone"
(project / "addons").mkdir(parents=True, exist_ok=True)
(root / "qa/.gdignore").touch()
(project / "qa").mkdir(exist_ok=True)
(project / "qa/.gdignore").touch()
link_directory(root / "addons/godot_telemetry", project / "addons/godot_telemetry")
shutil.copy2(root / "scripts/tests/telemetry_test.gd", project / "test.gd")
(project / "project.godot").write_text('config_version=5\n[application]\nconfig/name="telemetry_standalone_test"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
result = subprocess.run([args.godot, "--headless", "--path", str(project), "--script", "res://test.gd", "--log-file", str(project / "test.log")], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30)
output = result.stdout + result.stderr
print(output)
maintain_qa(root / 'qa')
raise SystemExit(0 if result.returncode == 0 and "Telemetry tests: 0 failures" in output and "SCRIPT ERROR" not in output else 1)
