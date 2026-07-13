# TMX 地图契约与自动化美术管线

`.tmx` 仍是运行时空间数据的唯一事实来源，但项目**不要求开发者手动使用 Tiled GUI**。地图由 `Tools/MapArtPipeline` 直接读写标准 TMX XML；SKTiled 继续负责运行时加载与渲染。

## 自动构建

```sh
python3 Tools/MapArtPipeline/build_map_art.py --area village_square
```

脚本会自动完成：

1. 把俯视原画裁切、缩放到地图精确像素尺寸；
2. 写入或更新 `background_art` image layer；
3. 更新出生点、NPC、出口、触发区与碰撞矩形；
4. 登记 `assets-manifest.json`；
5. 输出带碰撞覆盖的预览图和 Markdown 报告。

地图配置位于 `Tools/MapArtPipeline/map_art_specs.json`。以后增加地图时由 AI 修改配置并运行脚本，不需要用户打开 Tiled。

## 图层约定

- `background_art`：整张俯视背景，必须与地图像素尺寸一致，坐标必须是 `0,0`。
- `foreground_*`：透明前景遮挡图，可用于屋檐、树冠、洞顶；运行时自动放在角色上方。
- 首章正式地图不允许保留 `terrain`、旧 tileset 或其他回退渲染层；空间定位只以 TMX 对象层和正式图片层为准。

## 必需对象层

- `spawn`：需要 `id`
- `npc`：需要 `actorId`、`dialogId`；必须有非零宽高碰撞箱
- `encounter`：需要 `encounterId`、`radius`
- `trigger`：需要 `triggerId`、`action`
- `exit`：需要 `targetAreaId`、`targetSpawnId`
- `navObstacle`：需要 `blocksMovement`、`blocksSight`
- `surface`：需要 `surfaceType`
- `item`：需要 `itemId`

## 校验规则

- 所有必需对象层必须存在，即使为空。
- Tiled 数字对象 id 在每张地图内必须唯一。
- 必需属性必须存在，属性名大小写严格固定。
- `exit.targetSpawnId` 必须引用目标地图中存在的 `spawn.id`。
- 出生点不得位于移动障碍内。
- `background_art` 和 `foreground_*` 必须存在、可读取，并与地图尺寸完全一致。
- 资源必须登记在 `Assets/assets-manifest.json`。

## 校验命令

```sh
swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources \
  --chapter chapter1 \
  --write-preview Docs/Reports/map-previews/chapter1 \
  --write-report Docs/Reports/map-previews/chapter1/report.md
```

生成的 SVG、碰撞覆盖 PNG 与 Markdown 报告都是评审产物，不是手写源。
