"""Public-client telemetry ingestion. Importing this module never starts a service."""
from __future__ import annotations

import base64
from collections import OrderedDict
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import math
import os
from pathlib import Path
import re
import threading
import time
from urllib.error import URLError
from urllib.request import Request, urlopen

MAX_BODY = 1_048_576
MAX_EVENTS = 100
HEX_ID = re.compile(r"^[0-9a-f]{32}$")
ENVELOPE = {"event_id", "event_name", "schema_version", "timestamp", "game_id", "environment", "build_version", "session_id", "run_id", "source_type", "metadata", "properties"}


def validate_properties(props, schema):
    if not isinstance(props, dict):
        raise ValueError("properties must be an object")
    if any(key not in props for key in schema.get("required", [])):
        raise ValueError("missing required property")
    types = {"string": str, "number": (int, float), "integer": (int, float), "boolean": bool, "object": dict, "array": list, "null": type(None)}
    for key, value in props.items():
        rule = schema.get("properties", {}).get(key)
        if rule is None:
            if not schema.get("additionalProperties", False):
                raise ValueError("unknown property")
            continue
        kind = rule.get("type")
        if kind in types and (not isinstance(value, types[kind]) or (kind in ("number", "integer") and isinstance(value, bool))):
            raise ValueError("property type mismatch")
        if kind == "integer" and value != math.floor(value):
            raise ValueError("integer required")
        if isinstance(value, (float, int)) and not isinstance(value, bool):
            if not math.isfinite(value) or value < rule.get("minimum", -math.inf):
                raise ValueError("invalid numeric value")
        if isinstance(value, str) and len(value) > rule.get("maxLength", 4096):
            raise ValueError("property too long")
        if "enum" in rule and value not in rule["enum"]:
            raise ValueError("invalid enum")


def validate_event(event, schemas, allowed_games):
    if not isinstance(event, dict) or set(event) != ENVELOPE:
        raise ValueError("invalid envelope fields")
    for field in ENVELOPE - {"schema_version", "properties", "metadata"}:
        if not isinstance(event[field], str) or len(event[field]) > 256:
            raise ValueError("invalid envelope string")
    if not HEX_ID.fullmatch(event["event_id"]) or not HEX_ID.fullmatch(event["session_id"]):
        raise ValueError("invalid event/session ID")
    if event["game_id"] not in allowed_games or event["source_type"] not in ("human", "bot"):
        raise ValueError("unknown game/source")
    if not isinstance(event["metadata"], dict) or len(json.dumps(event["metadata"])) > 4096:
        raise ValueError("invalid metadata")
    if not event["timestamp"].endswith("Z"):
        raise ValueError("UTC timestamp required")
    stamp = datetime.fromisoformat(event["timestamp"].replace("Z", "+00:00"))
    if abs((datetime.now(timezone.utc) - stamp).total_seconds()) > 86400 * 7:
        raise ValueError("timestamp outside seven-day ingestion window")
    schema = schemas.get(event["event_name"])
    if schema and "versions" in schema:
        schema = schema["versions"].get(str(event["schema_version"]))
    if not schema or type(event["schema_version"]) is not int or event["schema_version"] != schema["version"]:
        raise ValueError("unknown event/schema version")
    validate_properties(event["properties"], schema)
    # JSON serialization catches non-finite numbers recursively, including legacy props.
    if len(json.dumps(event, allow_nan=False).encode()) > 16384:
        raise ValueError("event too large")


class RateLimiter:
    """Bounded per-address minute windows; reverse proxy owns global/concurrency limits."""
    def __init__(self, limit=120, capacity=10000, clock=time.monotonic):
        self.limit, self.capacity, self.clock = limit, capacity, clock
        self.windows = OrderedDict()
        self.lock = threading.Lock()

    def allow(self, key):
        now = self.clock()
        with self.lock:
            start, used = self.windows.pop(key, (now, 0))
            if now - start >= 60:
                start, used = now, 0
            self.windows[key] = (start, used + 1)
            while len(self.windows) > self.capacity:
                self.windows.popitem(last=False)
            return used < self.limit


class ClickHouse:
    def __init__(self):
        self.endpoint = os.environ.get("CLICKHOUSE_URL", "http://clickhouse:8123/")
        self.user = os.environ.get("CLICKHOUSE_USER", "ingest")
        self.password = os.environ.get("CLICKHOUSE_PASSWORD", "")

    def insert(self, events):
        lines = []
        for event in events:
            row = dict(event)
            row["properties"] = json.dumps(row["properties"], separators=(",", ":"), allow_nan=False)
            row["metadata"] = json.dumps(row["metadata"], separators=(",", ":"), allow_nan=False)
            lines.append(json.dumps(row, allow_nan=False))
        body = ("INSERT INTO telemetry.events FORMAT JSONEachRow\n" + "\n".join(lines)).encode()
        auth = base64.b64encode(f"{self.user}:{self.password}".encode()).decode()
        request = Request(self.endpoint, data=body, headers={"Authorization": f"Basic {auth}"}, method="POST")
        with urlopen(request, timeout=8) as response:
            response.read(4096)

    def insert_health(self, counters):
        row = {"timestamp": datetime.now(timezone.utc).isoformat(), **counters}
        body = ("INSERT INTO telemetry.ingest_health FORMAT JSONEachRow\n" + json.dumps(row)).encode()
        auth = base64.b64encode(f"{self.user}:{self.password}".encode()).decode()
        with urlopen(Request(self.endpoint, data=body, headers={"Authorization": f"Basic {auth}"}), timeout=8) as response:
            response.read(4096)


