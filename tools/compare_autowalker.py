"""Compare matched simulation seeds; descriptive differences are not regression verdicts."""
import argparse
import json
from pathlib import Path
from statistics import mean


def read(directory):
    records = {}
    for path in Path(directory).glob("simulation-*.json"):
        value = json.loads(path.read_text(encoding="utf-8"))
        key = (value["seed"], value["encounter"], value["policy"], value["policy_version"], value.get("mode", "encounter"))
        records[key] = value
    return records


def compare(before, after):
    common = sorted(before.keys() & after.keys())
    result = {"source_type": "bot", "matched_simulations": len(common), "unmatched_before": len(before.keys() - after.keys()),
              "unmatched_after": len(after.keys() - before.keys()), "metrics": {}}
    for metric in ("turns", "damage_taken", "duration_ms", "summons", "ai_invalid_decisions", "invalid_actions"):
        if common:
            left = mean(before[k].get(metric, 0) for k in common)
            right = mean(after[k].get(metric, 0) for k in common)
            result["metrics"][metric] = {"before": left, "after": right, "delta": right - left}
    result["outcome_changes"] = [{"seed": k[0], "policy": k[2], "before": before[k]["outcome"], "after": after[k]["outcome"]}
                                 for k in common if before[k]["outcome"] != after[k]["outcome"]]
    result["note"] = "Descriptive matched-seed comparison; policy versions must match. Statistical changes alone are not regressions."
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before")
    parser.add_argument("after")
    parser.add_argument("--output")
    args = parser.parse_args()
    text = json.dumps(compare(read(args.before), read(args.after)), indent=2)
    if args.output:
        Path(args.output).write_text(text, encoding="utf-8")
    print(text)
