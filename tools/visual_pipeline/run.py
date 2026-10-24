"""Capture a real combat scenario, extract evidence, and prepare an honest review."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from capture import ROOT, capture
from extract_frames import extract
from compare import compare


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scenario", help="Scenario name or JSON path")
    parser.add_argument("--godot", default=os.getenv("GODOT", shutil.which("godot")))
    parser.add_argument("--ffmpeg", default=os.getenv("FFMPEG", shutil.which("ffmpeg")))
    parser.add_argument("--label", required=True, help="New evidence directory name")
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--evidence-only", action="store_true", help="Extract/review an existing label after a capture or dependency failure")
    args = parser.parse_args()
    try:
        source = Path(args.scenario)
        if not source.is_file(): source = Path(__file__).parent / "scenarios" / f"{args.scenario}.json"
        scenario = json.loads(source.read_text(encoding="utf-8"))
        stills_only = bool(scenario.get("stills_only"))
        if stills_only and args.baseline:
            raise ValueError("Movie comparison requires a movie scenario.")
        if not args.godot or (not stills_only and not args.ffmpeg):
            raise ValueError("Supply --godot; movie scenarios also require --ffmpeg (or GODOT/FFMPEG).")
        if Path(args.label).name != args.label or args.label in (".", ".."):
            raise ValueError("--label must be a single directory name")
        if not stills_only:
            demuxers = subprocess.run([args.ffmpeg, "-hide_banner", "-demuxers"], capture_output=True, text=True, check=True).stdout
            filters = subprocess.run([args.ffmpeg, "-hide_banner", "-filters"], capture_output=True, text=True, check=True).stdout
            if " avi " not in demuxers or "hstack" not in filters:
                raise ValueError("FFmpeg needs AVI demuxing, PNG encoding and hstack; use a full build, not a vendor-trimmed binary.")
        if not 0 < scenario["duration"] <= 120 or not 1 <= scenario["fps"] <= 60:
            raise ValueError("duration must be 0..120 seconds, fps 1..60")
        output = ROOT / ".qa-tmp/visual" / args.label
        if (ROOT / "ai/visual/reviews" / f"{args.label}.md").exists():
            raise ValueError("Review already exists; use a new label")
        if not args.evidence_only:
            output.mkdir(parents=True, exist_ok=False)
        (ROOT / ".qa-tmp/.gdignore").touch()
        if args.evidence_only:
            scenario = json.loads((output / "scenario.json").read_text())
        else:
            (output / "scenario.json").write_text(json.dumps(scenario, indent=2))
        data = json.loads((output / "timing.json").read_text()) if args.evidence_only else capture(scenario, output, args.godot)
        frames = list(output.glob("*.png")) if stills_only else extract(output, args.ffmpeg)
        if not frames:
            raise RuntimeError("Capture produced no rendered evidence")
        if args.baseline:
            compare(args.baseline.resolve(), output, args.ffmpeg)
        expected = scenario.get("expect_card")
        found = not expected or any(e["details"].get("name") == expected for e in data["events"])
        if scenario.get("fixture") == "synthforged":
            completed = [e for e in data["events"] if e["kind"] == "fixture_completed"]
            found = found and bool(completed) and not completed[-1]["details"].get("failures")
        review = ROOT / "ai/visual/reviews" / f"{args.label}.md"
        if review.exists(): raise ValueError(f"Review already exists: {review}")
        review.write_text(f"# {scenario['event']} — {args.label}\n\nStatus: awaiting visual inspection.\n\nEvidence: `{output.relative_to(ROOT).as_posix()}`; {len(frames)} frames.\nExpected event observed: {found}.\n\n## Inspection\nRecord files/timestamps actually inspected and video/frame limitations.\n\n## Findings\nFor each: severity, time, observation, intended result, correction.\n\n## Regression checks\nHit reactions; combat feedback; spell identity; camera impulses; targeting highlights; tile edge synchronization; collapse; atmosphere; animation timing. Mark each observed / failed / not exercised.\n\n## Decision\nPending artistic review; successful capture is not visual acceptance.\n", encoding="utf-8")
        print(output)
        if not found: raise RuntimeError(f"Expected event {expected!r} absent; choose a suitable seed or replay.")
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"visual pipeline: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
