# Tiled 地图契约

`.tmx` 是标准地图源。生成的摘要、SVG 预览、Markdown 报告都是评审产物，不是手写源。

## 必需对象层

- `spawn`：需要 `id`
- `npc`：需要 `actorId`、`dialogId`；可选把对象画成有宽高的矩形来控制碰撞箱大小（不画宽高就是点对象，运行时回退为默认 36x36）
- `encounter`：需要 `encounterId`、`radius`
- `trigger`：需要 `triggerId`、`action`
- `exit`：需要 `targetAreaId`、`targetSpawnId`
- `navObstacle`：需要 `blocksMovement`、`blocksSight`
- `surface`：需要 `surfaceType`
- `item`：需要 `itemId`

## 校验规则

- 所有必需层都必须存在，即使为空。
- Tiled 数字对象 id 在每张地图内必须唯一。
- 必需属性必须存在。
- `exit.targetSpawnId` 必须引用被校验地图中存在的 `spawn.id`。
- `spawn` 点不得位于 `blocksMovement = true` 的 `navObstacle` 对象内。

## CLI

```sh
rtk swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources --area village_square --write-preview Docs/Reports/map-previews/chapter1/village_square --write-report Docs/Reports/map-previews/chapter1/village_square/report.md
```

`--write-preview` 写入 SVG 预览。`--write-report` 写入 Markdown 报告。
