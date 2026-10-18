"""Validate final art references, alpha, resolution, hex bounds and unused outputs."""
from pathlib import Path
import json
import re
import sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'assets/rift'


def validate():
    issues=[];refs=set();cards=0
    for folder in ['scenes','resources','scripts','ui','addons']:
        for p in (ROOT/folder).rglob('*'):
            if p.suffix not in ['.gd','.tscn','.tres','.gdshader']:continue
            s=p.read_text(errors='replace')
            for ref in re.findall(r'res://[^"\n]+\.(?:svg|png|webp|jpg)',s):
                if '%' in ref or p.parent.name=='tests':continue
                refs.add(ref)
                if not (ROOT/ref.removeprefix('res://')).exists():issues.append(f'Missing art: {p.relative_to(ROOT)} -> {ref}')
    for p in (ROOT/'resources/data/cards').rglob('*.tres'):
        s=p.read_text();expected=f'res://assets/rift/cards/{p.stem}.webp'
        if expected not in s or 'card_art = ExtResource("rift_art")' not in s:issues.append(f'Card has no canonical illustration: {p}')
        if s.find('card_art =') < s.find('script =',s.find('[resource]')):issues.append(f'Art property precedes script: {p}')
        if (ART/'cards'/(p.stem+'.webp')).exists():
            image=Image.open(ART/'cards'/(p.stem+'.webp'))
            if image.size!=(592,396):issues.append(f'Wrong card dimensions: {p.stem}: {image.size}')
        cards+=1
    entities=0
    for p in (ART/'entities').glob('*.webp'):
        image=Image.open(p).convert('RGBA');alpha=image.getchannel('A')
        if image.size!=(512,512):issues.append(f'Wrong unit canvas: {p.name}: {image.size}')
        if alpha.getextrema()[0]!=0:issues.append(f'Opaque entity background: {p.name}')
        if any(alpha.getpixel(pt)>0 for pt in [(0,0),(511,0),(0,511),(511,511)]):issues.append(f'Opaque entity corners: {p.name}')
        if p.stem=='shadow':continue
        bounds=alpha.point(lambda a:255 if a>16 else 0).getbbox()
        if not bounds or max(bounds[2]-bounds[0],bounds[3]-bounds[1])<280:issues.append(f'Excess padding/small unit art: {p.name}')
        for y in range(512):
            row=alpha.crop((0,y,512,y+1)).point(lambda a:255 if a>32 else 0).getbbox()
            if not row:continue
            x=max(abs(row[0]-256),abs(row[2]-256))*.0625*1.04*1.02
            yy=abs(y-256)*.0625*1.04*1.02+1
            if x>16 or yy+x/2>16:
                issues.append(f'Unit exceeds hex during movement/fly presentation: {p.name}')
                break
        entities+=1
    # Five retained masters are inputs to the deterministic card/menu compositor.
    source_allow={'arena.webp','menu.webp','riftwalker.webp','synthforged.webp','voidbinder.webp'}
    unused=[]
    for p in ART.rglob('*'):
        if p.suffix not in ['.webp','.png','.svg']:continue
        if p.parent.name=='source' and p.name in source_allow:continue
        ref='res://'+p.relative_to(ROOT).as_posix()
        if ref not in refs:unused.append(p.relative_to(ROOT).as_posix())
    if unused:issues.append('Unused final assets: '+', '.join(unused))
    manifest=json.loads((ROOT/'ai/docs/rift-asset-inventory.json').read_text())
    remaining=[x['old'] for x in manifest['assets'] if (ROOT/x['old'].removeprefix('res://')).exists()]
    if remaining:issues.append('Superseded sources remain: '+', '.join(remaining))
    return issues,dict(cards=cards,entities=entities,art_files=sum(1 for p in ART.rglob('*') if p.suffix in ['.webp','.png','.svg']),bytes=sum(p.stat().st_size for p in ART.rglob('*') if p.is_file()))


if __name__=='__main__':
    issues,counts=validate()
    print(json.dumps(counts,indent=2))
    print('\n'.join(issues) if issues else 'Art validation passed')
    sys.exit(bool(issues))
