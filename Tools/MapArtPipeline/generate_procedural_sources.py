#!/usr/bin/env python3
"""Generate deterministic top-down map art from TMX layout data.

This is the fallback production path when generative image tools cannot preserve
map geometry. It intentionally favors readability and exact alignment over
illustration-level detail.
"""
from __future__ import annotations

import argparse
import csv
import math
import random
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter

TILE = 32
PALETTES = {
    "village_riverside": {
        "ground": (91, 111, 67), "ground2": (108, 126, 77), "path": (151, 127, 86),
        "path2": (170, 145, 98), "water": (57, 111, 126), "water2": (74, 137, 148),
        "edge": (47, 65, 42), "wood": (112, 73, 42), "wood2": (151, 104, 59),
    },
    "village_outskirts": {
        "ground": (88, 111, 62), "ground2": (104, 126, 72), "path": (147, 119, 79),
        "path2": (170, 143, 95), "water": (54, 99, 112), "water2": (71, 121, 132),
        "edge": (45, 63, 38), "wood": (104, 68, 39), "wood2": (145, 96, 53),
    },
    "wilds_road": {
        "ground": (72, 96, 53), "ground2": (88, 110, 61), "path": (137, 112, 75),
        "path2": (158, 132, 87), "water": (48, 93, 108), "water2": (65, 118, 129),
        "edge": (39, 56, 35), "wood": (91, 59, 35), "wood2": (132, 88, 48),
    },
    "wilds_ruins": {
        "ground": (66, 79, 55), "ground2": (80, 91, 61), "path": (117, 105, 80),
        "path2": (136, 121, 91), "water": (48, 82, 91), "water2": (62, 102, 108),
        "edge": (36, 43, 34), "wood": (83, 55, 35), "wood2": (119, 79, 45),
    },
    "wilds_riverbank": {
        "ground": (70, 96, 55), "ground2": (86, 111, 63), "path": (136, 112, 76),
        "path2": (157, 132, 89), "water": (43, 98, 117), "water2": (58, 127, 139),
        "edge": (36, 57, 39), "wood": (91, 61, 37), "wood2": (132, 90, 51),
    },
}


def parse_csv_layer(root: ET.Element, name: str) -> list[list[int]]:
    layer = next(l for l in root.findall("layer") if l.get("name") == name)
    data = layer.findtext("data", default="")
    rows = []
    for row in csv.reader(line.strip() for line in data.strip().splitlines() if line.strip()):
        rows.append([int(v) for v in row if v.strip()])
    return rows


def objects(root: ET.Element, group_name: str) -> Iterable[ET.Element]:
    group = next((g for g in root.findall("objectgroup") if g.get("name") == group_name), None)
    return [] if group is None else group.findall("object")


def seeded(area: str) -> random.Random:
    return random.Random(sum((i + 1) * ord(c) for i, c in enumerate(area)))


def stipple(draw: ImageDraw.ImageDraw, rng: random.Random, box: tuple[int, int, int, int], count: int, colors: list[tuple[int, int, int]], radius=(1, 3)) -> None:
    x0, y0, x1, y1 = box
    for _ in range(count):
        x, y = rng.randint(x0, max(x0, x1 - 1)), rng.randint(y0, max(y0, y1 - 1))
        r = rng.randint(*radius)
        draw.ellipse((x-r, y-r, x+r, y+r), fill=rng.choice(colors))


def draw_tile_base(area: str, root: ET.Element) -> Image.Image:
    p = PALETTES[area]
    rows = parse_csv_layer(root, "terrain")
    h, w = len(rows) * TILE, len(rows[0]) * TILE
    image = Image.new("RGB", (w, h), p["ground"])
    draw = ImageDraw.Draw(image)
    rng = seeded(area)
    for ty, row in enumerate(rows):
        for tx, gid in enumerate(row):
            box = (tx*TILE, ty*TILE, (tx+1)*TILE, (ty+1)*TILE)
            if gid in {2, 3}:
                fill = p["path"] if (tx + ty) % 2 == 0 else p["path2"]
            elif gid == 4:
                fill = p["water"] if (tx + ty) % 2 == 0 else p["water2"]
            elif gid == 8:
                fill = p["edge"]
            else:
                fill = p["ground"] if (tx + ty) % 3 else p["ground2"]
            draw.rectangle(box, fill=fill)
    # soften tile seams while retaining a painted 2D look
    image = image.filter(ImageFilter.GaussianBlur(1.2))
    draw = ImageDraw.Draw(image)
    stipple(draw, rng, (32, 32, w-32, h-32), 900, [(64, 86, 48), (123, 139, 82), (73, 94, 54)], (1, 2))
    return image


