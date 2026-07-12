# MapArtPipeline

无需打开 Tiled。脚本根据 `map_art_specs.json` 自动完成：

1. 将俯视原画裁切并缩放到 TMX 的精确像素尺寸；
2. 写入或更新 TMX `background_art` image layer；
3. 更新出生点、NPC、出口、触发器和碰撞矩形；
4. 登记 `assets-manifest.json`；
5. 输出碰撞覆盖预览与构建报告。

```sh
python3 Tools/MapArtPipeline/build_map_art.py --area village_square
```

正式地图的空间规则仍存于 TMX，但 TMX 由脚本维护，开发者不需要学习或手动操作 Tiled GUI。
