"""Sparse event-aware evidence extraction; FFmpeg is the only external dependency."""
import json
from pathlib import Path
import subprocess


def extract(output, ffmpeg):
    data = json.loads((output / "timing.json").read_text())
    duration = data["duration"]
    # Context plus up to four actions, three samples per action. No inferred impact labels.
    times = {0.5, max(0, duration - 0.2)}
    actions = [e for e in data["events"] if e["kind"] == "action_started"][:4]
    for event in actions:
        times.update(event["time"] + offset for offset in (0, 0.12, 0.35, 0.7))
    frames = output / "frames"
    frames.mkdir(exist_ok=True)
    index = []
    for i, time in enumerate(sorted({round(t, 3) for t in times if 0 <= t < duration})):
        name = f"{i:02d}-{time:.3f}.png"
        subprocess.run([ffmpeg, "-v", "error", "-y", "-ss", str(time), "-i", str(output / "capture.avi"),
                        "-frames:v", "1", str(frames / name)], check=True)
        if not (frames / name).exists():
            raise RuntimeError(f"No video frame at {time}")
        index.append({"time": time, "file": f"frames/{name}"})
    (output / "frames.json").write_text(json.dumps(index, indent=2))
    return index
