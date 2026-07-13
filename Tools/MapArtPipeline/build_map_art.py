#!/usr/bin/env python3
"""Build aligned map art and export layout contracts without opening Tiled.

The pipeline treats TMX as the spatial source of truth. Ready art sources can be
cropped and attached to the map; pending maps can still export exact 1024x640
layout guides for image creation and collision review.
"""
from __future__ import annotations

import argparse
import json
import os
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

PIPELINE_VERSION = "3"
VALID_STATUSES = {"ready", "pending-source"}
GUIDE_GROUP_COLORS: dict[str, tuple[int, int, int, int]] = {
    "navObstacle": (220, 38, 38, 76),
    "spawn": (16, 185, 129, 230),
    "npc": (250, 204, 21, 210),
    "trigger": (192, 132, 252, 110),
    "exit": (59, 130, 246, 120),
    "encounter": (239, 68, 68, 120),
    "surface": (14, 165, 233, 95),
    "item": (245, 158, 11, 225),
}


def load_specs(project_root: Path) -> dict[str, dict[str, Any]]:
    path = project_root / "Tools/MapArtPipeline/map_art_specs.json"
    return json.loads(path.read_text(encoding="utf-8"))


def load_world_areas(project_root: Path) -> list[dict[str, Any]]:
    path = project_root / "RiftExpedition/Resources/Data/worlds/chapter1.json"
    world = json.loads(path.read_text(encoding="utf-8"))
    return world["areas"]


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


def map_pixel_size(root: ET.Element) -> tuple[int, int]:
    width = int(root.get("width", "0")) * int(root.get("tilewidth", "0"))
    height = int(root.get("height", "0")) * int(root.get("tileheight", "0"))
    return width, height


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
        actual = obj.get("id") if property_name == "tiledID" else property_value(obj, property_name)
        if actual == expected:
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
        first_layer_index = next(
            (i for i, child in enumerate(children) if child.tag in {"layer", "objectgroup", "imagelayer", "group"}),
            len(children),
        )
        root.insert(first_layer_index, layer)
    image = layer.find("image")
    if image is None:
        image = ET.SubElement(layer, "image")
    relative = os.path.relpath(output_path, start=map_path.parent).replace(os.sep, "/")
    image.set("source", relative)
    image.set("width", str(width))
    image.set("height", str(height))


def update_manifest_entry(project_root: Path, *, asset_id: str, output: str, source_description: str) -> None:
    manifest_path = project_root / "RiftExpedition/Resources/Assets/assets-manifest.json"
    entries = json.loads(manifest_path.read_text(encoding="utf-8"))
    output = Path(output)
    relative_to_resources = output.relative_to(Path("RiftExpedition/Resources")).as_posix()
    entry = {
        "id": asset_id,
        "path": relative_to_resources,
        "type": "map-art",
        "source": source_description,
        "license": "ai-static",
        "downloadedAt": "2026-07-12",
        "author": "AI-generated, integrated by Rift Expedition project",
    }
    entries = [item for item in entries if item.get("id") != entry["id"] and item.get("path") != entry["path"]]
    entries.append(entry)
    manifest_path.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def update_manifest(project_root: Path, spec: dict[str, Any]) -> None:
    update_manifest_entry(
        project_root,
        asset_id=spec["assetID"],
        output=spec["output"],
        source_description=spec.get("sourceDescription", "Top-down 2D environment aligned by Tools/MapArtPipeline"),
    )
    if spec.get("foregroundOutput") and spec.get("foregroundAssetID"):
        update_manifest_entry(
            project_root,
            asset_id=spec["foregroundAssetID"],
            output=spec["foregroundOutput"],
            source_description=spec.get("foregroundSourceDescription", "Transparent foreground occlusion art aligned by Tools/MapArtPipeline"),
        )


def draw_object_overlay(image: Image.Image, root: ET.Element, *, include_labels: bool) -> Image.Image:
    base = image.convert("RGBA")
    marks = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(marks, "RGBA")
    for group in root.findall("objectgroup"):
        name = group.get("name", "")
        color = GUIDE_GROUP_COLORS.get(name)
        if color is None:
            continue
        for obj in group.findall("object"):
            x = float(obj.get("x", "0"))
            y = float(obj.get("y", "0"))
            width = float(obj.get("width", "0"))
            height = float(obj.get("height", "0"))
            if width > 0 and height > 0:
                draw.rectangle((x, y, x + width, y + height), fill=color, outline=color[:3] + (255,), width=2)
                label_x, label_y = x + 3, y + 3
            else:
                draw.ellipse((x - 7, y - 7, x + 7, y + 7), fill=color, outline=color[:3] + (255,))
                label_x, label_y = x + 8, y - 6
            if include_labels:
                label = f"{name}:{obj.get('id', '?')}"
                draw.text((label_x, label_y), label, fill=(20, 20, 24, 255), stroke_width=2, stroke_fill=(255, 255, 255, 230))
    return Image.alpha_composite(base, marks)


