#!/usr/bin/env python3
"""Slice the 4 direction strips (each a 2x6 grid of 12 poses with black grid
lines, verified consistent boundaries via detect_lines.py) into cells, chroma
key + trim + fit each cell to 96x96, and compose the final 4x12 = 1152x384
contact sheet in direction order down/left/right/up and pose order
idle1-3/walk1-3/attack1-3/hurt1-3.

Note: the strips now have a solid BLACK border around the whole sheet (we
asked for grid lines), so sampling the key color from the full image's outer
corners grabs black, not the green background. Instead we sample from the
corners of each cell's own interior (inside the grid lines)."""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

CELL_SIZE = 96
PADDING = 4
BLACK_THRESHOLD = 60
LINE_MIN_FRACTION = 0.5
LINE_GAP = 3
LINE_INSET = 2


def find_line_groups(frac, min_frac=LINE_MIN_FRACTION):
    idx = np.where(frac >= min_frac)[0]
    if len(idx) == 0:
        return []
    groups = []
    cur = [idx[0]]
    for value in idx[1:]:
        if value - cur[-1] <= LINE_GAP:
            cur.append(value)
        else:
            groups.append(cur)
            cur = [value]
    groups.append(cur)
    return [(int(group[0]), int(group[-1])) for group in groups]


def ranges_between_lines(lines):
    ranges = []
    for left, right in zip(lines, lines[1:]):
        start = left[1] + 1 + LINE_INSET
        end = right[0] - LINE_INSET
        if end <= start:
            raise ValueError(f"invalid grid range from lines {left} and {right}")
        ranges.append((start, end))
    return ranges


def detect_grid_ranges(arr):
    is_black = (
        (arr[..., 0] < BLACK_THRESHOLD)
        & (arr[..., 1] < BLACK_THRESHOLD)
        & (arr[..., 2] < BLACK_THRESHOLD)
    )
    col_lines = find_line_groups(is_black.mean(axis=0))
    row_lines = find_line_groups(is_black.mean(axis=1))
    if len(col_lines) < 2 or len(row_lines) < 2:
        raise ValueError(f"could not detect sprite grid: col_lines={col_lines}, row_lines={row_lines}")

    col_ranges = ranges_between_lines(col_lines)
    row_ranges = ranges_between_lines(row_lines)
    tile_count = len(col_ranges) * len(row_ranges)
    if tile_count != 12:
        raise ValueError(
            f"expected 12 grid cells, got {tile_count}: "
            f"columns={len(col_ranges)}, rows={len(row_ranges)}, "
            f"col_lines={col_lines}, row_lines={row_lines}"
        )
    return col_ranges, row_ranges


def compute_global_key(arr, col_ranges, row_ranges, patch=10):
    samples = []
    for (ry0, ry1) in row_ranges:
        for (cx0, cx1) in col_ranges:
            sample_size = min(patch, max(1, (cx1 - cx0) // 4), max(1, (ry1 - ry0) // 4))
            samples.append(arr[ry0:ry0 + sample_size, cx0:cx0 + sample_size].reshape(-1, 3))
            samples.append(arr[ry0:ry0 + sample_size, cx1 - sample_size:cx1].reshape(-1, 3))
            samples.append(arr[ry1 - sample_size:ry1, cx0:cx0 + sample_size].reshape(-1, 3))
            samples.append(arr[ry1 - sample_size:ry1, cx1 - sample_size:cx1].reshape(-1, 3))
    all_samples = np.concatenate(samples, axis=0)
    return np.median(all_samples, axis=0)


def chroma_key_to_alpha(arr, key, transparent_threshold=12, opaque_threshold=220, despill=True):
    diff = arr - key[None, None, :]
    dist = np.sqrt((diff ** 2).sum(axis=-1))
    lo = transparent_threshold * 3.0
    hi = opaque_threshold * 1.2
    alpha = np.clip((dist - lo) / max(hi - lo, 1e-6), 0.0, 1.0)
    out = arr.copy()
    if despill:
        key_channel = int(np.argmax(key))
        other = [c for c in range(3) if c != key_channel]
        other_mean = out[..., other].mean(axis=-1)
        spill_mask = (alpha > 0) & (alpha < 1)
        out[..., key_channel] = np.where(spill_mask, np.minimum(out[..., key_channel], other_mean), out[..., key_channel])
    out_rgba = np.dstack([out, alpha * 255.0]).astype(np.uint8)
    return out_rgba


def trim_alpha(img_rgba):
    arr = np.array(img_rgba)
    alpha = arr[..., 3]
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0 or len(ys) == 0:
        return img_rgba
    x0, x1 = xs.min(), xs.max() + 1
    y0, y1 = ys.min(), ys.max() + 1
    return img_rgba.crop((x0, y0, x1, y1))


def fit_center(img_rgba, cell_size, padding):
    target = cell_size - 2 * padding
    w, h = img_rgba.size
    scale = min(target / w, target / h) if w > 0 and h > 0 else 1.0
    new_w = max(1, round(w * scale))
    new_h = max(1, round(h * scale))
    resized = img_rgba.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
    off_x = (cell_size - new_w) // 2
    off_y = (cell_size - new_h) // 2
    canvas.alpha_composite(resized, (off_x, off_y))
    return canvas


def slice_strip(path, debug_prefix=None):
    src = Image.open(path).convert("RGB")
    arr = np.array(src).astype(np.float32)
    col_ranges, row_ranges = detect_grid_ranges(arr)
    key = compute_global_key(arr, col_ranges, row_ranges)
    keyed = chroma_key_to_alpha(arr, key)
    keyed_img = Image.fromarray(keyed, mode="RGBA")

    tiles = []
    for (ry0, ry1) in row_ranges:
        for (cx0, cx1) in col_ranges:
            cell = keyed_img.crop((cx0, ry0, cx1, ry1))
            trimmed = trim_alpha(cell)
            tile = fit_center(trimmed, CELL_SIZE, PADDING)
            tiles.append(tile)
    if debug_prefix:
        for i, t in enumerate(tiles):
            t.save(f"{debug_prefix}_{i:02d}.png")
    print(f"{path}: grid={len(col_ranges)}x{len(row_ranges)} key={key} -> {len(tiles)} tiles")
    return tiles


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--down", required=True)
    ap.add_argument("--left", required=True)
    ap.add_argument("--right", required=True)
    ap.add_argument("--up", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--debug-dir", default=None)
    args = ap.parse_args()
    if args.debug_dir:
        Path(args.debug_dir).mkdir(parents=True, exist_ok=True)

    direction_order = ["down", "left", "right", "up"]
    strip_paths = {"down": args.down, "left": args.left, "right": args.right, "up": args.up}

    rows_tiles = []
    for d in direction_order:
        prefix = f"{args.debug_dir}/{d}" if args.debug_dir else None
        tiles = slice_strip(strip_paths[d], debug_prefix=prefix)
        rows_tiles.append(tiles)

    columns = 12
    rows = 4
    out_w = columns * CELL_SIZE
    out_h = rows * CELL_SIZE
    canvas = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    for r, tiles in enumerate(rows_tiles):
        for c, tile in enumerate(tiles):
            canvas.alpha_composite(tile, (c * CELL_SIZE, r * CELL_SIZE))

    canvas.save(args.output)
    print(f"wrote {args.output} size={canvas.size}")


if __name__ == "__main__":
    main()
