# 文档索引

根目录只放长期维护文档；发布 / 文案清单放在 `Reports/`。地图校验报告与预览 SVG 是 validator 生成产物，已在 `.gitignore` 忽略、不入库，需要时用 validator 现生成（见 `tiled-map-contract.md`）。

## 长期文档

- `assets.md`：美术与音频资源的授权契约、当前来源登记、替换规则（合并原 asset-policy / asset-sources / art-resource-guide）。
- `balance-starting-values.md`：首版数值基线。
- `chapter1-worldgraph.md`：首章区域连接设计。
- `dependencies.md`：依赖说明。
- `tiled-map-contract.md`：TMX 图层、对象和校验约定。

## 报告与清单

- `Reports/release-checklist.md`：本地 macOS 构建与分发检查。
- `Reports/ui-copy-checklist.md`：中文 UI 文案检查。

## 生成产物（不入库）

- `Reports/chapter1-validation-report.md`、`Reports/map-previews/`：由 validator 生成，已 gitignore；需要时用 `rtk swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources ...` 现生成。
