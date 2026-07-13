import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

MODULE_PATH = Path(__file__).with_name("build_map_art.py")
SPEC = importlib.util.spec_from_file_location("build_map_art", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
pipeline = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(pipeline)


class MapArtPipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.project_root = Path(__file__).resolve().parents[2]
        cls.specs = pipeline.load_specs(cls.project_root)
        cls.areas = pipeline.load_world_areas(cls.project_root)

    def test_chapter_maps_have_single_painted_visual_source(self) -> None:
        for area_id, spec in self.specs.items():
            self.assertNotIn("terrainVisible", spec, area_id)
            root = ET.parse(self.project_root / spec["tmx"]).getroot()
            self.assertEqual(root.findall("tileset"), [], area_id)
            self.assertEqual(
                [layer for layer in root.findall("layer") if layer.get("name") == "terrain"],
                [],
                area_id,
            )

    def test_specs_cover_world_graph_and_validate(self) -> None:
        self.assertEqual(set(self.specs), {area["id"] for area in self.areas})
        self.assertEqual(pipeline.validate_contracts(self.project_root, self.specs, self.areas), [])
        self.assertEqual(sum(spec["status"] == "ready" for spec in self.specs.values()), 9)
        self.assertEqual(sum(spec["status"] == "pending-source" for spec in self.specs.values()), 0)

    def test_manifest_provenance_matches_each_map_art_source(self) -> None:
        manifest = json.loads(
            (self.project_root / "RiftExpedition/Resources/Assets/assets-manifest.json").read_text(encoding="utf-8")
        )
        by_id = {entry["id"]: entry for entry in manifest}
        for area_id, spec in self.specs.items():
            background = by_id[spec["assetID"]]
            self.assertEqual(background["source"], spec["sourceDescription"], area_id)
            self.assertEqual(background["license"], spec["license"], area_id)
            self.assertEqual(background["author"], spec["author"], area_id)
            if spec.get("foregroundAssetID"):
                foreground = by_id[spec["foregroundAssetID"]]
                self.assertEqual(foreground["source"], spec["foregroundSourceDescription"], area_id)
                self.assertEqual(foreground["license"], spec["foregroundLicense"], area_id)
                self.assertEqual(foreground["author"], spec["foregroundAuthor"], area_id)

        for area_id in {
            "village_riverside", "village_outskirts", "wilds_road", "wilds_ruins",
            "wilds_riverbank", "cave_entrance", "cave_mines",
        }:
            self.assertEqual(self.specs[area_id]["license"], "self-made")
        self.assertEqual(self.specs["village_square"]["license"], "ai-static")
        self.assertEqual(self.specs["cave_depths"]["license"], "ai-static")

    def test_pending_source_can_export_guide_without_source_image(self) -> None:
        area = next(area for area in self.areas if area["id"] == "cave_entrance")
        spec = dict(self.specs[area["id"]])
        spec["status"] = "pending-source"
        spec["source"] = "Tools/MapArtPipeline/Sources/not-created.png"
        self.assertFalse((self.project_root / spec["source"]).exists())

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            contract = pipeline.write_layout_guide(self.project_root, area, spec, output)
            image_path = output / "cave_entrance_layout_guide.png"
            markdown_path = output / "cave_entrance_layout_contract.md"

            self.assertTrue(image_path.is_file())
            self.assertTrue(markdown_path.is_file())
            with Image.open(image_path) as image:
                self.assertEqual(image.size, (1024, 640))
            self.assertEqual(contract["status"], "pending-source")
            self.assertIn("No Tiled GUI required", markdown_path.read_text(encoding="utf-8"))

    def test_ready_source_builds_runtime_art_in_isolated_project(self) -> None:
        spec = self.specs["village_square"]
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            for relative in [spec["tmx"], spec["source"], spec["foregroundSource"], "RiftExpedition/Resources/Assets/assets-manifest.json"]:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)

            pipeline.build(project, "village_square", spec)

            output = project / spec["output"]
            self.assertTrue(output.is_file())
            with Image.open(output) as image:
                self.assertEqual(image.size, (1024, 640))
            root = ET.parse(project / spec["tmx"]).getroot()
            properties = {
                prop.get("name"): prop.get("value")
                for prop in root.find("properties").findall("property")
            }
            self.assertEqual(properties["artPipelineVersion"], pipeline.PIPELINE_VERSION)
            self.assertNotIn("assetId", properties)
            self.assertEqual(root.findall("tileset"), [])
            self.assertEqual(root.findall("layer"), [])
            self.assertIsNotNone(next((layer for layer in root.findall("imagelayer") if layer.get("name") == "background_art"), None))


    def test_ready_source_with_foreground_builds_both_layers(self) -> None:
        spec = self.specs["village_riverside"]
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            relatives = [
                spec["tmx"],
                spec["source"],
                spec["foregroundSource"],
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in relatives:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)

            pipeline.build(project, "village_riverside", spec)

            with Image.open(project / spec["foregroundOutput"]) as image:
                self.assertEqual(image.size, (1024, 640))
                self.assertEqual(image.mode, "RGBA")
            root = ET.parse(project / spec["tmx"]).getroot()
            layer_names = {layer.get("name") for layer in root.findall("imagelayer")}
            self.assertIn("background_art", layer_names)
            self.assertIn(spec["foregroundLayerName"], layer_names)


    def test_build_rejects_duplicate_and_unexpected_image_layers(self) -> None:
        area = next(area for area in self.areas if area["id"] == "village_square")
        spec = self.specs[area["id"]]
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            relatives = [
                spec["tmx"],
                spec["source"],
                spec["foregroundSource"],
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in relatives:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)

            map_path = project / spec["tmx"]
            tree = ET.parse(map_path)
            root = tree.getroot()
            layer = next(layer for layer in root.findall("imagelayer") if layer.get("name") == spec["layerName"])
            duplicate = ET.fromstring(ET.tostring(layer, encoding="unicode"))
            duplicate.set("id", root.get("nextlayerid", "99"))
            root.append(duplicate)
            stale = ET.Element("imagelayer", {"id": "998", "name": "legacy_background"})
            ET.SubElement(stale, "image", {"source": "legacy.png", "width": "1024", "height": "640"})
            root.append(stale)
            tree.write(map_path, encoding="utf-8", xml_declaration=True)
            before = map_path.read_bytes()

            with self.assertRaisesRegex(ValueError, "unexpected image layers"):
                pipeline.build(project, area["id"], spec)

            self.assertEqual(before, map_path.read_bytes())


    def test_contract_rejects_unexpected_image_layer(self) -> None:
        area = next(area for area in self.areas if area["id"] == "village_square")
        spec = self.specs[area["id"]]
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            relatives = [
                spec["tmx"],
                spec["source"],
                spec["foregroundSource"],
                spec["output"],
                spec["foregroundOutput"],
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in relatives:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)

            map_path = project / spec["tmx"]
            tree = ET.parse(map_path)
            root = tree.getroot()
            stale = ET.Element("imagelayer", {"id": "998", "name": "legacy_background"})
            ET.SubElement(stale, "image", {"source": "legacy.png", "width": "1024", "height": "640"})
            root.append(stale)
            tree.write(map_path, encoding="utf-8", xml_declaration=True)

            errors = pipeline.validate_contracts(project, {area["id"]: spec}, [area])
            self.assertTrue(any("image layer names" in error for error in errors), errors)

    def test_chapter_audit_rejects_unexpected_image_layer(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            copy_paths = [
                "Tools/MapArtPipeline/map_art_specs.json",
                "RiftExpedition/Resources/Maps/chapter1",
                "RiftExpedition/Resources/Assets/MapArt/chapter1",
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in copy_paths:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                if source.is_dir():
                    shutil.copytree(source, destination)
                else:
                    shutil.copy2(source, destination)

            spec = self.specs["village_square"]
            map_path = project / spec["tmx"]
            tree = ET.parse(map_path)
            root = tree.getroot()
            stale = ET.Element("imagelayer", {"id": "998", "name": "legacy_background"})
            ET.SubElement(stale, "image", {"source": "legacy.png", "width": "1024", "height": "640"})
            root.append(stale)
            tree.write(map_path, encoding="utf-8", xml_declaration=True)

            result = subprocess.run(
                [
                    sys.executable,
                    str(self.project_root / "Tools/MapArtPipeline/audit_chapter1.py"),
                    "--project-root",
                    str(project),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn("image layers", result.stderr + result.stdout)

    def test_chapter_audit_rejects_stale_map_art_manifest_and_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            copy_paths = [
                "Tools/MapArtPipeline/map_art_specs.json",
                "RiftExpedition/Resources/Maps/chapter1",
                "RiftExpedition/Resources/Assets/MapArt/chapter1",
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in copy_paths:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                if source.is_dir():
                    shutil.copytree(source, destination)
                else:
                    shutil.copy2(source, destination)

            stale_relative = Path("RiftExpedition/Resources/Assets/MapArt/chapter1/stale.png")
            stale_path = project / stale_relative
            Image.new("RGB", (4, 4), (0, 0, 0)).save(stale_path)
            manifest_path = project / "RiftExpedition/Resources/Assets/assets-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest.append({
                "id": "mapart.chapter1_stale",
                "path": "Assets/MapArt/chapter1/stale.png",
                "type": "map-art",
                "source": "stale test fixture",
                "license": "self-made",
                "downloadedAt": "2026-07-13",
                "author": "test",
            })
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(self.project_root / "Tools/MapArtPipeline/audit_chapter1.py"),
                    "--project-root",
                    str(project),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            combined = result.stdout + result.stderr
            self.assertNotEqual(result.returncode, 0, combined)
            self.assertIn("map-art manifest ids", combined)
            self.assertIn("runtime map-art files", combined)


    def test_contract_rejects_retired_tile_art_path(self) -> None:
        area = next(area for area in self.areas if area["id"] == "village_square")
        spec = self.specs[area["id"]]
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            relatives = [
                spec["tmx"],
                spec["source"],
                spec["foregroundSource"],
                spec["output"],
                spec["foregroundOutput"],
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in relatives:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)

            map_path = project / spec["tmx"]
            tree = ET.parse(map_path)
            root = tree.getroot()
            properties = root.find("properties")
            assert properties is not None
            ET.SubElement(properties, "property", {"name": "assetId", "value": "tileset.legacy"})
            root.insert(1, ET.Element("tileset", {"firstgid": "1", "name": "legacy"}))
            root.append(ET.Element("layer", {"id": "99", "name": "terrain", "width": "32", "height": "20"}))
            tree.write(map_path, encoding="utf-8", xml_declaration=True)

            errors = pipeline.validate_contracts(project, {area["id"]: spec}, [area])
            self.assertTrue(any("legacy tileset" in error for error in errors), errors)
            self.assertTrue(any("legacy tile layers" in error for error in errors), errors)
            self.assertTrue(any("legacy assetId" in error for error in errors), errors)

    def test_contract_rejects_tmx_and_manifest_drift(self) -> None:
        area = next(area for area in self.areas if area["id"] == "village_square")
        spec = self.specs[area["id"]]
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            relatives = [
                spec["tmx"],
                spec["source"],
                spec["foregroundSource"],
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in relatives:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)

            pipeline.build(project, area["id"], spec)
            map_path = project / spec["tmx"]
            tree = ET.parse(map_path)
            root = tree.getroot()
            background = next(layer for layer in root.findall("imagelayer") if layer.get("name") == spec["layerName"])
            background.find("image").set("source", "../Art/wrong.png")
            tree.write(map_path, encoding="utf-8", xml_declaration=True)

            manifest_path = project / "RiftExpedition/Resources/Assets/assets-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            entry = next(entry for entry in manifest if entry.get("id") == spec["assetID"] )
            entry["type"] = "illustration"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            errors = pipeline.validate_contracts(project, {area["id"]: spec}, [area])
            self.assertTrue(any("source" in error and "wrong.png" in error for error in errors), errors)
            self.assertTrue(any("manifest entry does not exactly match" in error for error in errors), errors)

    def test_cli_rebuilds_missing_ready_outputs_before_runtime_validation(self) -> None:
        area_id = "village_square"
        spec = self.specs[area_id]
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            copy_paths = [
                "Tools/MapArtPipeline/map_art_specs.json",
                "Tools/MapArtPipeline/Sources",
                "RiftExpedition/Resources/Data/worlds/chapter1.json",
                "RiftExpedition/Resources/Maps/chapter1",
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]
            for relative in copy_paths:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                if source.is_dir():
                    shutil.copytree(source, destination)
                else:
                    shutil.copy2(source, destination)

            map_path = project / spec["tmx"]
            tree = ET.parse(map_path)
            root = tree.getroot()
            for layer_name in (spec["layerName"], spec["foregroundLayerName"]):
                for layer in list(root.findall("imagelayer")):
                    if layer.get("name") == layer_name:
                        root.remove(layer)
            properties = root.find("properties")
            assert properties is not None
            for name in ("artAssetId", "foregroundArtAssetId", "artPipelineVersion"):
                for prop in list(properties.findall("property")):
                    if prop.get("name") == name:
                        properties.remove(prop)
            tree.write(map_path, encoding="utf-8", xml_declaration=True)

            manifest_path = project / "RiftExpedition/Resources/Assets/assets-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            removed_ids = {spec["assetID"], spec["foregroundAssetID"]}
            manifest_path.write_text(
                json.dumps([entry for entry in manifest if entry.get("id") not in removed_ids], ensure_ascii=False),
                encoding="utf-8",
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    "--project-root",
                    str(project),
                    "--area",
                    area_id,
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((project / spec["output"]).is_file())
            self.assertTrue((project / spec["foregroundOutput"]).is_file())
            self.assertEqual(
                pipeline.validate_contracts(
                    project,
                    self.specs,
                    self.areas,
                    runtime_area_ids={area_id},
                ),
                [],
            )

    def test_pending_source_cannot_be_built_as_runtime_art(self) -> None:
        spec = dict(self.specs["cave_entrance"])
        spec["status"] = "pending-source"
        with self.assertRaisesRegex(ValueError, "not approved yet"):
            pipeline.build(self.project_root, "cave_entrance", spec)


    def test_cli_rebuilds_missing_ready_outputs_before_full_contract_validation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            for relative in [
                "Tools/MapArtPipeline/map_art_specs.json",
                "RiftExpedition/Resources/Data/worlds/chapter1.json",
                "RiftExpedition/Resources/Assets/assets-manifest.json",
            ]:
                source = self.project_root / relative
                destination = project / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
            shutil.copytree(
                self.project_root / "Tools/MapArtPipeline/Sources",
                project / "Tools/MapArtPipeline/Sources",
            )
            shutil.copytree(
                self.project_root / "RiftExpedition/Resources/Maps/chapter1",
                project / "RiftExpedition/Resources/Maps/chapter1",
            )
            shutil.copytree(
                self.project_root / "RiftExpedition/Resources/Assets/MapArt/chapter1",
                project / "RiftExpedition/Resources/Assets/MapArt/chapter1",
            )

            spec = self.specs["village_square"]
            (project / spec["output"]).unlink()
            (project / spec["foregroundOutput"]).unlink()

            result = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    "--project-root",
                    str(project),
                    "--area",
                    "village_square",
                ],
                capture_output=True,
                text=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((project / spec["output"]).is_file())
            self.assertTrue((project / spec["foregroundOutput"]).is_file())
            specs = pipeline.load_specs(project)
            areas = pipeline.load_world_areas(project)
            self.assertEqual(pipeline.validate_contracts(project, specs, areas), [])

    def test_contract_export_contains_every_area(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            pipeline.write_layout_guides(
                self.project_root,
                self.specs,
                self.areas,
                list(self.specs),
                output,
            )
            payload = json.loads((output / "chapter1_layout_contracts.json").read_text(encoding="utf-8"))
            self.assertEqual(payload["pipelineVersion"], pipeline.PIPELINE_VERSION)
            self.assertEqual({area["areaID"] for area in payload["areas"]}, set(self.specs))


if __name__ == "__main__":
    unittest.main()
