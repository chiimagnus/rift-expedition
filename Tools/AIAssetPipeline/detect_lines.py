#!/usr/bin/env python3
"""Detect black grid-line row/column positions in a strip image (used now that
we explicitly asked the model to draw black divider lines). Prints candidate
boundaries so we can hardcode them into slice_strip.py after a quick look."""
import sys
import numpy as np
from PIL import Image

path = sys.argv[1]
img = Image.open(path).convert("RGB")
arr = np.array(img).astype(np.int32)
h, w, _ = arr.shape

# a pixel counts as "black line" if all channels are low
is_black = (arr[..., 0] < 60) & (arr[..., 1] < 60) & (arr[..., 2] < 60)

col_black_frac = is_black.mean(axis=0)
row_black_frac = is_black.mean(axis=1)

def find_lines(frac, min_frac=0.8):
    idx = np.where(frac >= min_frac)[0]
    if len(idx) == 0:
        return []
    groups = []
    cur = [idx[0]]
    for x in idx[1:]:
        if x - cur[-1] <= 3:
            cur.append(x)
        else:
            groups.append(cur)
            cur = [x]
    groups.append(cur)
    return [(int(g[0]), int(g[-1]), int(np.mean(g))) for g in groups]

print("size", w, h)
print("col lines (start,end,center):", find_lines(col_black_frac))
print("row lines (start,end,center):", find_lines(row_black_frac))
