"""Align real action boundaries and make side-by-side evidence for human/agent review."""
import json
from pathlib import Path
import subprocess


def compare(baseline, revised, ffmpeg):
    a, b = [json.loads((p / "timing.json").read_text()) for p in (baseline, revised)]
    ea, eb = [[e for e in d["events"] if e["kind"] == "action_started"] for d in (a, b)]
    rows = []
    for i in range(max(len(ea), len(eb))):
        x = ea[i] if i < len(ea) else None
        y = eb[i] if i < len(eb) else None
        rows.append({"index": i, "baseline": x, "revised": y,
                     "same_action": bool(x and y and x["details"] == y["details"]),
                     "start_delta": y["time"] - x["time"] if x and y else None})
    setup_keys = ("seed", "encounter", "fps", "engine", "renderer", "viewport")
    report = {"setup_matches": all(a.get(k) == b.get(k) for k in setup_keys),
              "unrecorded_setup_fields": [k for k in setup_keys if k not in a or k not in b],
              "final_state_matches": a.get("state") == b.get("state"),
              "duration_delta": b["duration"] - a["duration"],
              "actions": rows, "note": "Action alignment is diagnostic. Inspect motion for missing feedback; no metric rates artistic quality."}
    (revised / "comparison.json").write_text(json.dumps(report, indent=2))
    subprocess.run([ffmpeg, "-v", "error", "-y", "-i", str(baseline / "capture.avi"),
                    "-i", str(revised / "capture.avi"), "-filter_complex",
                    "[0:v]scale=640:360[a];[1:v]scale=640:360[b];[a][b]hstack=shortest=1[v]",
                    "-map", "[v]", "-an", str(revised / "comparison.mp4")], check=True)
    return report