def draw_overlay(image: Image.Image, root: ET.Element, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    draw_object_overlay(image, root, include_labels=False).convert("RGB").save(output)


def object_contract(root: ET.Element) -> dict[str, list[dict[str, Any]]]:
    contract: dict[str, list[dict[str, Any]]] = {}
    for group in root.findall("objectgroup"):
        name = group.get("name", "")
        if name not in GUIDE_GROUP_COLORS:
            continue
        contract[name] = []
        for obj in group.findall("object"):
            contract[name].append({
                "tiledID": int(obj.get("id", "0")),
                "name": obj.get("name", ""),
                "x": float(obj.get("x", "0")),
                "y": float(obj.get("y", "0")),
                "width": float(obj.get("width", "0")),
                "height": float(obj.get("height", "0")),
            })
    return contract


def write_layout_guide(
    project_root: Path,
    area: dict[str, Any],
    spec: dict[str, Any],
    output_directory: Path,
) -> dict[str, Any]:
    map_path = project_root / spec["tmx"]
    root = ET.parse(map_path).getroot()
    width, height = map_pixel_size(root)
    guide = Image.new("RGB", (width, height), (226, 220, 202))
    draw = ImageDraw.Draw(guide)
    for x in range(0, width + 1, 32):
        major = x % 128 == 0
        draw.line((x, 0, x, height), fill=(116, 108, 94) if major else (180, 171, 151), width=2 if major else 1)
    for y in range(0, height + 1, 32):
        major = y % 128 == 0
        draw.line((0, y, width, y), fill=(116, 108, 94) if major else (180, 171, 151), width=2 if major else 1)
    guide = draw_object_overlay(guide, root, include_labels=True).convert("RGB")
    header = ImageDraw.Draw(guide)
    header.rectangle((0, 0, min(width, 430), 30), fill=(22, 24, 30))
    header.text((8, 8), f"{area['id']} | {width}x{height} | {spec['status']}", fill=(255, 255, 255))

    output_directory.mkdir(parents=True, exist_ok=True)
    png_path = output_directory / f"{area['id']}_layout_guide.png"
    md_path = output_directory / f"{area['id']}_layout_contract.md"
    guide.save(png_path, optimize=True)

    objects = object_contract(root)
    counts = {name: len(values) for name, values in objects.items()}
    md_path.write_text(
        f"# Layout Contract: {area['id']}\n\n"
        f"- Display name: {area['displayName']}\n"
        f"- Biome: {area['biome']}\n"
        f"- Canvas: {width} x {height}\n"
        f"- Art status: {spec['status']}\n"
        f"- TMX: `{spec['tmx']}`\n"
        f"- Planned source: `{spec['source']}`\n"
        f"- Runtime output: `{spec['output']}`\n"
        f"- Object counts: `{json.dumps(counts, ensure_ascii=False, sort_keys=True)}`\n"
        f"- Guide: `{png_path.name}`\n\n"
        "## Non-negotiable art rules\n\n"
        "- Pure top-down 2D, near 90-degree bird's-eye camera.\n"
        "- No horizon, isometric projection, oblique cinematic camera, UI, labels, or large characters.\n"
        "- Keep every exit opening, interaction point, encounter zone, and walkable corridor readable at game scale.\n"
        "- Buildings, water, cliffs, and cave walls must visually agree with the red navObstacle regions.\n"
        "- Roofs, tree canopies, and cave overhangs intended to cover actors belong in separate foreground PNG layers.\n"
        "- No Tiled GUI required; the pipeline attaches approved art and patches TMX automatically.\n",
        encoding="utf-8",
    )
    return {
        "areaID": area["id"],
        "displayName": area["displayName"],
        "biome": area["biome"],
        "width": width,
        "height": height,
        "status": spec["status"],
        "source": spec["source"],
        "output": spec["output"],
        "objects": objects,
    }


def write_layout_guides(
    project_root: Path,
    specs: dict[str, dict[str, Any]],
    areas: list[dict[str, Any]],
    area_ids: list[str],
    output_directory: Path,
) -> None:
    by_id = {area["id"]: area for area in areas}
    contracts = [write_layout_guide(project_root, by_id[area_id], specs[area_id], output_directory) for area_id in area_ids]
    contract_path = output_directory / "chapter1_layout_contracts.json"
    contract_path.write_text(
        json.dumps({"pipelineVersion": PIPELINE_VERSION, "areas": contracts}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(contracts)} layout guides: {output_directory}")


def validate_contracts(
    project_root: Path,
    specs: dict[str, dict[str, Any]],
    areas: list[dict[str, Any]],
) -> list[str]:
    errors: list[str] = []
    world_ids = [area["id"] for area in areas]
    spec_ids = list(specs)
    if set(world_ids) != set(spec_ids):
        missing = sorted(set(world_ids) - set(spec_ids))
        extra = sorted(set(spec_ids) - set(world_ids))
        if missing:
            errors.append(f"Missing map-art specs: {', '.join(missing)}")
        if extra:
            errors.append(f"Unknown map-art specs: {', '.join(extra)}")

    asset_ids: set[str] = set()
    outputs: set[str] = set()
    area_by_id = {area["id"]: area for area in areas}
    for area_id, spec in specs.items():
        status = spec.get("status")
        if status not in VALID_STATUSES:
            errors.append(f"{area_id}: invalid status {status!r}")
        required = ["source", "tmx", "output", "assetID", "layerName"]
        for key in required:
            if not spec.get(key):
                errors.append(f"{area_id}: missing {key}")
        if spec.get("layerName") != "background_art":
            errors.append(f"{area_id}: layerName must be background_art")
        foreground_keys = ["foregroundSource", "foregroundOutput", "foregroundAssetID", "foregroundLayerName"]
        present_foreground = [key for key in foreground_keys if spec.get(key)]
        if present_foreground and len(present_foreground) != len(foreground_keys):
            errors.append(f"{area_id}: foreground fields must be provided together")
        if spec.get("foregroundLayerName") and not str(spec["foregroundLayerName"]).startswith("foreground_"):
            errors.append(f"{area_id}: foregroundLayerName must start with foreground_")

        asset_id = spec.get("assetID", "")
        if asset_id in asset_ids:
            errors.append(f"{area_id}: duplicate assetID {asset_id}")
        asset_ids.add(asset_id)
        output = spec.get("output", "")
        if output in outputs:
            errors.append(f"{area_id}: duplicate output {output}")
        outputs.add(output)

        map_path = project_root / spec.get("tmx", "")
        if not map_path.is_file():
            errors.append(f"{area_id}: missing TMX {map_path}")
            continue
        try:
            root = ET.parse(map_path).getroot()
            width, height = map_pixel_size(root)
            if width <= 0 or height <= 0:
                errors.append(f"{area_id}: invalid map dimensions {width}x{height}")
        except ET.ParseError as error:
            errors.append(f"{area_id}: invalid TMX XML: {error}")

        area = area_by_id.get(area_id)
        if area is not None:
            expected_tmx = (Path("RiftExpedition/Resources") / area["mapPath"]).as_posix()
            if Path(spec.get("tmx", "")).as_posix() != expected_tmx:
                errors.append(f"{area_id}: TMX path differs from world graph ({expected_tmx})")
        if status == "ready" and not (project_root / spec.get("source", "")).is_file():
            errors.append(f"{area_id}: ready source is missing")
        if status == "ready" and spec.get("foregroundSource") and not (project_root / spec["foregroundSource"]).is_file():
            errors.append(f"{area_id}: ready foreground source is missing")
    return errors


def write_report(project_root: Path, area_id: str, spec: dict[str, Any], map_width: int, map_height: int, overlay: Path) -> None:
    report = project_root / f"Docs/Reports/map-art/chapter1/{area_id}.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(
        f"# Map Art Build: {area_id}\n\n"
        f"- Pipeline version: {PIPELINE_VERSION}\n"
        f"- Output size: {map_width} x {map_height}\n"
        f"- TMX source: `{spec['tmx']}`\n"
        f"- Runtime art: `{spec['output']}`\n"
        f"- Foreground art: `{spec.get('foregroundOutput', 'none')}`\n"
        f"- Collision objects: {len(spec.get('replaceObstacles', []))}\n"
        f"- Overlay preview: `{overlay.relative_to(project_root).as_posix()}`\n"
        f"- Tiled GUI required: no\n",
        encoding="utf-8",
    )


def build(project_root: Path, area_id: str, spec: dict[str, Any]) -> None:
    if spec.get("status") != "ready":
        raise ValueError(
            f"{area_id} art source is not approved yet (status={spec.get('status')}). "
            "Generate a layout guide first, then add the approved top-down source and set status=ready."
        )

    map_path = project_root / spec["tmx"]
    source_path = project_root / spec["source"]
    output_path = project_root / spec["output"]
    tree = ET.parse(map_path)
    root = tree.getroot()
    map_width, map_height = map_pixel_size(root)
    if map_width <= 0 or map_height <= 0:
        raise ValueError(f"Invalid map dimensions for {area_id}")

    image = Image.open(source_path).convert("RGB")
    if spec.get("crop") == "center":
        image = center_crop(image, map_width / map_height)
    image = image.resize((map_width, map_height), Image.Resampling.LANCZOS)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path, optimize=True)

    foreground_image = None
    if spec.get("foregroundSource"):
        foreground_source = project_root / spec["foregroundSource"]
        foreground_output = project_root / spec["foregroundOutput"]
        foreground_image = Image.open(foreground_source).convert("RGBA")
        if spec.get("crop") == "center":
            foreground_image = center_crop(foreground_image, map_width / map_height)
        foreground_image = foreground_image.resize((map_width, map_height), Image.Resampling.LANCZOS)
        foreground_output.parent.mkdir(parents=True, exist_ok=True)
        foreground_image.save(foreground_output, optimize=True)

    ensure_property(root, "artAssetId", spec["assetID"])
    ensure_property(root, "artPipelineVersion", PIPELINE_VERSION)
    ensure_image_layer(root, map_path, output_path, spec["layerName"], map_width, map_height)
    if spec.get("foregroundOutput"):
        ensure_property(root, "foregroundArtAssetId", spec["foregroundAssetID"])
        ensure_image_layer(
            root,
            map_path,
            project_root / spec["foregroundOutput"],
            spec["foregroundLayerName"],
            map_width,
            map_height,
        )
    terrain = next((layer for layer in root.findall("layer") if layer.get("name") == "terrain"), None)
    if terrain is not None:
        terrain.set("visible", "1" if spec.get("terrainVisible", True) else "0")
    update_objects(root, spec.get("objectOverrides", {}))
    if "replaceObstacles" in spec:
        replace_obstacles(root, spec["replaceObstacles"])
    max_object_id = max(
        (int(obj.get("id", "0")) for group in root.findall("objectgroup") for obj in group.findall("object")),
        default=0,
    )
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
    parser.add_argument("--area", action="append", help="Area id. Repeat to select multiple maps.")
    parser.add_argument("--validate-contracts", action="store_true", help="Validate all chapter-one map-art contracts and exit.")
    parser.add_argument("--write-guides", type=Path, help="Write exact TMX layout guides and machine-readable contracts.")
    args = parser.parse_args()

    project_root = args.project_root.resolve()
    specs = load_specs(project_root)
    areas = load_world_areas(project_root)
    errors = validate_contracts(project_root, specs, areas)
    if errors:
        raise SystemExit("Map-art contract validation failed:\n- " + "\n- ".join(errors))

    if args.validate_contracts:
        ready_count = sum(spec.get("status") == "ready" for spec in specs.values())
        print(f"Map-art contracts valid: {len(specs)} areas, {ready_count} ready, {len(specs) - ready_count} pending-source")
        return

    selected = args.area or list(specs)
    unknown = [area_id for area_id in selected if area_id not in specs]
    if unknown:
        raise SystemExit(f"Unknown area: {', '.join(unknown)}")

    if args.write_guides is not None:
        output_directory = args.write_guides
        if not output_directory.is_absolute():
            output_directory = project_root / output_directory
        write_layout_guides(project_root, specs, areas, selected, output_directory)
        return

    area_ids = args.area or [area_id for area_id, spec in specs.items() if spec.get("status") == "ready"]
    for area_id in area_ids:
        build(project_root, area_id, specs[area_id])


if __name__ == "__main__":
    main()
