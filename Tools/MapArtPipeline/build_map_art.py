#!/usr/bin/env python3
"""Build aligned map art and patch TMX without opening Tiled.

The script is intentionally deterministic: the input image, crop rule, map size,
object overrides and obstacle layout all live in map_art_specs.json.
"""
from __future__ import annotations

import argparse
import json
import os
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

PIPELINE_VERSION = "1"


def center_crop(image: Image.Image, target_ratio: float) -> Image.Image:
    width, height = image.size
    ratio = width / height
    if abs(ratio - target_ratio) < 1e-6:
        return image
    if ratio > target_ratio:
        crop_width = round(height * target_ratio)
        left = (width - crop_width) // 2
        return image.crop((left, 0, left + crop_width, height))
    crop_height = round(width / target_ratio)
    top = (height - crop_height) // 2
    return image.crop((0, top, width, top + crop_height))


def ensure_property(parent: ET.Element, name: str, value: str) -> None:
    properties = parent.find("properties")
    if properties is None:
        properties = ET.Element("properties")
        parent.insert(0, properties)
    prop = next((p for p in properties.findall("property") if p.get("name") == name), None)
    if prop is None:
        prop = ET.SubElement(properties, "property", {"name": name})
    prop.set("value", value)


def property_value(obj: ET.Element, name: str) -> str | None:
    properties = obj.find("properties")
    if properties is None:
        return None
    for prop in properties.findall("property"):
        if prop.get("name") == name:
            return prop.get("value", "")
    return None


def find_object(group: ET.Element, selector: str) -> ET.Element:
    property_name, expected = selector.split(":", 1)
    for obj in group.findall("object"):
        if property_value(obj, property_name) == expected:
            return obj
    raise ValueError(f"Object selector not found in {group.get('name')}: {selector}")


def update_objects(root: ET.Element, overrides: dict[str, dict[str, dict[str, Any]]]) -> None:
    groups = {group.get("name", ""): group for group in root.findall("objectgroup")}
    for group_name, selections in overrides.items():
        group = groups.get(group_name)
        if group is None:
            raise ValueError(f"Missing object group: {group_name}")
        for selector, values in selections.items():
            obj = find_object(group, selector)
            for key in ("x", "y", "width", "height"):
                if key in values:
                    obj.set(key, str(values[key]))


def replace_obstacles(root: ET.Element, obstacles: list[dict[str, Any]]) -> None:
    group = next((g for g in root.findall("objectgroup") if g.get("name") == "navObstacle"), None)
    if group is None:
        raise ValueError("Missing navObstacle group")
    for child in list(group):
        if child.tag == "object":
            group.remove(child)
    for obstacle in obstacles:
        obj = ET.SubElement(group, "object", {
            "id": str(obstacle["id"]),
            "name": obstacle["name"],
            "x": str(obstacle["x"]),
            "y": str(obstacle["y"]),
            "width": str(obstacle["width"]),
            "height": str(obstacle["height"]),
        })
        properties = ET.SubElement(obj, "properties")
        ET.SubElement(properties, "property", {
            "name": "blocksMovement",
            "value": "true" if obstacle["blocksMovement"] else "false",
        })
        ET.SubElement(properties, "property", {
            "name": "blocksSight",
            "value": "true" if obstacle["blocksSight"] else "false",
        })


def ensure_image_layer(root: ET.Element, map_path: Path, output_path: Path, layer_name: str, width: int, height: int) -> None:
    layer = next((element for element in root.findall("imagelayer") if element.get("name") == layer_name), None)
    if layer is None:
        next_layer_id = int(root.get("nextlayerid", "1"))
        layer = ET.Element("imagelayer", {"id": str(next_layer_id), "name": layer_name, "x": "0", "y": "0"})
        root.set("nextlayerid", str(next_layer_id + 1))
        children = list(root)
        first_layer_index = next((i for i, child in enumerate(children) if child.tag in {"layer", "objectgroup", "imagelayer", "group"}), len(children))
        root.insert(first_layer_index, layer)
    image = layer.find("image")
    if image is None:
        image = ET.SubElement(layer, "image")
    relative = os.path.relpath(output_path, start=map_path.parent).replace(os.sep, "/")
    image.set("source", relative)
    image.set("width", str(width))
    image.set("height", str(height))


def update_manifest(project_root: Path, spec: dict[str, Any]) -> None:
    manifest_path = project_root / "RiftExpedition/Resources/Assets/assets-manifest.json"
    entries = json.loads(manifest_path.read_text())
    output = Path(spec["output"])
    relative_to_resources = output.relative_to(Path("RiftExpedition/Resources")).as_posix()
    entry = {
        "id": spec["assetID"],
        "path": relative_to_resources,
        "type": "map-art",
        "source": "AI-generated top-down 2D environment aligned and cropped by Tools/MapArtPipeline",
        "license": "ai-static",
        "downloadedAt": "2026-07-12",
        "author": "AI-generated, integrated by Rift Expedition project"
    }
    entries = [item for item in entries if item.get("id") != entry["id"] and item.get("path") != entry["path"]]
    entries.append(entry)
    manifest_path.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n")


