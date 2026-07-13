#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from PIL import Image


def rect(obj: ET.Element) -> tuple[float, float, float, float]:
    return tuple(float(obj.get(key, "0")) for key in ("x", "y", "width", "height"))  # type: ignore[return-value]


def intersects(
    first: tuple[float, float, float, float],
    second: tuple[float, float, float, float],
) -> bool:
    ax, ay, aw, ah = first
    bx, by, bw, bh = second
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by


def expected_image_source(output_path: Path, tmx_path: Path) -> str:
    return os.path.relpath(output_path, start=tmx_path.parent).replace(os.sep, "/")


def audit_project(
    root_path: Path,
) -> tuple[list[str], list[tuple[str, int, int, int, str, str]]]:
    specs_path = root_path / "Tools/MapArtPipeline/map_art_specs.json"
    specs: dict[str, dict[str, Any]] = json.loads(specs_path.read_text(encoding="utf-8"))
    issues: list[str] = []
    rows: list[tuple[str, int, int, int, str, str]] = []

    manifest_path = root_path / "RiftExpedition/Resources/Assets/assets-manifest.json"
    try:
        manifest_entries = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        manifest_entries = []
        issues.append(f"map-art manifest cannot be read: {error}")
    if not isinstance(manifest_entries, list):
        manifest_entries = []
        issues.append("map-art manifest top-level value must be an array")

    expected_manifest_ids: list[str] = []
    expected_manifest_paths: list[str] = []
    expected_runtime_files: set[Path] = set()
    for spec in specs.values():
        expected_manifest_ids.append(spec["assetID"])
        expected_manifest_paths.append(
            Path(spec["output"]).relative_to("RiftExpedition/Resources").as_posix()
        )
        expected_runtime_files.add((root_path / spec["output"]).resolve())
        if spec.get("foregroundOutput"):
            expected_manifest_ids.append(spec["foregroundAssetID"])
            expected_manifest_paths.append(
                Path(spec["foregroundOutput"]).relative_to("RiftExpedition/Resources").as_posix()
            )
            expected_runtime_files.add((root_path / spec["foregroundOutput"]).resolve())

    map_art_entries = [
        entry for entry in manifest_entries
        if isinstance(entry, dict) and entry.get("type") == "map-art"
    ]
    actual_manifest_ids = [str(entry.get("id", "")) for entry in map_art_entries]
    actual_manifest_paths = [str(entry.get("path", "")) for entry in map_art_entries]
    if sorted(actual_manifest_ids) != sorted(expected_manifest_ids):
        issues.append(
            "map-art manifest ids do not exactly match specs: "
            f"actual={sorted(actual_manifest_ids)!r}, expected={sorted(expected_manifest_ids)!r}"
        )
    if sorted(actual_manifest_paths) != sorted(expected_manifest_paths):
        issues.append(
            "map-art manifest paths do not exactly match specs: "
            f"actual={sorted(actual_manifest_paths)!r}, expected={sorted(expected_manifest_paths)!r}"
        )

    runtime_directory = root_path / "RiftExpedition/Resources/Assets/MapArt/chapter1"
    actual_runtime_files = {
        candidate.resolve()
        for candidate in runtime_directory.rglob("*.png")
        if candidate.is_file()
    } if runtime_directory.is_dir() else set()
    if actual_runtime_files != expected_runtime_files:
        extra = sorted(path.as_posix() for path in actual_runtime_files - expected_runtime_files)
        missing = sorted(path.as_posix() for path in expected_runtime_files - actual_runtime_files)
        issues.append(f"runtime map-art files differ from specs: extra={extra!r}, missing={missing!r}")

    for area, spec in specs.items():
        tmx_path = root_path / spec["tmx"]
        map_root = ET.parse(tmx_path).getroot()
        width = int(map_root.get("width", "0")) * int(map_root.get("tilewidth", "0"))
        height = int(map_root.get("height", "0")) * int(map_root.get("tileheight", "0"))

        background_path = root_path / spec["output"]
        if not background_path.is_file():
            issues.append(f"{area}: missing background")
        else:
            with Image.open(background_path) as image:
                if image.size != (width, height):
                    issues.append(f"{area}: background size {image.size} != {(width, height)}")

        foreground_state = "none"
        foreground_output = spec.get("foregroundOutput")
        if not foreground_output:
            issues.append(f"{area}: foreground is not configured")
        else:
            foreground_path = root_path / foreground_output
            foreground_state = "ok"
            if not foreground_path.is_file():
                issues.append(f"{area}: missing foreground")
                foreground_state = "missing"
            else:
                with Image.open(foreground_path) as image:
                    if image.size != (width, height):
                        issues.append(f"{area}: foreground size mismatch")
                    if image.mode != "RGBA":
                        issues.append(f"{area}: foreground must be RGBA")
                    elif image.getchannel("A").getextrema() == (255, 255):
                        issues.append(f"{area}: foreground has no transparency")

        image_layers = map_root.findall("imagelayer")
        actual_layer_names = [layer.get("name") for layer in image_layers]
        expected_layer_names = [spec["layerName"]]
        if foreground_output:
            expected_layer_names.append(spec["foregroundLayerName"])
        if sorted(actual_layer_names, key=lambda value: value or "") != sorted(expected_layer_names):
            issues.append(
                f"{area}: image layers {actual_layer_names!r} do not exactly match "
                f"{expected_layer_names!r}"
            )

        layers_by_name = {layer.get("name"): layer for layer in image_layers}
        expected_outputs = {spec["layerName"]: background_path}
        if foreground_output:
            expected_outputs[spec["foregroundLayerName"]] = root_path / foreground_output
        for layer_name, output_path in expected_outputs.items():
            layer = layers_by_name.get(layer_name)
            if layer is None:
                continue
            if layer.get("visible", "1") == "0":
                issues.append(f"{area}: {layer_name} is hidden")
            if layer.get("opacity", "1") != "1":
                issues.append(f"{area}: {layer_name} opacity must be 1")
            if layer.get("x", "0") != "0" or layer.get("y", "0") != "0":
                issues.append(f"{area}: {layer_name} position must be zero")
            if layer.get("offsetx") is not None or layer.get("offsety") is not None:
                issues.append(f"{area}: {layer_name} must not use offsets")
            images = layer.findall("image")
            if len(images) != 1:
                issues.append(f"{area}: {layer_name} image count is {len(images)}, expected 1")
                continue
            expected_source = expected_image_source(output_path, tmx_path)
            if images[0].get("source") != expected_source:
                issues.append(f"{area}: {layer_name} source does not match {expected_source}")

        groups = {group.get("name"): group for group in map_root.findall("objectgroup")}
        obstacle_group = groups.get("navObstacle")
        obstacles = [rect(obj) for obj in obstacle_group.findall("object")] if obstacle_group is not None else []
        exit_group = groups.get("exit")
        exit_count = 0
        if exit_group is not None:
            for exit_object in exit_group.findall("object"):
                exit_count += 1
                exit_rect = rect(exit_object)
                for obstacle in obstacles:
                    ox, oy, ow, oh = obstacle
                    is_interior = ox > 0 and oy > 0 and ox + ow < width and oy + oh < height
                    if is_interior and intersects(exit_rect, obstacle):
                        issues.append(
                            f"{area}: exit {exit_object.get('name')} overlaps interior obstacle"
                        )

        result = "FAIL" if any(issue.startswith(f"{area}:") for issue in issues) else "PASS"
        rows.append((area, width, height, exit_count, foreground_state, result))

    return issues, rows


def write_report(
    root_path: Path,
    issues: list[str],
    rows: list[tuple[str, int, int, int, str, str]],
) -> Path:
    report_path = root_path / "Docs/Reports/map-art/chapter1/full-audit.md"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Chapter 1 Map Art Audit",
        "",
        f"- Areas: {len(rows)}",
        f"- Issues: {len(issues)}",
        "",
        "| Area | Size | Exits | Foreground | Result |",
        "|---|---:|---:|---|---|",
    ]
    for area, width, height, exit_count, foreground_state, result in rows:
        lines.append(
            f"| {area} | {width}×{height} | {exit_count} | {foreground_state} | {result} |"
        )
    lines.extend(["", "## Findings", ""])
    lines.extend([f"- {issue}" for issue in issues] if issues else ["- None."])
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return report_path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
    )
    arguments = parser.parse_args()
    project_root = arguments.project_root.resolve()
    issues, rows = audit_project(project_root)
    report_path = write_report(project_root, issues, rows)
    print(f"Wrote {report_path}")
    if issues:
        raise SystemExit("\n".join(issues))


if __name__ == "__main__":
    main()
