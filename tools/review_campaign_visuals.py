"""Bounded native still sequences through the existing visual production recorder."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent / 'visual_pipeline'))
from capture import ROOT, capture


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--bosses-only', action='store_true')
    args = parser.parse_args()
    scenarios = [
        ('fracture-normal', 'crossed_watch'), ('fracture-elite', 'fractured_convoy'),
        ('fracture-boss', 'tier_2_bulwark_channelers'),
        ('corruption-normal', 'root_lesson'), ('corruption-elite', 'rootbound_coven'),
        ('corruption-boss', 'tier_2_void_spectre'),
        ('unmaking-normal', 'last_coin'), ('unmaking-elite', 'the_collectors'),
        ('unmaking-boss', 'prismatic_siege'),
    ]
    for label, encounter in scenarios:
        if args.bosses_only and not label.endswith('-boss'):
            continue
        if args.bosses_only:
            label = 'final-' + label
        output = ROOT / '.qa-tmp/bkl-031/visual' / label
        output.mkdir(parents=True, exist_ok=True)
        scenario = {'event': label, 'seed': 7, 'policy': 'greedy', 'duration': 10,
                    'fps': 30, 'stills_only': True,
                    'encounter': f'res://resources/data/battles/{encounter}.tres'}
        (output / 'scenario.json').write_text(json.dumps(scenario, indent=2), encoding='utf-8')
        data = capture(scenario, output, args.godot)
        frames = [event for event in data['events'] if event['kind'] == 'rendered_frame']
        if len(frames) != 3:
            raise RuntimeError(f'{label}: expected three native frames, got {len(frames)}')
        print(label, '3 native frames; actions', len(data['trace']), flush=True)
    print('Background SHA256:', hashlib.sha256((ROOT / 'assets/rift/menus/act_environments.png').read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
