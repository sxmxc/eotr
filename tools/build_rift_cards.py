"""Compose high-resolution card artwork from fixed, shared illustrated masters.

The Riftwalker is never redrawn: sleeves, mask, cloak, hands and boots are copied
from exactly the same asset on every card. Build outputs overwrite their one
canonical destination. Requires Pillow; no network or image-model calls.
"""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'assets/rift'
SIZE=(592,396)
CYAN='#89d8d2'; GOLD='#d9bb85'; PLUM='#a96d91'; INK='#142030'


def save(image,path):
    image.save(str(path)+'.pending','WEBP',quality=94,method=6)
    Path(str(path)+'.pending').replace(path)


def compose(key):
    image=Image.open(ART/'source/arena.webp').convert('RGBA').resize(SIZE,Image.Resampling.LANCZOS)
    overlay=Image.new('RGBA',SIZE)
    d=ImageDraw.Draw(overlay)
    def actor(name,x,y,height,alpha=255,flip=False):
        source=Image.open(ART/'entities'/(name+'.webp')).convert('RGBA')
        source=source.crop(source.getchannel('A').getbbox())
        source=source.resize((round(source.width*height/source.height),height),Image.Resampling.LANCZOS)
        if flip:source=source.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        if alpha<255:source.putalpha(source.getchannel('A').point(lambda a:a*alpha//255))
        image.alpha_composite(source,(x,y))
    def curve(points,color,width=5):
        d.line(points,fill=color,width=width,joint='curve')
        # Soft restrained aura under the crisp energy core, never on entity sprites.
    def arc(box,start,end,color=CYAN,width=6):d.arc(box,start,end,fill=color,width=width)
    def sparks(x,y,color=GOLD):
        for dx,dy in [(-24,-17),(-15,29),(20,-24),(33,8),(-34,6)]:
            d.line((x+dx,y+dy,x+dx*1.3,y+dy*1.3),fill=color,width=3)
    def shard(x,y,size=30):
        d.polygon([(x-8,y+size),(x-16,y),(x+8,y-size),(x+15,y-5),(x+2,y+size-7)],fill='#684f70',outline='#d39cb4',width=3)
        d.line((x-7,y+size-7,x+8,y-size+5),fill='#e8c3d0',width=3)
    attacks={'arcane_bolt','arcane_blast','arcane_flame','corroding_shot','chrono_jab','jab','phase_slash','overload_shot','void_shard','void_surge','deminishing_returns'}
    if key in attacks:
        actor('riftwalker',5,35,330)
        actor('horror' if key in ['jab','chrono_jab','deminishing_returns'] else 'spectre',355,85,260,flip=True)
        if key in ['jab','chrono_jab']:
            # Two impact streaks; the underlying glove/sleeve stays identical.
            for y in [196,234]:curve([(240,y),(280,y-8),(365,y-5)],GOLD,10)
            if key=='chrono_jab':arc((227,126,413,295),20,325,GOLD,4)
        elif key=='phase_slash':
            actor('riftwalker',100,20,330,90)
            for i in range(6):arc((175+i*3,25+i*4,530-i*3,320-i*3),207,307,CYAN,3)
        elif key=='arcane_blast':
            curve([(221,208),(297,191),(389,203)],'#396e7e',32)
            curve([(221,208),(297,201),(389,203)],CYAN,12)
            arc((355,173,417,235),0,360,CYAN,5)
        elif key=='arcane_flame':
            for x,y in [(303,207),(344,178),(379,210),(405,167)]:
                d.polygon([(x-19,y+43),(x-25,y+5),(x-8,y-33),(x+3,y-48),(x+7,y-8),(x+21,y-19),(x+30,y+26),(x+8,y+47)],fill='#b27b57')
                d.polygon([(x-6,y+31),(x-10,y+2),(x+3,y-20),(x+8,y+10),(x+16,y+26)],fill='#eed4a0')
        elif key=='corroding_shot':
            curve([(225,205),(280,224),(329,191),(389,212)],PLUM,8)
            for x,y in [(375,197),(406,214),(391,243)]:
                d.ellipse((x-3,y,x+4,y+8),fill='#d39cb4');curve([(x,y),(x,y+23)],PLUM,3)
        elif key=='overload_shot':
            curve([(225,205),(300,190),(390,210)],'#b48a5c',43)
            curve([(225,205),(300,200),(390,210)],'#f4dfb3',15)
            arc((196,170,254,242),0,360,CYAN,4);sparks(237,203)
        elif key=='void_shard':
            shard(316,195,65);curve([(227,224),(272,205)],PLUM,3)
        elif key=='void_surge':
            curve([(224,212),(279,173),(321,218),(390,200)],'#735574',28)
            curve([(224,212),(279,173),(321,218),(390,200)],PLUM,7)
        elif key=='deminishing_returns':
            actor('bat',280,10,106)
            for y in [193,206,220]:curve([(229,y),(292,y-12),(376,y+3)],GOLD,4)
        else:
            curve([(225,209),(270,193),(293,211),(334,193),(390,209)],CYAN,6)
        sparks(391,208,PLUM)
    elif key in ['phase_step','quantum_rift']:
        actor('riftwalker',13,48,305,90)
        actor('riftwalker',310,32,323)
        if key=='quantum_rift':
            for box,color in [((17,30,222,365),PLUM),((301,14,520,367),CYAN)]:
                arc(box,0,360,color,7);arc((box[0]+10,box[1]+12,box[2]-10,box[3]-12),0,360,color,2)
        else:
            for y in [292,310,329]:curve([(157,y),(238,y-12),(325,y-3)],CYAN,3)
    elif key in ['eldritch_barrier','nano_shield']:
        actor('riftwalker',140,42,325)
        if key=='eldritch_barrier':
            for i in range(6):arc((102+i*5,18+i*4,466-i*2,380-i*3),240,478,CYAN,3)
            for x,y in [(444,116),(490,198),(455,283)]:curve([(x,y),(x+28,y-15)],GOLD,6)
        else:
            for x,y in [(126,116),(165,58),(297,40),(409,109),(424,227),(352,337),(188,350),(119,262)]:
                arc((x-18,y-18,x+18,y+18),20,320,CYAN,5)
            curve([(474,111),(445,177),(476,177),(444,244)],GOLD,8)
    elif key in ['arcane_explosion','fracture_pulse','corrosion_wave']:
        actor('riftwalker',226,107,236)
        actor('horror',5,139,170);actor('blob',419,215,150);actor('bat',414,44,130)
        color=PLUM if key=='corrosion_wave' else CYAN
        for r in ([74,132,191] if key=='fracture_pulse' else [126,192]):arc((293-r,246-r/2,293+r,246+r/2),0,360,color,5)
        if key=='corrosion_wave':
            for x,y in [(105,225),(475,281),(472,115)]:curve([(x,y),(x,y+24)],PLUM,5)
        if key=='fracture_pulse':curve([(285,87),(267,129),(299,129),(279,169)],GOLD,6)
    elif key=='echo_harvest':
        actor('riftwalker',277,39,323)
        for x,y in [(100,285),(162,248),(214,293)]:
            d.polygon([(x-15,y+15),(x-19,y-6),(x+2,y-38),(x+17,y-12),(x+11,y+19)],fill='#b18b61',outline=GOLD,width=3)
            arc((x,y-133,378,y+9),190,280,GOLD,3)
    elif key in ['focus','mana_surge','rift_knowledge','mana_leech']:
        actor('riftwalker',134,38,325)
        if key=='rift_knowledge':
            actor('spectre',418,135,180)
            arc((383,122,562,310),0,360,CYAN,4)
            for x,y in [(146,110),(165,93),(177,130)]:d.ellipse((x,y,x+6,y+6),fill=GOLD)
        elif key=='mana_leech':
            actor('spectre',431,101,218)
            arc((279,80,529,245),193,348,CYAN,5)
            arc((289,160,527,312),8,165,GOLD,4)
        elif key=='mana_surge':
            for x in [75,415]:curve([(x,285),(x+35,186),(x+14,186),(x+55,88)],GOLD,8)
        else:
            arc((181,25,382,223),0,360,GOLD,4)
            for x,y in [(195,65),(354,68),(272,15)]:d.ellipse((x,y,x+7,y+7),fill=CYAN)
    elif key in ['adrenaline_rush','echo']:
        actor('riftwalker',4,43,322)
        for x,y in [(317,99),(431,129)]:
            d.rounded_rectangle((x,y,x+80,y+126),radius=9,fill='#304651',outline=GOLD,width=4)
            arc((x+20,y+30,x+60,y+78),0,300,CYAN,5)
            curve([(x+20,y+100),(x+60,y+100)],CYAN,2)
        if key=='echo':arc((275,46,518,302),110,280,GOLD,4)
        else:curve([(263,287),(291,228),(277,228),(310,177)],GOLD,8)
    elif key=='sever_anchor':
        actor('riftwalker',3,39,325);actor('obelisk',360,22,342)
        curve([(179,325),(244,276),(310,304),(391,268)],PLUM,12)
        curve([(269,153),(337,274)],CYAN,10);sparks(316,274,GOLD)
    elif key=='void_fracture':
        actor('riftwalker',0,40,325)
        for x,y,size in [(307,170,52),(406,129,60),(495,233,48)]:shard(x,y,size)
        sparks(404,225,CYAN)
    elif key in ['void_residue','void_slime']:
        if key=='void_slime':actor('blob',158,80,263)
        else:
            d.ellipse((103,223,484,337),fill='#57445f',outline=PLUM,width=4)
            for x,y in [(171,245),(239,290),(350,252),(414,285)]:arc((x,y,x+28,y+10),0,180,'#be89a6',3)
        for x,y in [(181,161),(328,111),(427,173)]:d.ellipse((x,y,x+9,y+9),fill=PLUM)
    else:raise ValueError('Missing authored composition '+key)
    # The same source produces a restrained glow and a crisp illustrated effect.
    glow=overlay.filter(ImageFilter.GaussianBlur(7))
    glow.putalpha(glow.getchannel('A').point(lambda a:a//3))
    image.alpha_composite(glow);image.alpha_composite(overlay)
    return image.convert('RGB')


def main():
    build_variants()
    for p in sorted((ROOT/'resources/data/cards').rglob('*.tres')):
        save(compose(p.stem),ART/'cards'/(p.stem+'.webp'))
    build_menus()
    print('29 distinct card compositions built from one unaltered character master.')


def build_variants():
    content=json.loads((ROOT/'ai/docs/rift-content.json').read_text())
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


if __name__=='__main__':main()
