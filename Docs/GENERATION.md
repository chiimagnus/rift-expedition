# 文档同步记录

| 字段 | 值 |
| --- | --- |
| Commit hash | 0dcd1ca |
| Generated at | 2026-07-10 |
| 页面清单 | overview.md, architecture.md, dependencies.md, assets.md, balance-starting-values.md, chapter1-worldgraph.md, tiled-map-contract.md, glossary.md |

## Coverage Gaps（已知未覆盖内容）

- `Tools/RiftValidator` 内部各校验规则的详细实现未单独成文档，需要时直接读 `Tools/RiftValidator/Sources/RiftValidator/*.swift`。
- `RiftExpedition/Views/*` 各界面的视觉细节未单独成文档；界面状态、会话边界与截图入口见 `architecture.md`，具体布局以代码和 Debug 截图为准。

下次同步文档时，请先对比本文件记录的 Commit hash 与当前代码差异，只更新受影响的文档页面。
