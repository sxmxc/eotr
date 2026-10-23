"""Bounded campaign lifecycle/mechanics checks in the real project, isolated saves."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--capture', action='store_true')
    parser.add_argument('--bosses-only', action='store_true')
    parser.add_argument('--save-quit-only', action='store_true')
    parser.add_argument('--save-validation-only', action='store_true')
    parser.add_argument('--obelisk-encounters-only', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    output = root / '.qa-tmp/bkl-031/campaign'
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='rift-campaign-') as temporary:
        env = os.environ.copy()
        for name in ('APPDATA', 'LOCALAPPDATA', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME'):
            env[name] = temporary
        display = ['--windowed', '--position', '-32000,-32000', '--resolution', '1920x1080'] if args.capture else ['--headless']
        command = [args.godot, '--path', str(root), *display, '--log-file', str(output / 'godot.log'),
                   'res://scripts/tests/campaign_test.tscn', '--', '--validation-local']
        if args.capture:
            command.append('--captures=' + output.as_posix())
        if args.bosses_only:
            command.append('--bosses-only')
        if args.save_quit_only:
            command.append('--save-quit-only')
        if args.obelisk_encounters_only:
            command.append('--obelisk-encounters-only')
        if args.save_validation_only:
            command.append('--save-validation-only')
        result = subprocess.run(command, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
        text = result.stdout + result.stderr
        (output / 'console.log').write_text(text, encoding='utf-8')
        errors = [line for line in text.splitlines() if ('SCRIPT ERROR:' in line or 'FAIL:' in line)]
        for line in errors[:25]:
            print(line)
        print('Campaign validation:', result.returncode, 'errors:', len(errors))
        return int(result.returncode != 0 or bool(errors) or 'Campaign tests: 0 failures' not in text)


if __name__ == '__main__':
    raise SystemExit(main())
