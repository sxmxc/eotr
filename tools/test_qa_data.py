"""QA retention and report attribution regressions; no backend required."""
import json
import os
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch

from compare_autowalker import compare, read
from qa_storage import artifact_files, cap_log, prune_qa
from validate_project import link_directory


class QADataTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name).resolve()
        self.addCleanup(self.directory.cleanup)

    def artifact(self, name, age=0, size=10):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'x' * size)
        stamp = time.time() - age * 86400
        os.utime(path, (stamp, stamp))
        return path

    def test_age_size_and_report_count_limits_preserve_other_files(self):
        old = self.artifact('old/events.jsonl', age=20)
        save = self.artifact('save.json', age=20)
        first = self.artifact('batch/simulation-1.json', age=3)
        second = self.artifact('batch/simulation-2.json', age=2)
        latest = self.artifact('batch/simulation-3.json')
        prune_qa(self.root, max_reports=2)
        self.assertFalse(old.exists())
        self.assertFalse(first.exists())
        self.assertTrue(save.exists())
        prune_qa(self.root, protected=[latest], max_bytes=10)
        self.assertFalse(second.exists())
        self.assertTrue(latest.exists())

    def test_junction_or_symlink_and_save_directory_are_not_traversed(self):
        source = self.root / 'source'
        source.mkdir()
        (source / 'events.jsonl').write_text('outside QA')
        qa = self.root / 'qa'
        qa.mkdir()
        link_directory(source, qa / 'linked-assets')
        saves = qa / 'autowalker-userdata'
        saves.mkdir()
        (saves / 'events.jsonl').write_text('save data')
        self.assertEqual(artifact_files(qa), [])
        prune_qa(qa, max_bytes=0)
        self.assertEqual((source / 'events.jsonl').read_text(), 'outside QA')
        self.assertTrue((saves / 'events.jsonl').exists())

    def test_log_trimming_keeps_script_error_status_and_recent_output(self):
        log = self.root / 'godot.log'
        log.write_bytes(b'SCRIPT ERROR: early failure\n' + b'repeated line\n' * 100 + b'last line\n')
        with patch('qa_storage.MAX_LOG_BYTES', 512):
            cap_log(log)
        self.assertLess(log.stat().st_size, 512)
        self.assertIn(b'SCRIPT ERROR:', log.read_bytes())
        self.assertTrue(log.read_bytes().endswith(b'last line\n'))

    def test_comparison_uses_only_current_session_and_matching_metric_versions(self):
        (self.root / 'summary.json').write_text(json.dumps({'session_id': 'current'}))
        def report(seed, session, version):
            value = dict(seed=seed, encounter='blobs', policy='greedy', policy_version='1',
                         mode='encounter', session_id=session, metrics_version=version, outcome='win')
            (self.root / f'simulation-{seed}.json').write_text(json.dumps(value))
        report(1, 'current', 2)
        report(2, 'old', 2)
        current = read(self.root)
        self.assertEqual(len(current), 1)
        report(1, 'current', 1)
        self.assertEqual(compare(current, read(self.root))['matched_simulations'], 0)


if __name__ == '__main__':
    unittest.main()
