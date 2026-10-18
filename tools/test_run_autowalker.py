"""Launcher lifecycle regressions; no engine or backend required."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

import run_autowalker as launcher


class LauncherLifecycleTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.stop_file = Path(self.directory.name) / '.stop-test'
        self.process = Mock(args=['godot'])
        self.process.poll.return_value = 0
        self.spawn = patch.object(launcher.subprocess, 'Popen', return_value=self.process)
        self.popen = self.spawn.start()
        self.addCleanup(self.spawn.stop)

    def test_normal_exit_preserves_engine_exit_code_and_isolates_interrupts(self):
        self.process.poll.return_value = 7
        self.assertEqual(launcher.run_godot(['godot'], {}, 5, self.stop_file), 7)
        options = self.popen.call_args.kwargs
        if os.name == 'nt':
            self.assertEqual(options['creationflags'], subprocess.CREATE_NEW_PROCESS_GROUP)
        else:
            self.assertTrue(options['start_new_session'])
        self.process.kill.assert_not_called()

    def test_poll_wait_stays_interruptible_without_windows_wait_retry(self):
        self.process.poll.side_effect = [None, 0, 0]
        with patch.object(launcher.time, 'sleep', side_effect=KeyboardInterrupt):
            self.assertEqual(launcher.run_godot(['godot'], {}, None, self.stop_file), 130)
        self.process.wait.assert_not_called()
        self.process.kill.assert_not_called()

    def test_interrupt_requests_graceful_stop_and_preserves_completed_report(self):
        report = self.stop_file.parent / 'simulation-1.json'
        report.write_text('{"outcome":"win"}', encoding='utf-8')

        def wait(process, timeout, maintenance=None):
            if not self.stop_file.exists():
                raise KeyboardInterrupt
            self.assertEqual(timeout, 20)
            return 0

        with patch.object(launcher, 'wait_for_exit', side_effect=wait):
            self.assertEqual(launcher.run_godot(['godot'], {}, None, self.stop_file), 130)
        self.assertFalse(self.stop_file.exists())
        self.assertEqual(report.read_text(encoding='utf-8'), '{"outcome":"win"}')
        self.process.kill.assert_not_called()

    def test_unresponsive_interrupted_child_is_killed_and_reaped(self):
        with patch.object(launcher, 'wait_for_exit', side_effect=[KeyboardInterrupt, subprocess.TimeoutExpired('godot', 20)]):
            self.assertEqual(launcher.run_godot(['godot'], {}, None, self.stop_file), 130)
        self.process.kill.assert_called_once()
        self.process.wait.assert_called_once_with()
        self.assertFalse(self.stop_file.exists())

    def test_deadline_kills_and_reaps_child_before_reporting_timeout(self):
        with patch.object(launcher, 'wait_for_exit', side_effect=subprocess.TimeoutExpired('godot', 5)):
            with self.assertRaises(subprocess.TimeoutExpired):
                launcher.run_godot(['godot'], {}, 5, self.stop_file)
        self.process.kill.assert_called_once()
        self.process.wait.assert_called_once_with()


if __name__ == '__main__':
    unittest.main()
