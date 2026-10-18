"""Rebuild the small custom UI family. SVG source paths are shipped directly."""
from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageEnhance

OUT=Path(__file__).resolve().parents[1]/'assets/rift/ui'
SHAPES={
 'attack':'M20 47 41 15 48 12 47 22 25 45M17 36 31 45M18 49 24 41',
 'block':'M16 17Q32 14 48 17L45 35Q42 44 32 51Q22 44 19 35ZM32 22V41',
 'health':'M32 49 16 33Q7 24 16 17Q24 12 32 23Q40 12 48 17Q57 24 48 33ZM22 32H42',
 'move':'M12 45H24V31H47M38 22 47 31 38 40',
 'energy':'M35 11 19 35H31L27 53 47 28H34Z',
 'coin':'M32 12C58 12 58 52 32 52C6 52 6 12 32 12ZM32 21 39 31 32 43 25 31Z',
 'chest':'M13 30Q16 17 21 17H43Q48 17 51 30L48 48H16ZM14 31H50M28 29H36V38H28Z',
 'fire':'M25 49Q12 42 23 28L31 13Q32 26 39 31L44 24Q56 46 38 51Q24 56 25 43L32 34',
 'eye':'M10 32Q32 9 54 32Q32 55 10 32ZM32 24C43 24 43 40 32 40C21 40 21 24 32 24Z',
 'portal':'M32 11C52 11 52 53 32 53C12 53 12 11 32 11ZM32 19 27 29 37 36 32 46',
 'crystal':'M32 11 47 25 40 48H24L17 25ZM17 25H47M32 11 26 25 32 48 38 25Z',
 'card':'M20 12H44Q48 12 48 16V48Q48 52 44 52H20Q16 52 16 48V16Q16 12 20 12ZM24 22H40M24 43H40M32 27 38 33 32 39 26 33Z',
 'draw':'M16 23H39V52H16ZM25 14H48V43M29 29V44M23 38 29 44 35 38',
 'burn':'M17 13H44V30M17 13V49H26M33 50Q25 43 34 33L38 27 42 38 47 35Q53 49 41 52Z',
 'shuffle':'M12 20H22L43 44H53M45 36 53 44 45 52M12 44H22L43 20H53M45 12 53 20 45 28',
 'next':'M23 14 42 32 23 50', 'previous':'M41 14 22 32 41 50',
 'camp':'M19 49 45 41M19 41 45 49M28 36Q19 29 29 19L33 13 38 26 43 23Q49 39 34 39Z',
 'skull':'M21 40Q8 22 20 15Q32 7 44 15Q56 22 43 40L41 50H23ZM26 42V50M37 42V50M20 27 26 29 23 33ZM44 27 38 29 41 33Z',
 'elite':'M14 20 24 29 32 13 40 29 50 20 46 46H18ZM20 39H44',
 'event':'M21 22Q22 9 36 13Q52 19 37 31L31 37V40M31 48V50',
 'mechanism':'M26 12H38L40 20 48 23 52 32 47 41 40 44 37 52H26L23 44 15 41 12 32 16 23 24 20ZM32 24C43 24 43 40 32 40C21 40 21 24 32 24Z',
 'poison':'M26 12H38M28 12V25L19 40Q15 51 26 51H39Q50 51 45 40L36 25V12M23 37H41M30 44H34',
 'search':'M28 13C47 13 47 41 28 41C9 41 9 13 28 13ZM38 38 51 51',
 'resource':'M13 25 34 16 51 25V41L30 50 13 41ZM13 25 30 34 51 25M30 34V50',
 'ruin':'M13 48H51M19 46V22L27 18V46M37 46V17L45 22V46M15 19 32 11 49 19',
 'key':'M23 13C37 13 37 33 23 33C9 33 9 13 23 13ZM30 30 49 49M40 40 45 35M45 45 50 40',
 'ring':'M32 21C55 21 55 51 32 51C9 51 9 21 32 21ZM23 19 32 10 41 19 32 27Z',
 'time':'M32 12C58 12 58 52 32 52C6 52 6 12 32 12ZM32 19V32L42 39',
 'strength':'M14 41 21 27 29 33 35 19 43 18 48 30 43 44 27 48Z',
 'focus':'M32 21C47 21 47 43 32 43C17 43 17 21 32 21ZM32 10V17M32 47V54M10 32H17M47 32H54',
 'corrosion':'M13 23H51V40H38L36 34 31 42 28 36 13 40ZM18 17 22 12M38 17 42 11',
 'bounty':'M16 12H48V52H16ZM24 20H40M24 45H40M32 26 39 32 32 38 25 32Z',
 'road':'M16 51 24 33 21 25 28 12M48 51 40 33 43 25 36 12M32 43V49M32 28V34M32 15V20',
 'marker':'M32 51 17 29Q12 12 32 11Q52 12 47 29ZM32 19C40 19 40 31 32 31C24 31 24 19 32 19Z',
 'reflect':'M14 17 29 12 44 17 42 37 29 50 17 37ZM35 30H53M46 23 53 30 46 37',
 'circuit':'M16 16H32V32H48V48M16 48V32H32V16H48M13 13H19V19H13ZM45 45H51V51H45Z',
 'upgrade':'M18 34 32 20 46 34M32 20V51M18 12H46',
}

