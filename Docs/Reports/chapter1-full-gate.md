# 第一章全量 Gate 报告

- 执行日期：2026-07-13
- 执行环境：Linux / Swift 6.2.1
- 范围：P1–P4 自动化 Gate
- 结论：Linux Gate 全部通过；macOS/Xcode 实机 Gate 待在开发机完成

## 自动化结果

| Gate | 结果 | 证据摘要 |
| --- | --- | --- |
| `todo.toml` 结构校验 | PASS | `todo.toml OK` |
| RiftCore 单元测试 | PASS | 51 tests, 0 failures |
| RiftValidator XCTest | PASS | 21 tests, 0 failures |
| RiftValidator Swift Testing | PASS | 7 tests, 0 failures |
| MapArtPipeline 单元测试 | PASS | 8 tests, 0 failures |
| 地图美术契约 | PASS | 9 areas, 9 ready, 0 pending-source |
| 首章地图美术审计 | PASS | 9/9 地图通过 |
| RiftValidator `--chapter chapter1` | PASS | 0 issues |
| JSON 解析 | PASS | 10 files |
| TMX 解析 | PASS | 9 files |
| Swift 语法扫描 | PASS | 139 files |
| Git whitespace 检查 | PASS | 无问题 |
| 计划相关旧路径扫描 | PASS | 无 `vertical_slice`、`dialogues.json`、旧音频包装或旧遭遇包装 |

## 已验证的严格边界

- 当前存档 schema 不接受旧字段缺失、空队伍、空角色 ID 或重复角色 ID。
- 已解决遭遇按 `areaID + tiledID` 持久化；缺失遭遇定义不会消耗合法触发器。
- 九区域地图美术、TMX image layer、前景遮挡和 manifest 一一对应。
- 战斗状态、状态持续时间、死亡跳过、敌方行动上下文和移动阻挡均有自动测试。
- 对话只保留 `dialogs.json` 单一真源；内容加载错误会暴露给启动流程。
- 首章验证范围由显式 `--chapter chapter1` 和世界图谱决定，不再依赖路径推断。

## macOS 必做 Gate

当前环境没有 `xcodebuild`，以下项目不能由 Linux 替代：

1. Debug 与 Release 完整编译。
2. SwiftUI 布局和窗口缩放截图验收。
3. SpriteKit/SKTiled 地图实际渲染、前景遮挡和坐标对位。
4. AVFoundation 循环、交叉淡化和音量滑杆实机试听。
5. 从新游戏到第一章结算的完整通关与存档恢复。

详见 `Docs/Reports/chapter1-playtest-checklist.md`。
