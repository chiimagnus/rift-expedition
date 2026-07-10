# 架构总览

## 分层

- **`Packages/RiftCore`**：纯 Swift 游戏规则引擎。不依赖 SwiftUI / SpriteKit / SKTiled / OSLog（见 [`dependencies.md`](dependencies.md)），可独立 `swift test`。
  - `Model/`：`Actor`、`ClassDefinition`、`Equipment`、`Faction`、`QuestDefinition`、`SkillDefinition`、`Stats` 等纯数据结构。
  - `Battle/`：回合制战斗规则 —— AP 规则、战斗状态机、技能效果与结算、目标选择、行动顺序。
  - `AI/`：敌人 AI 倾向（近战贴近 / 弓手拉距离 / 法师偏元素 / 刺客绕后）。
  - `Element/`：元素地表与状态解析（火 / 水 / 油 / 毒等）。
  - `Progression/`：属性点成长、经验曲线。
  - `Inventory/`：装备规则、队伍共享背包。
  - `Quest/`：任务引擎。
  - `Save/`：版本化存档（`schemaVersion`）与存档槽策略（5 手动 + 5 自动，只在安全点写入）。
  - `Config/`：JSON 内容加载与启动期校验（`ContentLoader` / `ContentValidator` / `ContentCatalog`）。
  - `Foundation/`：可注入的随机源（`RandomSource` / `SeededRandomSource`），保证战斗逻辑可复现测试。

- **`RiftExpedition`**（macOS App，MVVM + SpriteKit）
  - `App/`：应用入口、根视图、全局 `AppState`。
  - `Game/`：SpriteKit 场景（`GameScene`）、Tiled 地图加载（`TiledMapLoader`）、探索 / 寻路 / 视线 / 遭遇触发服务。
  - `ViewModels/`：战斗、对话、背包、角色创建、存档读写等界面状态与流程编排，依赖 `RiftCore` 与 `Game` 层服务。
  - `Views/`：SwiftUI 界面（HUD、对话框、背包、角色卡、设置等）。
  - `Audio/`、`Save/`、`Support/`：音效播放、本地存档读写、日志等基础设施。
  - `Resources/`：地图（`Maps/*.tmx`）、内容配置（`Data/*.json`）、美术音频（`Assets/`，见 [`assets.md`](assets.md)）。

- **`Tools/RiftValidator`**：独立 SwiftPM 命令行工具，不参与 App 运行时；离线校验地图对象层完整性、资源引用、世界图谱连通性，并可生成地图预览 SVG 与 Markdown 报告（见 [`tiled-map-contract.md`](tiled-map-contract.md)）。

## 依赖方向

```
SwiftUI Views -> ViewModels -> Game 层服务（GameScene / TiledMapLoader / Navigation / Encounter）-> RiftCore
                                                              -> Resources（JSON / TMX / Assets）
```

`RiftCore` 不反向依赖 App 层或任何 UI 框架，保证战斗 / 规则逻辑可以脱离 App 独立跑单元测试。

## 数据流：从地图到画面

1. `.tmx`（Tiled 编辑源）→ `TiledMapLoader` 解析对象层（`spawn` / `npc` / `encounter` / `trigger` / `exit` / `navObstacle` / `surface` / `item`，见 [`tiled-map-contract.md`](tiled-map-contract.md)）。
2. `GameScene` 渲染 tileset、放置 NPC / 敌人 / 道具立绘（贴图来自 `Assets/Characters`，分帧约定见 [`assets.md`](assets.md)），并把可行走区域 / 视线交给 `NavigationService` / `LineOfSightService`。
3. 玩家进入 `encounter` 触发范围 → `EncounterTriggerService` 触发战斗 → `BattleViewModel` 驱动 `RiftCore.BattleEngine` 完成回合结算 → 结果写回存档（`SaveGameStore` → `RiftCore.SaveGame`）。

## 共享会话、存档与 Debug 截图

GameSessionViewModel 持有唯一的 GameSessionState：队伍、共享背包、任务状态、已拾取物和一次性地图触发器只在此处可写。InventoryViewModel 与 DialogViewModel 引用同一个状态，避免面板关闭后才回写的副本不同步问题。

手动保存与安全自动保存将会话状态写入 JSON。SaveGame schema 2 额外保存任务状态、已拾取物与一次性触发器；读取 schema 1 时，缺失字段回退为空状态，保持旧存档可读。

ContentView 仅在 #if DEBUG 中读取 -uiState 启动参数。GameSessionViewModel 会为 party、exploration、inventory、skills、quests、save 准备确定的示例状态，供窗口截图和布局回归检查；Release 不包含此入口。最小回归测试在 RiftExpeditionTests/GameSessionViewModelTests.swift。

## 测试分布

| 测试目标 | 位置 | 运行方式 |
| --- | --- | --- |
| 纯规则逻辑（战斗 / 元素 / AI / 存档 / 任务 / 成长） | `Packages/RiftCore/Tests` | `rtk swift test --package-path Packages/RiftCore` |
| App 层（ViewModel / 场景 / 服务） | `RiftExpeditionTests` | `rtk xcodebuild test -scheme RiftExpedition -destination 'platform=macOS'` |
| 地图 / 资源校验工具 | `Tools/RiftValidator/Tests` | `rtk swift test --package-path Tools/RiftValidator` |
