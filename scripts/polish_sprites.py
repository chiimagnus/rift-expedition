#!/usr/bin/env python3
# 一次性美术润色脚本：给现有的程序化像素美术资源统一补上「描边 + 明暗 + 简单五官」，
# 不重新设计每张图的轮廓（轮廓/配色是 P2 轮次已经按职业/威胁等级区分过的，继续保留），
# 只是让每张图看起来不再是纯色色块。跑一次即可，不接入构建流程。
from PIL import Image
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "RiftExpedition", "Resources", "Assets")

OUTLINE = (18, 16, 20, 255)


def add_outline(rgba):
    w, h = rgba.size
    src = rgba.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                continue
            dst[x, y] = src[x, y]
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            if any(0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0 for nx, ny in neighbors):
                dst[x, y] = OUTLINE
    return out


def add_shading(rgba, top=1.16, bottom=0.86):
    w, h = rgba.size
    px = rgba.load()
    for y in range(h):
        factor = top + (bottom - top) * (y / max(h - 1, 1))
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (
                min(255, max(0, int(r * factor))),
                min(255, max(0, int(g * factor))),
                min(255, max(0, int(b * factor))),
                a,
            )
    return rgba


def opaque_bbox(rgba):
    w, h = rgba.size
    px = rgba.load()
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] != 0:
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    if maxx < 0:
        return None
    return minx, miny, maxx, maxy


def add_eyes(rgba):
    box = opaque_bbox(rgba)
    if box is None:
        return rgba
    minx, miny, maxx, maxy = box
    head_h = max(2, int((maxy - miny) * 0.28))
    head_top = miny + max(1, int((maxy - miny) * 0.05))
    head_bottom = head_top + head_h
    center_x = (minx + maxx) // 2
    eye_y = min(head_bottom, miny + head_h)
    px = rgba.load()
    for dx in (-2, 2):
        ex = center_x + dx
        if 0 <= ex < rgba.size[0] and 0 <= eye_y < rgba.size[1] and px[ex, eye_y][3] != 0:
            px[ex, eye_y] = OUTLINE
    return rgba


def polish_frame(frame, humanoid):
    frame = add_shading(frame.copy())
    if humanoid:
        frame = add_eyes(frame)
    frame = add_outline(frame)
    return frame


def polish_single(path, humanoid):
    img = Image.open(path).convert("RGBA")
    polish_frame(img, humanoid).save(path)
    print("polished", path)


def polish_sheet(path, frame_count, humanoid):
    sheet = Image.open(path).convert("RGBA")
    w, h = sheet.size
    frame_w = w // frame_count
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for i in range(frame_count):
        box = (i * frame_w, 0, (i + 1) * frame_w, h)
        frame = sheet.crop(box)
        polished = polish_frame(frame, humanoid)
        out.paste(polished, box)
    out.save(path)
    print("polished sheet", path, frame_count, "frames")


if __name__ == "__main__":
    sprites_dir = os.path.join(ROOT, "Sprites")
    characters_dir = os.path.join(ROOT, "Characters")

    humanoid_singles = [
        "actor_warrior.png", "actor_archer.png", "actor_mage.png", "actor_rogue.png",
        "npc_elder.png",
    ]
    other_singles = [
        "enemy_boar.png", "enemy_raider.png", "enemy_spider.png",
        "prop_chest.png", "prop_woodpile.png",
    ]
    # enemy_raider 是人形劫掠者，单独按人形处理（加眼睛）；其余保持原样只补描边/明暗。
    humanoid_singles.append("enemy_raider.png")
    other_singles.remove("enemy_raider.png")

    for name in humanoid_singles:
        polish_single(os.path.join(sprites_dir, name), humanoid=True)
    for name in other_singles:
        polish_single(os.path.join(sprites_dir, name), humanoid=False)

    polish_sheet(os.path.join(characters_dir, "village_npcs.png"), 3, humanoid=True)
    polish_sheet(os.path.join(characters_dir, "human_enemies.png"), 3, humanoid=True)
    polish_sheet(os.path.join(characters_dir, "beasts_and_monsters.png"), 3, humanoid=False)