class Ingestor:
    def __init__(self, schemas, store, allowed_games=("echoes_of_the_rift",), limiter=None):
        self.schemas, self.store = schemas, store
        self.allowed_games = set(allowed_games)
        self.limiter = limiter or RateLimiter()
        self.metrics = {"requests": 0, "accepted": 0, "rejected": 0, "storage_failures": 0, "rate_limited": 0}
        self.lock = threading.Lock()

    def count(self, name, amount=1):
        with self.lock:
            self.metrics[name] += amount

    def handle(self, body, address):
        self.count("requests")
        if not self.limiter.allow(address):
            self.count("rate_limited")
            return 429, {"error": "rate limit", "retryable": True}
        if len(body) > MAX_BODY:
            self.count("rejected")
            return 413, {"error": "request too large", "retryable": False}
        try:
            payload = json.loads(body, parse_constant=lambda _: (_ for _ in ()).throw(ValueError("non-finite JSON")))
            if not isinstance(payload, dict) or set(payload) != {"events"}:
                raise ValueError("expected events batch")
            events = payload["events"]
            if not isinstance(events, list) or not 1 <= len(events) <= MAX_EVENTS:
                raise ValueError("batch size must be 1..100")
            for event in events:
                validate_event(event, self.schemas, self.allowed_games)
        except (ValueError, TypeError, KeyError, OverflowError, RecursionError) as exc:
            self.count("rejected")
            return 400, {"error": str(exc)[:200], "retryable": False}
        # Whole-batch acceptance. Stable IDs plus the FINAL view deduplicate retries.
        unique = {(event["game_id"], event["event_id"]): event for event in events}
        try:
            self.store.insert(list(unique.values()))
        except (OSError, URLError, TimeoutError):
            self.count("storage_failures")
            return 503, {"error": "storage unavailable", "retryable": True}
        self.count("accepted", len(events))
        return 200, {"accepted": len(events), "unique": len(unique), "retryable": False}


def make_handler(ingestor):
    class Handler(BaseHTTPRequestHandler):
        def setup(self):
            super().setup()
            self.connection.settimeout(10)

        def respond(self, code, payload):
            body = json.dumps(payload).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Connection", "close")
            if code in (429, 503):
                self.send_header("Retry-After", "10")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            # Expose only on the internal network; the reverse proxy publishes /v1/events.
            if self.path == "/health":
                self.respond(200, {"status": "alive", "storage_checked": False})
            elif self.path == "/metrics":
                with ingestor.lock:
                    self.respond(200, dict(ingestor.metrics))
            else:
                self.respond(404, {"error": "not found"})

        def do_POST(self):
            if self.path != "/v1/events":
                self.respond(404, {"error": "not found"})
                return
            if self.headers.get("Content-Type", "").split(";")[0] != "application/json" or self.headers.get("Transfer-Encoding"):
                self.respond(415, {"error": "JSON with Content-Length required"})
                return
            try:
                length = int(self.headers.get("Content-Length", "-1"))
            except ValueError:
                length = -1
            if not 0 < length <= MAX_BODY:
                self.respond(413, {"error": "invalid content length"})
                return
            try:
                body = self.rfile.read(length)
                if len(body) != length:
                    raise ValueError("incomplete body")
                code, payload = ingestor.handle(body, self.client_address[0])
                self.respond(code, payload)
            except (OSError, ValueError):
                self.respond(400, {"error": "incomplete request"})

        def log_message(self, *_args):
            pass # Do not persist player IP addresses in application logs.
    return Handler


def main():
    schema_path = Path(os.environ.get("SCHEMA_PATH", "/app/schemas/events.json"))
    schemas = json.loads(schema_path.read_text())["events"]
    ingestor = Ingestor(schemas, ClickHouse(), os.environ.get("ALLOWED_GAMES", "echoes_of_the_rift").split(","))
    def report_health():
        while True:
            time.sleep(60)
            with ingestor.lock:
                counters = dict(ingestor.metrics)
            try:
                ingestor.store.insert_health(counters)
            except OSError:
                pass
    threading.Thread(target=report_health, daemon=True).start()
    server = ThreadingHTTPServer(("0.0.0.0", 8080), make_handler(ingestor))
    server.serve_forever()


if __name__ == "__main__":
    main()
