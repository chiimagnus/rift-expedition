# 文档同步记录

| 字段 | 值 |
| --- | --- |
| Commit hash | 6f76c509054d0f933765760bbcce4b4a4cd448e9 |
| Generated at | 2026-07-06 |
| 页面清单 | overview.md, architecture.md, dependencies.md, assets.md, balance-starting-values.md, chapter1-worldgraph.md, tiled-map-contract.md, glossary.md |

## Coverage Gaps（已知未覆盖内容）

- `Tools/RiftValidator` 内部各校验规则的详细实现未单独成文档，需要时直接读 `Tools/RiftValidator/Sources/RiftValidator/*.swift`。
- `RiftExpedition/Views/*` 各界面的交互细节未单独成文档；界面结构见 `architecture.md`，具体交互以代码为准。
- 存档 `SaveGame` / `SaveSlotPolicy` 的字段级 schema 未单独成文档，需要时读 `Packages/RiftCore/Sources/RiftCore/Save/*.swift`。

下次同步文档时，请先对比本文件记录的 Commit hash 与当前代码差异，只更新受影响的文档页面。
