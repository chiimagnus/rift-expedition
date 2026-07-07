#!/usr/bin/env python3
"""Python approximation of Tools/RiftValidator/Sources/RiftValidator/AssetValidation.swift
Since no Swift toolchain is available in this sandbox, this re-implements the
same rules for a best-effort self-check. NOT a substitute for running the real
RiftValidator locally."""
import json
import sys
from pathlib import Path
from PIL import Image

REPO = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
RESOURCES_ROOT = REPO / 'RiftExpedition' / 'Resources'
MANIFEST_PATH = RESOURCES_ROOT / 'Assets' / 'assets-manifest.json'
ANIMATIONS_PATH = RESOURCES_ROOT / 'Assets' / 'actor-animations.json'

ALLOWED_LICENSES = {'CC0', 'self-made', 'ai-static'}
BANNED_ID_FRAGMENTS = ['placeholder', 'temp', 'graybox']
EXPECTED_FRAME_SIZE = (96, 96)
EXPECTED_SHEET_SIZE = (1152, 384)
EXPECTED_DIRECTIONS = ['down', 'left', 'right', 'up']
EXPECTED_ACTIONS = {
    'idle': (0, 3),
    'walk': (3, 3),
    'attack': (6, 3),
    'hurt': (9, 3),
}

issues = []

with open(MANIFEST_PATH) as f:
    manifest = json.load(f)

seen_ids = set()
manifest_by_id = {}
for entry in manifest:
    eid = entry.get('id', '')
    if eid in seen_ids:
        issues.append(f"duplicate manifest id: {eid}")
    seen_ids.add(eid)
    manifest_by_id[eid] = entry

    lower_id = eid.lower()
    for frag in BANNED_ID_FRAGMENTS:
        if frag in lower_id:
            issues.append(f"banned id fragment '{frag}' in id: {eid}")

    if entry.get('license') not in ALLOWED_LICENSES:
        issues.append(f"disallowed license '{entry.get('license')}' for id: {eid}")

    rel_path = entry.get('path', '')
    full_path = RESOURCES_ROOT / rel_path
    if not full_path.exists():
        issues.append(f"missing file for id {eid}: {rel_path}")

if ANIMATIONS_PATH.exists():
    with open(ANIMATIONS_PATH) as f:
        catalog = json.load(f)

    if catalog.get('version') != 1:
        issues.append(f"actor-animations.json: version must be 1, got {catalog.get('version')}")

    frame_size = catalog.get('frameSize', {})
    if (frame_size.get('width'), frame_size.get('height')) != EXPECTED_FRAME_SIZE:
        issues.append(f"actor-animations.json: frameSize must be {EXPECTED_FRAME_SIZE}, got {frame_size}")

    directions = catalog.get('directions', [])
    if directions != EXPECTED_DIRECTIONS:
        issues.append(f"actor-animations.json: directions must be {EXPECTED_DIRECTIONS}, got {directions}")

    actions = catalog.get('actions', {})
    if set(actions.keys()) != set(EXPECTED_ACTIONS.keys()):
        issues.append(f"actor-animations.json: actions keys must be {sorted(EXPECTED_ACTIONS.keys())}, got {sorted(actions.keys())}")
    else:
        occupied = set()
        for name, (exp_col, exp_count) in EXPECTED_ACTIONS.items():
            a = actions[name]
            if a.get('startColumn') != exp_col or a.get('frameCount') != exp_count:
                issues.append(f"actor-animations.json: action '{name}' expected startColumn={exp_col} frameCount={exp_count}, got {a}")
            cols = set(range(a.get('startColumn', 0), a.get('startColumn', 0) + a.get('frameCount', 0)))
            if occupied & cols:
                issues.append(f"actor-animations.json: action '{name}' columns overlap with another action: {sorted(occupied & cols)}")
            occupied |= cols

    seen_visual_ids = set()
    for sprite in catalog.get('sprites', []):
        vid = sprite.get('visualID')
        sheet_rel = sprite.get('sheet')
        if vid in seen_visual_ids:
            issues.append(f"actor-animations.json: duplicate visualID: {vid}")
        seen_visual_ids.add(vid)

        expected_sheet = f"Assets/Characters/{vid}_anim.png"
        if sheet_rel != expected_sheet:
            issues.append(f"actor-animations.json: sprite '{vid}' sheet must be '{expected_sheet}', got '{sheet_rel}'")

        sheet_full = RESOURCES_ROOT / sheet_rel
        if not sheet_full.exists():
            issues.append(f"actor-animations.json: sheet file missing for '{vid}': {sheet_rel}")
            continue

        manifest_entry = manifest_by_id.get(f"spritesheet.{vid}_anim")
        if manifest_entry is None:
            # fall back: search by path+type since id naming isn't contractually fixed
            matches = [e for e in manifest if e.get('path') == sheet_rel and e.get('type') == 'spritesheet']
            if not matches:
                issues.append(f"actor-animations.json: sheet for '{vid}' not registered as type=spritesheet in assets-manifest.json")
        elif manifest_entry.get('type') != 'spritesheet':
            issues.append(f"actor-animations.json: manifest entry for sheet '{sheet_rel}' must have type=spritesheet")

        with Image.open(sheet_full) as im:
            if im.size != EXPECTED_SHEET_SIZE:
                issues.append(f"actor-animations.json: sheet '{sheet_rel}' must be {EXPECTED_SHEET_SIZE}px, got {im.size}")

print(f"Checked {len(manifest)} manifest entries, actor-animations.json exists={ANIMATIONS_PATH.exists()}")
if issues:
    print(f"FOUND {len(issues)} ISSUE(S):")
    for i in issues:
        print(" -", i)
    sys.exit(1)
else:
    print("0 issues found (python approximation of RiftValidator asset checks)")
    sys.exit(0)
