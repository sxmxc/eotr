"""Static source checks only. Never imports main() or opens service sockets."""
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

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
    assert '"8080:8080"' in compose and '"3000:3000"' in compose
    assert "8123:8123" not in compose and "9000:9000" not in compose
    users_path = "clickhouse/users.d/telemetry.xml"
    assert f"./{users_path}:/etc/clickhouse-server/users.d/telemetry.xml:ro" in compose
    users = ET.parse(ROOT / users_path).getroot()
    for name, password_var, grants in (
        ("telemetry_ingest", "TELEMETRY_INGEST_PASSWORD", {
            "GRANT INSERT ON telemetry.events", "GRANT INSERT ON telemetry.ingest_health"}),
        ("grafana_reader", "TELEMETRY_READ_PASSWORD", {
            "GRANT SELECT ON telemetry.events", "GRANT SELECT ON telemetry.events_deduplicated",
            "GRANT SELECT ON telemetry.ingest_health"}),
    ):
        user = users.find(f"users/{name}")
        assert user is not None
        assert user.find("password").attrib == {"from_env": password_var}
        assert {query.text for query in user.findall("grants/query")} == grants
    assert users.findtext("profiles/telemetry_reader/readonly") == "1"
    timeout = users.find("profiles/telemetry_reader/constraints/max_execution_time")
    assert timeout.find("changeable_in_readonly") is not None
    assert timeout.findtext("min") == "1" and timeout.findtext("max") == "60"
    server_path = "clickhouse/config.d/telemetry.xml"
    assert f"./{server_path}:/etc/clickhouse-server/config.d/telemetry.xml:ro" in compose
    assert ET.parse(ROOT / server_path).findtext("access_control_improvements/settings_constraints_replace_previous") == "true"
    assert 'TELEMETRY_INGEST_PASSWORD: ${CLICKHOUSE_PASSWORD:?' in compose
    assert 'TELEMETRY_READ_PASSWORD: ${CLICKHOUSE_READ_PASSWORD:?' in compose
    try:
        import yaml
    except ImportError:
        print("PyYAML unavailable: YAML syntax parsing skipped; structural source checks passed")
    else:
        data = yaml.safe_load(compose)
        assert set(data["services"]) == {"clickhouse", "grafana", "ingest"}
        datasource = yaml.safe_load((ROOT / "grafana/provisioning/datasources/clickhouse.yaml").read_text())["datasources"][0]
        assert datasource["jsonData"]["username"] == "grafana_reader"
        assert datasource["secureJsonData"]["password"] == "$CLICKHOUSE_READ_PASSWORD"
        for path in (ROOT / "grafana/provisioning").rglob("*.yaml"):
            assert yaml.safe_load(path.read_text())["apiVersion"] == 1
    print("Backend artifact static checks passed; no service integration claimed")


if __name__ == "__main__":
    main()
