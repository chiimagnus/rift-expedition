#!/usr/bin/env python3
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]

def gen(area:str):
    root=ET.parse(ROOT/f'RiftExpedition/Resources/Maps/chapter1/{area}.tmx').getroot()
    w=int(root.get('width'))*int(root.get('tilewidth')); h=int(root.get('height'))*int(root.get('tileheight'))
    im=Image.new('RGBA',(w,h),(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA')
    group=next(g for g in root.findall('objectgroup') if g.get('name')=='navObstacle')
    for o in group.findall('object'):
        name=o.get('name',''); x=float(o.get('x','0')); y=float(o.get('y','0')); ow=float(o.get('width','0')); oh=float(o.get('height','0'))
        if area=='village_square' and any(k in name for k in ('民居','议事屋','商铺','公告亭')):
            d.polygon([(x,y+oh*.42),(x+ow*.5,y),(x+ow,y+oh*.42),(x+ow,y+oh*.78),(x,y+oh*.78)], fill=(104,57,35,235), outline=(50,30,24,255))
            for px in range(int(x+18),int(x+ow),28): d.line((px,y+oh*.18,px-12,y+oh*.6),fill=(151,87,50,210),width=3)
        if area=='cave_depths' and ('边界' in name or '塌陷石带' in name):
            step=36
            for px in range(int(x),int(x+ow)+1,step):
                for py in range(int(y),int(y+oh)+1,step):
                    d.ellipse((px-24,py-18,px+24,py+18),fill=(57,56,64,245),outline=(28,28,34,255),width=3)
    out=ROOT/f'Tools/MapArtPipeline/Sources/{area}_foreground_source.png'; out.parent.mkdir(parents=True,exist_ok=True); im.save(out,optimize=True)
    print(out)
for a in ('village_square','cave_depths'): gen(a)
