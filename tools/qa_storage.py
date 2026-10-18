"""Bound generated QA artifacts without following junctions or touching game saves."""
import os
from pathlib import Path
import re
import stat
import time

MAX_BYTES = 256 * 1024 * 1024
MAX_AGE_DAYS = 14
MAX_REPORTS = 32
MAX_LOG_BYTES = 8 * 1024 * 1024
ARTIFACT = re.compile(r'^(simulation-.*\.json|summary\.json|events\.jsonl|launcher-failure\.json|.*\.log(?:\.\d+)?|watch\.png|overhaul-.*\.png|.*comparison.*\.json)$')


def artifact_files(root):
    root = Path(root).absolute()
    if not root.exists():
        return []
    if root.resolve() != root or root.is_symlink():
        raise ValueError('QA root must be a real directory, not a link or junction')
    found = []
    pending = [root]
    while pending:
        directory = pending.pop()
        for entry in os.scandir(directory):
            info = entry.stat(follow_symlinks=False)
            if entry.is_symlink() or getattr(info, 'st_file_attributes', 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT:
                continue
            path = Path(entry.path)
            if entry.is_dir(follow_symlinks=False):
                if entry.name not in ('.godot', 'autowalker-userdata', 'compatibility-userdata'):
                    pending.append(path)
            elif entry.is_file(follow_symlinks=False) and ARTIFACT.fullmatch(entry.name):
                found.append((path, info))
    return found


def prune_qa(root, protected=(), max_bytes=MAX_BYTES, max_age_days=MAX_AGE_DAYS, max_reports=MAX_REPORTS):
    root = Path(root).absolute()
    protected = {Path(path).resolve() for path in protected}
    files = sorted(artifact_files(root), key=lambda item: item[1].st_mtime, reverse=True)
    total = sum(info.st_size for _, info in files)
    cutoff = time.time() - max_age_days * 86400
    reports = {}
    victims = set()
    for path, info in files:
        if path.name.startswith('simulation-'):
            reports[path.parent] = reports.get(path.parent, 0) + 1
        if info.st_mtime < cutoff or (path.name.startswith('simulation-') and reports[path.parent] > max_reports):
            victims.add(path)
    removed = 0
    for path, info in reversed(files):
        if path.resolve() in protected:
            continue
        if path in victims or total > max_bytes:
            # Recheck confinement immediately before unlinking; never recurse through links.
            resolved = path.resolve()
            if root not in resolved.parents or path.is_symlink():
                raise ValueError('QA artifact escaped retention root')
            try:
                path.unlink()
            except FileNotFoundError:
                continue
            total -= info.st_size
            removed += 1
    if removed:
        print(f'QA retention: removed {removed} old artifacts; {total / 1048576:.1f} MiB retained')
    return removed


def cap_log(path):
    path = Path(path)
    if path.exists() and path.stat().st_size > MAX_LOG_BYTES:
        with path.open('r+b') as log:
            script_error = False
            overlap = b''
            while chunk := log.read(65536):
                script_error = script_error or b'SCRIPT ERROR:' in overlap + chunk
                overlap = chunk[-16:]
            log.seek(-MAX_LOG_BYTES // 2, os.SEEK_END)
            tail = log.read().split(b'\n', 1)[-1]
            log.seek(0)
            prefix = b'[QA retention: earlier log output trimmed]\n'
            if script_error:
                prefix += b'SCRIPT ERROR: present in earlier trimmed log output\n'
            log.write(prefix + tail)
            log.truncate()


def maintain_qa(root, output=None, replay=None, trim_log=True):
    protected = [Path(replay)] if replay else []
    if output:
        output = Path(output)
        if trim_log:
            cap_log(output / 'godot.log')
        reports = list(output.glob('simulation-*.json'))
        if reports:
            protected.append(max(reports, key=lambda path: path.stat().st_mtime))
        protected.extend(output / name for name in ('godot.log', 'events.jsonl', 'summary.json'))
    return prune_qa(root, protected)
