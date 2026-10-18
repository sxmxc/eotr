import copy
from datetime import datetime, timezone
import json
from pathlib import Path
import unittest
from unittest.mock import Mock

from service import Ingestor, MAX_BODY, RateLimiter

SCHEMAS = json.loads((Path(__file__).resolve().parents[3] / "telemetry/schemas/events.json").read_text())["events"]


def event():
    return {"event_id": "a" * 32, "event_name": "stat_changed", "schema_version": 1,
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "game_id": "echoes_of_the_rift", "environment": "qa", "build_version": "test",
            "session_id": "b" * 32, "run_id": "test-run", "source_type": "bot",
            "metadata": {}, "properties": {"stat": "damage", "change": 2.5}}


class IngestionTests(unittest.TestCase):
    def setUp(self):
        self.store = Mock()
        self.service = Ingestor(SCHEMAS, self.store)

    def send(self, events):
        return self.service.handle(json.dumps({"events": events}).encode(), "test-address")

    def test_accept_and_batch_deduplication(self):
        value = event()
        code, ack = self.send([value, copy.deepcopy(value)])
        self.assertEqual(code, 200)
        self.assertEqual(ack["accepted"], 2)
        self.assertEqual(len(self.store.insert.call_args.args[0]), 1)

    def test_rejects_entire_invalid_batch(self):
        bad = event()
        bad["schema_version"] = 99
        self.assertEqual(self.send([event(), bad])[0], 400)
        self.store.insert.assert_not_called()

    def test_types_required_and_limits(self):
        for props in ({}, {"stat": "test", "change": True}, {"stat": "x", "change": "3"}, {"stat": "x", "change": 1, "unknown": 2}):
            value = event()
            value["properties"] = props
            self.assertEqual(self.send([value])[0], 400)
        self.assertEqual(self.service.handle(b"x" * (MAX_BODY + 1), "a")[0], 413)
        self.assertEqual(self.send([])[0], 400)
        self.assertEqual(self.send([event()] * 101)[0], 400)

    def test_malformed_and_untrusted_fields(self):
        for body in (b"null", b"[]", b"{", b'{"events":[NaN]}'):
            self.assertEqual(self.service.handle(body, "a")[0], 400)
        for field, value in (("game_id", "other"), ("source_type", "admin"), ("timestamp", "2020-01-01T00:00:00Z"), ("event_id", "bad")):
            data = event()
            data[field] = value
            self.assertEqual(self.send([data])[0], 400)

    def test_storage_retry(self):
        self.store.insert.side_effect = OSError("offline")
        code, ack = self.send([event()])
        self.assertEqual(code, 503)
        self.assertTrue(ack["retryable"])

    def test_rate_limit_bounded_memory(self):
        limiter = RateLimiter(limit=1, capacity=2, clock=lambda: 0)
        self.assertTrue(limiter.allow("a"))
        self.assertFalse(limiter.allow("a"))
        limiter.allow("b")
        limiter.allow("c")
        self.assertEqual(len(limiter.windows), 2)

    def test_parallel_schema_versions(self):
        one = SCHEMAS["stat_changed"]
        two = {**one, "version": 2}
        self.service.schemas = {"stat_changed": {"versions": {"1": one, "2": two}}}
        first, second = event(), event()
        second["schema_version"] = 2
        self.assertEqual(self.send([first, second])[0], 200)


if __name__ == "__main__":
    unittest.main()