def draw_overlay(image: Image.Image, root: ET.Element, output: Path) -> None:
    base = image.convert("RGBA")
    marks = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(marks, "RGBA")
    colors = {
        "navObstacle": (220, 38, 38, 70),
        "spawn": (16, 185, 129, 220),
        "npc": (250, 204, 21, 220),
        "trigger": (192, 132, 252, 100),
        "exit": (59, 130, 246, 110),
        "encounter": (239, 68, 68, 100),
        "item": (245, 158, 11, 220),
    }
    for group in root.findall("objectgroup"):
        name = group.get("name", "")
        if name not in colors:
            continue
        color = colors[name]
        for obj in group.findall("object"):
            x = float(obj.get("x", "0")); y = float(obj.get("y", "0"))
            width = float(obj.get("width", "0")); height = float(obj.get("height", "0"))
            if width > 0 and height > 0:
                draw.rectangle((x, y, x + width, y + height), fill=color, outline=color[:3] + (255,), width=2)
            else:
                draw.ellipse((x - 7, y - 7, x + 7, y + 7), fill=color)
    output.parent.mkdir(parents=True, exist_ok=True)
    Image.alpha_composite(base, marks).convert("RGB").save(output)


def write_report(project_root: Path, area_id: str, spec: dict[str, Any], map_width: int, map_height: int, overlay: Path) -> None:
    report = project_root / f"Docs/Reports/map-art/chapter1/{area_id}.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(
        f"# Map Art Build: {area_id}\n\n"
        f"- Pipeline version: {PIPELINE_VERSION}\n"
        f"- Output size: {map_width} x {map_height}\n"
        f"- TMX source: `{spec['tmx']}`\n"
        f"- Runtime art: `{spec['output']}`\n"
        f"- Collision objects: {len(spec.get('replaceObstacles', []))}\n"
        f"- Overlay preview: `{overlay.relative_to(project_root).as_posix()}`\n"
        f"- Tiled GUI required: no\n",
        encoding="utf-8"
    )


def build(project_root: Path, area_id: str, spec: dict[str, Any]) -> None:
    map_path = project_root / spec["tmx"]
    source_path = project_root / spec["source"]
    output_path = project_root / spec["output"]
    tree = ET.parse(map_path)
    root = tree.getroot()
    map_width = int(root.get("width", "0")) * int(root.get("tilewidth", "0"))
    map_height = int(root.get("height", "0")) * int(root.get("tileheight", "0"))
    if map_width <= 0 or map_height <= 0:
        raise ValueError(f"Invalid map dimensions for {area_id}")

    image = Image.open(source_path).convert("RGB")
    if spec.get("crop") == "center":
        image = center_crop(image, map_width / map_height)
    image = image.resize((map_width, map_height), Image.Resampling.LANCZOS)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path, optimize=True)

    ensure_property(root, "artAssetId", spec["assetID"])
    ensure_property(root, "artPipelineVersion", PIPELINE_VERSION)
    ensure_image_layer(root, map_path, output_path, spec["layerName"], map_width, map_height)
    terrain = next((layer for layer in root.findall("layer") if layer.get("name") == "terrain"), None)
    if terrain is not None:
        terrain.set("visible", "1" if spec.get("terrainVisible", True) else "0")
    update_objects(root, spec.get("objectOverrides", {}))
    if "replaceObstacles" in spec:
        replace_obstacles(root, spec["replaceObstacles"])
    max_object_id = max((int(obj.get("id", "0")) for group in root.findall("objectgroup") for obj in group.findall("object")), default=0)
    root.set("nextobjectid", str(max_object_id + 1))
    ET.indent(tree, space="  ")
    tree.write(map_path, encoding="UTF-8", xml_declaration=True)

    update_manifest(project_root, spec)
    overlay = project_root / f"Docs/Reports/map-art/chapter1/{area_id}_overlay.png"
    draw_overlay(image, root, overlay)
    write_report(project_root, area_id, spec, map_width, map_height, overlay)
    print(f"Built {area_id}: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--area", action="append", help="Area id. Repeat to build multiple maps.")
    args = parser.parse_args()
    project_root = args.project_root.resolve()
    specs = json.loads((project_root / "Tools/MapArtPipeline/map_art_specs.json").read_text())
    area_ids = args.area or sorted(specs)
    for area_id in area_ids:
        if area_id not in specs:
            raise SystemExit(f"Unknown area: {area_id}")
        build(project_root, area_id, specs[area_id])


if __name__ == "__main__":
    main()