GROUPS={
 'attack':['piercing-sword','striking-arrows'], 'block':['armor-upgrade','intent-shield','shield'],
 'health':['heart'],'move':['path-distance','wingfoot'],'energy':['electric','rolling-energy','rolling-energy-2','unstable-orb'],
 'coin':['cash','two-coins','crown-coin','pay-money','shiny-purse'], 'chest':['chest','chest (1)','open-chest','open-treasure-chest'],
 'fire':['flame','cross-flare'], 'eye':['third-eye','soul'], 'portal':['portal','bubbles'],
 'crystal':['prism','cut-diamond','rupee'], 'card':['card-joker','buy-card'], 'draw':['card-draw'],
 'burn':['card-burn'],'shuffle':['card-random','perspective-dice-six-faces-random'],'next':['next-button','next-button (1)'],
 'previous':['previous-button'],'camp':['night-sleep','meditation'],'skull':['broken-skull','raise-skeleton'],
 'elite':['overlord-helm'],'event':['uncertainty'],'mechanism':['cpu','clockwork'],'poison':['poison-bottle'],
 'search':['magnifying-glass'],'resource':['clay-brick','metal-bar'],'ruin':['crystal-shrine','mining-helmet'],
 'key':['millenium-key'],'ring':['ring'],'time':['astrolabe'],'strength':['muscle-up'],'focus':['triple-yin'],
 'corrosion':['metal-bar-fg-only'],'bounty':['wanted-reward','wanted-reward-pressed'],'road':['mountain-road'],
 'marker':['position-marker'],'reflect':['shield-reflect'],'circuit':['circuitry'],'upgrade':['upgrade'],
}


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    root=OUT.parents[2]
    used=set()
    for folder in ['scenes','resources','scripts','ui']:
        for p in (root/folder).rglob('*'):
            if p.suffix in ['.gd','.tres','.tscn']:
                used.update(re.findall(r'res://assets/rift/ui/([^"\n]+)\.svg',p.read_text()))
    for key,shape in SHAPES.items():
        if used and key not in used:continue
        # The warm neutral stroke takes the existing theme's hover/disabled tint.
        source=f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><path d="{shape}" fill="none" stroke="#e5d7b7" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>\n'
        (OUT/(key+'.svg')).write_text(source,encoding='utf-8')
    build_terrain()


def build_terrain():
    art=OUT.parent
    source=Image.open(art/'source/arena.webp').convert('RGBA')
    atlas=Image.new('RGBA',(128,64))
    for index in range(8):
        # Real illustrated slate texture, masked to the engine's pointy 32px hex.
        tile=source.crop((80+index*20,270,208+index*20,398)).resize((32,32),Image.Resampling.LANCZOS)
        tile=ImageEnhance.Color(tile).enhance(.4)
        tile=ImageEnhance.Brightness(tile).enhance(.65 if index!=7 else 1.1)
        tint=Image.new('RGBA',(32,32),('#733e6b' if index==1 else '#234756')+( '90' if index==1 else '30'))
        tile=Image.alpha_composite(tile,tint)
        mask=Image.new('L',(32,32));md=ImageDraw.Draw(mask)
        points=[(16,0),(31,8),(31,23),(16,31),(0,23),(0,8)]
        md.polygon(points,fill=255);tile.putalpha(mask)
        d=ImageDraw.Draw(tile)
        d.line(points+[points[0]],fill='#788387',width=1)
        if index==0:
            d.polygon([(12,21),(10,15),(15,9),(21,12),(23,18),(18,23)],fill='#947b5c',outline='#d9bb85')
            d.line((13,18,15,12,20,13),fill='#e5d7b7')
        elif index==1:d.line((18,4,13,12,19,19,14,28),fill='#bd8ba9',width=2)
        elif index==2:
            d.ellipse((10,6,22,26),outline='#b58aa9',width=2)
            d.arc((12,9,20,23),90,270,fill='#e2c4d6')
        elif index==3:
            d.ellipse((7,12,25,23),fill='#213847',outline='#85c5c3')
            d.arc((10,12,22,20),5,180,fill='#bce5df',width=2)
        elif index==4:
            d.rectangle((8,11,12,23),fill='#a89e89');d.line((8,11,12,11),fill='#e5d7b7')
            d.rectangle((19,8,23,23),fill='#a89e89');d.line((19,8,23,8),fill='#e5d7b7')
            d.line((7,24,25,24),fill='#6c685e',width=2)
        elif index==5:
            shade=Image.new('RGBA',(32,32),'#142030d0');shade.putalpha(mask.point(lambda a:a*210//255));tile=Image.alpha_composite(tile,shade)
        elif index==6:d.arc((10,15,22,24),0,170,fill='#4c5d65')
        elif index==7:
            d=ImageDraw.Draw(tile);d.line(points+[points[0]],fill='#9fe4d6',width=2)
        atlas.alpha_composite(tile,((index%4)*32,(index//4)*32))
    (art/'terrain').mkdir(exist_ok=True)
    atlas.save(art/'terrain/hex_atlas.png',optimize=True)


if __name__=='__main__':main()
