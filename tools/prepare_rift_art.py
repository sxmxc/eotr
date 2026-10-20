"""Validate alpha and package selected original art into bounded game textures.

Only final bounded WebP/PNG assets live in the project. The image generator's source files
stay in its own output location. This tool refuses opaque unit backgrounds.
"""
from pathlib import Path
import argparse
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def prepare(source, key, category, frame_inset=0):
    image = Image.open(source).convert('RGBA')
    if category == 'entities':
        alpha = image.getchannel('A')
        if alpha.getextrema()[0] != 0:
            raise ValueError('Unit artwork has no genuine transparent background')
        if any(alpha.getpixel(point) > 0 for point in [(0,0),(image.width-1,0),(0,image.height-1),(image.width-1,image.height-1)]):
            raise ValueError('Unit artwork has opaque corners/background')
        image = image.crop(alpha.getbbox())
        if key in ['riftwalker','synthforged','voidbinder']:
            # Class screens use the same master at portrait resolution.
            portrait=image.copy()
            portrait.thumbnail((1024,1280),Image.Resampling.LANCZOS)
            portrait_path=ROOT/'assets/rift/source'/(key+'.webp')
            portrait_path.parent.mkdir(parents=True,exist_ok=True)
            portrait.save(str(portrait_path)+'.pending','WEBP',quality=94,method=6)
            Path(str(portrait_path)+'.pending').replace(portrait_path)
        # Full body fills a logical 512px canvas. All rendering uses this contract.
        target_h = 440 if key not in ['bat','wasp'] else 330
        factor = min(448/image.width, target_h/image.height)
        # Pointy hex: |x| <= 16 and |y| + |x|/2 <= 16. Reserve movement
        # punch/fly-idle space while filling the usable footprint with real art.
        opaque = image.getchannel('A').point(lambda a: 255 if a > 16 else 0)
        extent = 1.0
        for y in range(image.height):
            bounds = opaque.crop((0,y,image.width,y+1)).getbbox()
            if bounds:
                half_x = max(abs(bounds[0]-image.width/2),abs(bounds[2]-image.width/2))
                extent = max(extent,abs(y-image.height/2)+half_x/2)
        factor = min(factor,220/extent)
        image = image.resize((round(image.width*factor),round(image.height*factor)),Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA',(512,512))
        canvas.alpha_composite(image,((512-image.width)//2,(512-image.height)//2))
        image = canvas
    elif category == 'cards':
        # Packaging only: preserve the entire generated composition, without crops.
        if abs(image.width / image.height - 592 / 396) > 0.06:
            raise ValueError('Card source must be composed for the 3:2 art viewport')
        image = image.convert('RGB').resize((592,396),Image.Resampling.LANCZOS)
    elif category == 'fx' and key == 'target_ring':
        if image.width != image.height:
            raise ValueError('Target marker must use a square canvas')
        if image.getchannel('A').getextrema()[0] != 0:
            raise ValueError('Target marker needs real transparent alpha')
        image = image.resize((512,512),Image.Resampling.LANCZOS)
    elif category == 'fx':
        if abs(image.width / image.height - 2) > 0.01:
            raise ValueError('FX sheets require four by two equal square cells')
        if image.getchannel('A').getextrema()[0] != 0:
            raise ValueError('FX sheet needs real transparent alpha')
        image = image.resize((1024,512),Image.Resampling.LANCZOS)
        if frame_inset:
            # Packaging only: reserve a consistent transparent gutter per frame
            # so filtering cannot sample the adjacent authored animation cell.
            if not 0 < frame_inset < 64:
                raise ValueError('Frame inset must be between 1 and 63 pixels')
            sheet = Image.new('RGBA', image.size)
            for y in range(2):
                for x in range(4):
                    cell = image.crop((x*256,y*256,(x+1)*256,(y+1)*256))
                    cell = cell.resize((256-frame_inset*2,256-frame_inset*2),Image.Resampling.LANCZOS)
                    sheet.alpha_composite(cell,(x*256+frame_inset,y*256+frame_inset))
            image = sheet
        # GPUParticles2D samples a full texture RID; ship explicit single-cell
        # textures instead of relying on AtlasTexture region support there.
        particle_frames = {'arcane_projectile': ('arcane_spark',5), 'energy_wisp': ('energy_mote',3), 'ember_flame': ('ember_mote',3), 'void_projectile': ('void_mote',7)}
        if key in particle_frames:
            name, frame = particle_frames[key]
            x, y = frame % 4 * 256, frame // 4 * 256
            particle_path = ROOT/'assets/rift/fx'/(name+'.webp')
            particle_path.parent.mkdir(parents=True,exist_ok=True)
            image.crop((x,y,x+256,y+256)).save(particle_path,'WEBP',quality=92,method=6)
    elif category == 'terrain':
        if abs(image.width / image.height - 2) > 0.015:
            raise ValueError('Terrain sheet must preserve the four by two square-cell layout')
        # Retain the current logical hex silhouette and atlas addressing contract.
        mask = Image.open(ROOT/'assets/rift/terrain/hex_atlas.png').getchannel('A')
        canvas = Image.new('RGBA', mask.size)
        cell_size = mask.height // 2
        for y in range(2):
            for x in range(4):
                cell = image.crop((x*image.width//4, y*image.height//2, (x+1)*image.width//4, (y+1)*image.height//2))
                bounds = cell.getchannel('A').point(lambda a: 255 if a > 32 else 0).getbbox()
                if not bounds:
                    raise ValueError(f'Empty terrain cell: {x},{y}')
                cell = cell.crop(bounds).resize((cell_size,cell_size),Image.Resampling.LANCZOS)
                cell.putalpha(mask.crop((x*cell_size,y*cell_size,(x+1)*cell_size,(y+1)*cell_size)))
                canvas.paste(cell,(x*cell_size,y*cell_size))
        image = canvas
    elif category == 'environment':
        image.thumbnail((2048,1152),Image.Resampling.LANCZOS)
    else:
        image.thumbnail((1920,1080) if key=='menu' else (768,512),Image.Resampling.LANCZOS)
    output = ROOT/'assets/rift'/category/(key+('.png' if category == 'terrain' else '.webp'))
    output.parent.mkdir(parents=True,exist_ok=True)
    image.save(str(output)+'.pending','PNG' if category == 'terrain' else 'WEBP',quality=92,method=6)
    Path(str(output)+'.pending').replace(output)
    return output


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source');parser.add_argument('key');parser.add_argument('category',choices=['entities','source','cards','terrain','fx','environment'])
    parser.add_argument('--frame-inset',type=int,default=0,help='Transparent per-frame packaging gutter for FX sheets')
    args=parser.parse_args()
    print(prepare(args.source,args.key,args.category,args.frame_inset))
