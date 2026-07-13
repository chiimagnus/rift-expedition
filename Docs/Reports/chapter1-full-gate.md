# 第一章全量 Gate 报告

- 执行日期：2026-07-13
- 执行环境：Linux / Swift 6.2.1
- 范围：P1–P4 全阶段实现、审计修复与旧兼容路径清理
- 结论：Linux 自动化 Gate 全部通过；macOS/Xcode 实机 Gate 待在开发机完成

## 自动化结果

| Gate | 结果 | 证据摘要 |
| --- | --- | --- |
| `todo.toml` 结构校验 | PASS | `todo.toml OK`，P1–P4 均为 phase complete |
| RiftCore 单元测试 | PASS | 86 tests, 0 failures |
| RiftValidator XCTest | PASS | 28 tests, 0 failures |
| RiftValidator Swift Testing | PASS | 9 tests, 0 failures |
| MapArtPipeline 单元测试 | PASS | 16 tests, 0 failures |
| 地图美术契约 | PASS | 9 areas, 9 ready, 0 pending-source |
| 首章地图美术审计 | PASS | 9/9 地图通过 |
| RiftValidator `--chapter chapter1` | PASS | 9 maps, 0 issues |
| 仓库 JSON 解析 | PASS | 29 files |
| 仓库 TMX 解析 | PASS | 14 files |
| Swift 语法扫描 | PASS | 157 files |
| Git whitespace 检查 | PASS | 无问题 |
| 计划相关旧路径扫描 | PASS | 无旧地图入口、双对话数据源、旧类型别名、旧遭遇加载器、旧主题别名或旧地图自动迁移函数 |

## 已验证的严格边界

- 当前存档 schema 必须恰好包含两名角色；旧 schema、字段缺失、空或重复角色 ID、非法状态与资源边界均被拒绝。
- 已解决遭遇按 `areaID + tiledID` 持久化；失败或缺失定义不会消耗触发器，胜利后读档不会重复触发。
- 地图剧情触发器只在动作成功后消费；缺失对话和未知动作保持可重试。
- 九区域地图美术、TMX image layer、前景遮挡和 manifest 一一对应。
- 地图构建器拒绝旧 tileset、tile layer、`assetId`、未知 image layer 和重复正式图层，不再静默迁移旧地图。
- 战斗状态、状态持续时间、死亡跳过、敌方行动上下文、移动阻挡和表现事件消费均有自动测试。
- 对话只保留 `dialogs.json` 单一真源；规范类型直接来自 RiftCore。
- 遭遇由统一 `ContentCatalog` 加载；敌人职业、技能、装备、状态和对话开战引用在启动前校验。
- 任务数据使用严格非可选契约；顶层内容实体、奖励、目标和装备语义均被校验。
- 指定章节只解码精确世界图谱并校验内部 ID；区域预览仍会因同章节兄弟地图错误而失败，不会产生假绿。

## macOS 必做 Gate

当前环境没有 `xcodebuild`，以下项目不能由 Linux 替代：

1. Debug 与 Release 完整编译。
2. SwiftUI 布局和窗口缩放截图验收。
3. SpriteKit/SKTiled 地图实际渲染、前景遮挡和坐标对位。
4. AVFoundation 循环、交叉淡化和音量滑杆实机试听。
5. 从新游戏到第一章结算的完整通关与存档恢复。

详见 `Docs/Reports/chapter1-playtest-checklist.md`。
