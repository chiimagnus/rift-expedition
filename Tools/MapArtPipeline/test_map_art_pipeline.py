import importlib.util
import json
import shutil
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

    def test_specs_cover_world_graph_and_validate(self) -> None:
        self.assertEqual(set(self.specs), {area["id"] for area in self.areas})
        self.assertEqual(pipeline.validate_contracts(self.project_root, self.specs, self.areas), [])
        self.assertEqual(sum(spec["status"] == "ready" for spec in self.specs.values()), 9)
        self.assertEqual(sum(spec["status"] == "pending-source" for spec in self.specs.values()), 0)

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
            for relative in [spec["tmx"], spec["source"], "RiftExpedition/Resources/Assets/assets-manifest.json"]:
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

    def test_pending_source_cannot_be_built_as_runtime_art(self) -> None:
        spec = dict(self.specs["cave_entrance"])
        spec["status"] = "pending-source"
        with self.assertRaisesRegex(ValueError, "not approved yet"):
            pipeline.build(self.project_root, "cave_entrance", spec)

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
