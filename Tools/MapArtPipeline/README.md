# MapArtPipeline

无需打开 Tiled。TMX 始终是空间布局的唯一事实来源，脚本负责生成精确底稿、接入正式原画、更新碰撞与资源登记。

## 当前状态

`map_art_specs.json` 已覆盖第一章全部 9 个区域：

- `ready`：已有获批俯视原画，可以构建运行时地图；
- `pending-source`：空间契约已建立，但不能误把占位图打包为正式地图。

## 校验全部布局契约

```sh
python3 Tools/MapArtPipeline/build_map_art.py --validate-contracts
```

校验内容包括：世界图谱区域覆盖、TMX 路径、画布尺寸、唯一 asset ID、输出路径以及 ready 原画是否存在。

## 输出无需 Tiled 的构图底稿

```sh
python3 Tools/MapArtPipeline/build_map_art.py \
  --write-guides Docs/Reports/map-art/layout-guides/chapter1
```

每张底稿严格使用 TMX 的像素尺寸和左上角坐标，包含：

- 32 像素网格；
- 出生点、NPC、出口、触发器、遭遇、任务物品和地表；
- 红色不可行走区域；
- 对应 Markdown 美术硬约束；
- 汇总的 `chapter1_layout_contracts.json`。

这些底稿用于制作或生成正式的纯 2D 俯视背景，不会进入游戏资源包。

## 构建已获批地图

```sh
python3 Tools/MapArtPipeline/build_map_art.py --area village_square
```

不带 `--area` 时只构建 `ready` 地图。显式构建 `pending-source` 地图会直接失败，防止缺失或错误视角的图片进入正式资源。

构建正式地图时会自动：

1. 将获批俯视原画裁切并缩放到 TMX 的精确像素尺寸；
2. 写入或更新 TMX `background_art` image layer；
3. 更新配置中的出生点、NPC、出口、触发器和碰撞矩形；
4. 登记 `assets-manifest.json`；
5. 输出碰撞覆盖预览与构建报告。

## 自检

```sh
python3 -m unittest Tools/MapArtPipeline/test_map_art_pipeline.py
```

## 正式源图

`Tools/MapArtPipeline/Sources/` 中已获批的背景和透明前景 PNG 是地图美术构建的唯一源图。
构建脚本只负责按 TMX 尺寸生成运行时资源、规范化 image layer、更新对象与资源登记；
不再从已退役的瓦片层重建另一套视觉结果。替换源图时仍必须保持对应 TMX 的俯视几何和交互位置。
