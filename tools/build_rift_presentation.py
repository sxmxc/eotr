"""Rebuild existing enemy variants and class/menu presentation from retained masters.

Card illustrations are independent generated scenes; this tool never writes cards.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/"assets/rift"
CYAN="#89d8d2"; GOLD="#d9bb85"; INK="#142030"


def save(image, path):
    image.save(str(path)+".pending", "WEBP", quality=94, method=6)
    Path(str(path)+".pending").replace(path)


def build_variants():
    content=json.loads((ROOT/'ai/visual/reference/rift-content.json').read_text())
    for index,(key,data) in enumerate(content['enemies'].items()):
        if 'base' not in data:continue
        image=Image.open(ART/'entities'/(data['base']+'.webp')).convert('RGBA')
        bounds=image.getchannel('A').getbbox()
        cx=(bounds[0]+bounds[2])//2
        top=bounds[1]
        ornament=Image.new('RGBA',image.size)
        d=ImageDraw.Draw(ornament)
        style=index%3
        if style==0:
            # Raised, curved ivory/ochre crest anchored to the base's head.
            d.arc((cx-48,top+13,cx+44,top+91),183,352,fill=INK,width=17)
            d.arc((cx-48,top+13,cx+44,top+91),183,352,fill=GOLD,width=10)
            d.line((cx-27,top+29,cx-34,top+5),fill=GOLD,width=10)
            d.line((cx+22,top+24,cx+30,top+3),fill=GOLD,width=10)
        elif style==1:
            # Asymmetric shoulder guard; preserves silhouette and base identity.
            x=bounds[0]+int((bounds[2]-bounds[0])*.20);y=top+int((bounds[3]-top)*.43)
            d.rounded_rectangle((x-21,y-9,x+26,y+46),radius=16,fill='#3b4e5b',outline=GOLD,width=6)
            d.arc((x-11,y,x+17,y+34),70,270,fill='#e4cf9f',width=4)
        else:
            # Segmented cyan ward wrap across the lower torso.
            y=top+int((bounds[3]-top)*.66)
            for x in [cx-40,cx-10,cx+20]:
                d.rounded_rectangle((x,y,x+22,y+22),radius=7,fill='#365966',outline=CYAN,width=3)
        # Decorations must satisfy the same footprint as the underlying body.
        alpha=ornament.getchannel('A')
        for y in range(512):
            for x in range(512):
                xx=abs(x-256);yy=abs(y-256)
                if xx>216 or yy+xx/2>216:
                    alpha.putpixel((x,y),0)
        ornament.putalpha(alpha)
        image.alpha_composite(ornament)
        save(image,ART/'entities'/(key+'.webp'))
    # The pre-existing elite Horror also has readable armor differentiation.
    elite=Image.open(ART/'entities/horror.webp').convert('RGBA')
    armor=Image.new('RGBA',elite.size);ed=ImageDraw.Draw(armor)
    for offset in [-24,0,24]:
        ed.arc((177+offset,118,306+offset,278),185,334,fill='#dcc18b',width=8)
    armor.putalpha(Image.composite(armor.getchannel('A'),Image.new('L',elite.size),elite.getchannel('A')))
    elite.alpha_composite(armor)
    save(elite,ART/'entities/elite_horror.webp')


def build_menus():
    folder=ART/'menus';folder.mkdir(exist_ok=True)
    background=Image.open(ART/'source/menu.webp').convert('RGBA').resize((1920,1080),Image.Resampling.LANCZOS)
    save(background.convert('RGB'),folder/'main_menu.webp')
    for key in ['riftwalker','synthforged','voidbinder']:
        image=background.copy()
        character=Image.open(ART/'source'/(key+'.webp')).convert('RGBA')
        character=character.crop(character.getchannel('A').getbbox())
        character=character.resize((round(character.width*980/character.height),980),Image.Resampling.LANCZOS)
        image.alpha_composite(character,(int(1450-character.width/2),80))
        save(image.convert('RGB'),folder/(key+'.webp'))



if __name__ == "__main__":
    build_variants()
    build_menus()
