"""Static source checks only. Never imports main() or opens service sockets."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent


def main():
    dashboards = list((ROOT / "grafana/dashboards").glob("*.json"))
    assert len(dashboards) == 5
    for path in dashboards:
        dashboard = json.loads(path.read_text())
        assert {v["name"] for v in dashboard["templating"]["list"]} == {"game_id", "environment", "build_version", "source_type"}
        assert dashboard["panels"]
        for panel in dashboard["panels"]:
            query = panel["targets"][0]["rawSql"]
            assert ("events_deduplicated" in query or "telemetry.ingest_health" in query) and "$__timeFilter" in query
    schemas = json.loads((ROOT.parents[1] / "telemetry/schemas/events.json").read_text())
    assert schemas["format_version"] == 1 and len(schemas["events"]) >= 30
    migrations = list((ROOT / "clickhouse/migrations").glob("*.sql"))
    assert len(migrations) == 2
    sql = "\n".join(path.read_text() for path in migrations)
    assert "ReplacingMergeTree" in sql and " FINAL" in sql and "TTL" in sql
    compose = (ROOT / "compose.yaml").read_text()
    assert "127.0.0.1:8080:8080" in compose and "127.0.0.1:3000:3000" in compose
    assert "8123:8123" not in compose and "9000:9000" not in compose
    try:
        import yaml
    except ImportError:
        print("PyYAML unavailable: YAML syntax parsing skipped; structural source checks passed")
    else:
        data = yaml.safe_load(compose)
        assert set(data["services"]) == {"clickhouse", "grafana", "ingest"}
        for path in (ROOT / "grafana/provisioning").rglob("*.yaml"):
            assert yaml.safe_load(path.read_text())["apiVersion"] == 1
    print("Backend artifact static checks passed; no service integration claimed")


if __name__ == "__main__":
    main()