def draw_tree(draw: ImageDraw.ImageDraw, x: int, y: int, r: int, rng: random.Random, alpha: int = 255) -> None:
    shadow = (28, 45, 28, min(alpha, 130))
    draw.ellipse((x-r+5, y-r+8, x+r+5, y+r+8), fill=shadow)
    colors = [(44, 84, 46, alpha), (57, 103, 53, alpha), (76, 119, 60, alpha)]
    for ox, oy, rr in [(-r//3,0,r*2//3),(r//3,2,r*2//3),(0,-r//3,r*3//4)]:
        draw.ellipse((x+ox-rr, y+oy-rr, x+ox+rr, y+oy+rr), fill=rng.choice(colors), outline=(31,62,36,alpha), width=2)


def draw_fence(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, p: dict) -> None:
    cy = y + h//2
    draw.rounded_rectangle((x, cy-5, x+w, cy+5), radius=4, fill=p["wood"], outline=(67,43,28), width=2)
    for px in range(x+8, x+w, 28):
        draw.rounded_rectangle((px-4, y, px+4, y+h), radius=3, fill=p["wood2"], outline=(67,43,28), width=1)


def draw_wagon(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, p: dict) -> None:
    draw.rounded_rectangle((x+12, y+8, x+w-10, y+h-14), radius=7, fill=p["wood"], outline=(58,37,24), width=3)
    for off in (18, w-28):
        draw.ellipse((x+off-11, y+h-25, x+off+11, y+h-3), fill=(53,42,32), outline=(27,22,18), width=3)
    draw.line((x+w-10, y+h//2, x+w+24, y+h//2+15), fill=(70,48,30), width=6)


def add_environment(area: str, image: Image.Image, root: ET.Element) -> tuple[Image.Image, Image.Image]:
    p = PALETTES[area]
    rng = seeded(area + "env")
    draw = ImageDraw.Draw(image, "RGBA")
    fg = Image.new("RGBA", image.size, (0,0,0,0))
    fgd = ImageDraw.Draw(fg, "RGBA")
    width, height = image.size

    # Boundary vegetation: drawn into foreground so actors can pass visually beneath crowns near openings.
    for x in range(20, width, 54):
        draw_tree(fgd, x + rng.randint(-8,8), 22 + rng.randint(-5,8), rng.randint(22,30), rng, 235)
        draw_tree(fgd, x + rng.randint(-8,8), height-18 + rng.randint(-8,5), rng.randint(22,31), rng, 235)
    for y in range(70, height-50, 62):
        left_open = ((area == "village_outskirts" and 245 <= y <= 395)
                     or (area == "village_riverside" and y >= 515)
                     or (area == "wilds_road" and 245 <= y <= 395)
                     or (area == "wilds_ruins" and y >= 440)
                     or (area == "wilds_riverbank" and (95 <= y <= 220 or y >= 440)))
        right_open = ((area in {"village_riverside", "village_outskirts"} and 245 <= y <= 395)
                      or (area == "wilds_road" and (95 <= y <= 220 or y >= 440))
                      or (area == "wilds_ruins" and 95 <= y <= 220)
                      or (area == "wilds_riverbank" and 245 <= y <= 395))
        if not left_open:
            draw_tree(fgd, 18 + rng.randint(-5,8), y, rng.randint(23,31), rng, 235)
        if not right_open:
            draw_tree(fgd, width-18 + rng.randint(-8,5), y, rng.randint(23,31), rng, 235)

    if area == "village_riverside":
        # Water refinement and reeds, respecting the shallow-water/southwest layout.
        draw.rounded_rectangle((48, 468, 335, 590), radius=34, fill=(47,101,119,230), outline=(35,77,89,255), width=4)
        for yy in range(485, 578, 18):
            for xx in range(68, 320, 46):
                draw.arc((xx, yy, xx+28, yy+10), 190, 345, fill=(137,190,190,170), width=2)
        for _ in range(70):
            x, y = rng.randint(45,350), rng.randint(430,600)
            draw.line((x,y,x+rng.randint(-4,4),y-rng.randint(10,24)), fill=(83,117,55,230), width=2)
        draw_fence(draw, 256, 448, 544, 32, p)
        # Herbalist work area near NPC, no collision footprint.
        draw.rounded_rectangle((690, 272, 825, 355), radius=12, fill=(103,78,47,230), outline=(61,45,30,255), width=3)
        for py in range(286, 344, 18):
            draw.line((705,py,812,py), fill=(57,93,46,255), width=7)
            for px in range(710,812,20):
                draw.ellipse((px-3,py-5,px+4,py+3), fill=(141,171,73,255))
        # Clear visual corridors around both exits.
        draw.rounded_rectangle((875, 275, 1024, 365), radius=18, fill=(157,132,88,210))
        draw.rounded_rectangle((75, 545, 155, 640), radius=18, fill=(150,126,84,210))
    elif area == "village_outskirts":
        # Main east-west approach, village palisade fragments, encounter clearing.
        draw.rounded_rectangle((32, 270, 992, 370), radius=40, fill=(153,127,85,205))
        draw_fence(draw, 448, 224, 160, 48, p)
        draw_wagon(draw, 512, 384, 128, 64, p)
        draw.ellipse((555, 255, 745, 430), outline=(104,79,54,110), width=4)
        for _ in range(35):
            x, y = rng.randint(70,950), rng.choice([rng.randint(80,210), rng.randint(455,570)])
            rr = rng.randint(5,12)
            draw.ellipse((x-rr,y-rr//2,x+rr,y+rr//2), fill=(91,92,72,220), outline=(58,61,49,230))
        draw.rounded_rectangle((0, 274, 145, 366), radius=18, fill=(157,132,88,210))
        draw.rounded_rectangle((875, 274, 1024, 366), radius=18, fill=(157,132,88,210))
    elif area == "wilds_road":
        draw.line((35,320,420,320,560,260,760,330,990,160), fill=(151,126,84,230), width=88, joint="curve")
        draw.line((720,350,990,510), fill=(151,126,84,225), width=78)
        # fallen log obstacle and broken tower footprint
        draw.rounded_rectangle((416,300,576,340), radius=18, fill=(90,58,34,255), outline=(48,34,24,255), width=4)
        for x in range(430,565,26):
            draw.line((x,294,x-8,278), fill=(62,43,28,255), width=5)
        draw.rectangle((704,96,800,192), fill=(83,83,70,245), outline=(45,47,42,255), width=4)
        draw.rectangle((724,116,780,192), fill=(41,48,42,255))
        for _ in range(55):
            x,y=rng.randint(70,950),rng.randint(60,575)
            if 250 < y < 390: continue
            rr=rng.randint(4,10); draw.ellipse((x-rr,y-rr//2,x+rr,y+rr//2),fill=(79,83,64,220))
    elif area == "wilds_ruins":
        # ruined masonry, oil slick and surviving embers
        draw.rounded_rectangle((45,470,210,570), radius=28, fill=(130,116,86,215))
        draw.rounded_rectangle((850,105,1024,205), radius=28, fill=(130,116,86,215))
        draw.rectangle((320,160,448,256), fill=(91,91,79,245), outline=(50,52,47,255), width=4)
        for gx in range(326,445,28): draw.line((gx,165,gx,251), fill=(119,116,99,180), width=3)
        draw.rectangle((608,352,736,448), fill=(75,72,61,245), outline=(43,42,38,255), width=4)
        draw.ellipse((625,366,720,430), fill=(34,31,28,255), outline=(121,88,48,255), width=4)
        draw.ellipse((496,320,624,416), fill=(55,45,36,180), outline=(92,71,47,180), width=3)
        for cx,cy in [(680,325),(706,345),(666,360)]:
            draw.polygon([(cx,cy+18),(cx-12,cy+2),(cx,cy-20),(cx+12,cy+2)], fill=(229,113,39,230))
        for _ in range(70):
            x,y=rng.randint(55,960),rng.randint(55,585); rr=rng.randint(3,9)
            draw.rectangle((x-rr,y-rr//2,x+rr,y+rr//2),fill=(83,82,70,200))
    elif area == "wilds_riverbank":
        draw.rounded_rectangle((235,370,790,560), radius=65, fill=(44,103,121,235), outline=(31,75,88,255), width=5)
        draw.rounded_rectangle((352,384,672,480), radius=42, fill=(30,73,91,245), outline=(24,61,76,255), width=4)
        for yy in range(400,545,22):
            for xx in range(260,760,52): draw.arc((xx,yy,xx+34,yy+12),190,345,fill=(135,189,191,155),width=2)
        for _ in range(95):
            x,y=rng.randint(220,810),rng.randint(345,585)
            draw.line((x,y,x+rng.randint(-5,5),y-rng.randint(10,25)),fill=(79,116,54,220),width=2)
        draw.rounded_rectangle((0,115,145,205),radius=20,fill=(151,126,84,220))
        draw.rounded_rectangle((0,460,145,555),radius=20,fill=(151,126,84,220))
        draw.rounded_rectangle((875,275,1024,365),radius=20,fill=(151,126,84,220))

    # Gentle vignette, excluded from center readability.
    vignette = Image.new("RGBA", image.size, (0,0,0,0))
    vd = ImageDraw.Draw(vignette, "RGBA")
    for i in range(28):
        a = max(0, 3 + i//2)
        vd.rectangle((i,i,width-i-1,height-i-1), outline=(18,25,20,a), width=1)
    image = Image.alpha_composite(image.convert("RGBA"), vignette).convert("RGB")
    return image, fg


def generate(project_root: Path, area: str) -> None:
    tmx = project_root / f"RiftExpedition/Resources/Maps/chapter1/{area}.tmx"
    root = ET.parse(tmx).getroot()
    image = draw_tile_base(area, root)
    image, foreground = add_environment(area, image, root)
    source_dir = project_root / "Tools/MapArtPipeline/Sources"
    source_dir.mkdir(parents=True, exist_ok=True)
    image.save(source_dir / f"{area}_source.png", optimize=True)
    foreground.save(source_dir / f"{area}_foreground_source.png", optimize=True)
    print(f"Generated {area} deterministic sources")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--area", action="append", choices=sorted(PALETTES), required=True)
    args = parser.parse_args()
    for area in args.area:
        generate(args.project_root.resolve(), area)


if __name__ == "__main__":
    main()
