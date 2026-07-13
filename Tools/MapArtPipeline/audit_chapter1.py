#!/usr/bin/env python3
from __future__ import annotations
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SPECS = json.loads((ROOT/'Tools/MapArtPipeline/map_art_specs.json').read_text())
REPORT = ROOT/'Docs/Reports/map-art/chapter1/full-audit.md'


def rect(obj):
    return tuple(float(obj.get(k,'0')) for k in ('x','y','width','height'))

def intersects(a,b):
    ax,ay,aw,ah=a; bx,by,bw,bh=b
    return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by

issues=[]; rows=[]
for area,spec in SPECS.items():
    tmx=ROOT/spec['tmx']; root=ET.parse(tmx).getroot()
    w=int(root.get('width'))*int(root.get('tilewidth')); h=int(root.get('height'))*int(root.get('tileheight'))
    bg=ROOT/spec['output']
    if not bg.is_file(): issues.append(f'{area}: missing background')
    else:
        with Image.open(bg) as im:
            if im.size!=(w,h): issues.append(f'{area}: background size {im.size} != {(w,h)}')
    fg_state='none'
    if not spec.get('foregroundOutput'):
        issues.append(f'{area}: foreground is not configured')
    if spec.get('foregroundOutput'):
        fg=ROOT/spec['foregroundOutput']; fg_state='ok'
        if not fg.is_file(): issues.append(f'{area}: missing foreground'); fg_state='missing'
        else:
            with Image.open(fg) as im:
                if im.size!=(w,h): issues.append(f'{area}: foreground size mismatch')
                if im.mode!='RGBA': issues.append(f'{area}: foreground must be RGBA')
                elif im.getchannel('A').getextrema()==(255,255): issues.append(f'{area}: foreground has no transparency')
    layers={x.get('name'):x for x in root.findall('imagelayer')}
    if 'background_art' not in layers: issues.append(f'{area}: missing background_art layer')
    if spec.get('foregroundLayerName') and spec['foregroundLayerName'] not in layers:
        issues.append(f'{area}: missing {spec["foregroundLayerName"]} layer')
    groups={g.get('name'):g for g in root.findall('objectgroup')}
    obstacles=[rect(o) for o in groups.get('navObstacle',[]).findall('object')] if groups.get('navObstacle') is not None else []
    exits=groups.get('exit')
    exit_count=0
    if exits is not None:
        for e in exits.findall('object'):
            exit_count += 1
            er=rect(e)
            # boundary overlap is expected; fail only when an exit is completely swallowed by an interior obstacle.
            for ob in obstacles:
                ox,oy,ow,oh=ob
                interior=ox>0 and oy>0 and ox+ow<w and oy+oh<h
                if interior and intersects(er,ob): issues.append(f'{area}: exit {e.get("name")} overlaps interior obstacle')
    rows.append((area,w,h,exit_count,fg_state,'PASS' if not any(i.startswith(area+':') for i in issues) else 'FAIL'))

REPORT.parent.mkdir(parents=True,exist_ok=True)
lines=['# Chapter 1 Map Art Audit','',f'- Areas: {len(rows)}',f'- Issues: {len(issues)}','', '| Area | Size | Exits | Foreground | Result |','|---|---:|---:|---|---|']
for area,w,h,ec,fg,result in rows: lines.append(f'| {area} | {w}×{h} | {ec} | {fg} | {result} |')
lines += ['', '## Findings', '']
lines += [f'- {i}' for i in issues] if issues else ['- None.']
REPORT.write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(f'Wrote {REPORT}')
if issues:
    raise SystemExit('\n'.join(issues))
