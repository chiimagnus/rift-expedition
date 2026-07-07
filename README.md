# Rift Expedition（裂隙远征）

macOS 原生中文 2D 箱庭 CRPG。首章目标是做出「村庄 + 野外 + 洞穴」的完整可玩章节，而不是只停在竖切 demo：2 人小队、自由距离回合制战斗、整数 AP。

## 技术栈

- Swift 6.0，SwiftUI（菜单/HUD/面板）+ SpriteKit（2D 场景渲染）+ GameplayKit（寻路/随机源）
- 地图编辑源是 Tiled（`.tmx`），运行时由本地 vendored 的 [SKTiled](https://github.com/mfessenden/SKTiled) 读取渲染
- 架构是 MVVM；核心玩法规则（战斗/技能/元素/AI/存档/任务/成长）下沉到独立 Swift 包 `Packages/RiftCore`，不依赖任何 UI 框架，可单独测试

完整依赖边界见 [`Docs/dependencies.md`](Docs/dependencies.md)；架构细节与数据流见 [`Docs/architecture.md`](Docs/architecture.md)。

## 目录结构

| 路径 | 内容 |
| --- | --- |
| `Packages/RiftCore` | 纯 Swift 游戏规则引擎，不依赖 SwiftUI/SpriteKit |
| `RiftExpedition/App` | App 入口、根视图、全局状态 |
| `RiftExpedition/Game` | SpriteKit 场景、Tiled 地图加载、探索/寻路/视线/遭遇触发 |
| `RiftExpedition/ViewModels` `RiftExpedition/Views` | 各界面（战斗、对话、背包、存档等）及其 ViewModel |
| `RiftExpedition/Resources` | 地图 `Maps/`、内容配置 `Data/*.json`、美术音频 `Assets/` |
| `RiftExpeditionTests` | App 层单元测试 |
| `Tools/RiftValidator` | 独立命令行工具：校验地图/资源引用完整性，生成地图预览 |
| `AGENTS.md` | 面向开发者/AI 的强约束规则手册，改代码前先看 |
| `Docs/` | 项目知识库，入口见 [`Docs/overview.md`](Docs/overview.md) |

## 怎么打开项目

直接用 Xcode 打开 `RiftExpedition.xcodeproj`。

## 怎么编译 / 测试

```sh
# App 主 target + App 层单元测试
rtk xcodebuild test -scheme RiftExpedition -destination 'platform=macOS'

# RiftCore 纯逻辑包的单元测试（不需要打开 Xcode）
rtk swift test --package-path Packages/RiftCore

# 地图/资源校验工具自身的单元测试
rtk swift test --package-path Tools/RiftValidator
```

## 地图校验与预览

每次生成或大改地图后，用 validator 校验区域连通性、出口/出生点合法性，并生成预览图：

```sh
rtk swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources \
  --area village_square \
  --write-preview Docs/Reports/map-previews/chapter1/village_square \
  --write-report Docs/Reports/map-previews/chapter1/village_square/report.md
```

预览图与报告是生成产物，已在 `.gitignore` 忽略、不入库；需要时现生成即可。地图对象层的具体约定见 [`Docs/tiled-map-contract.md`](Docs/tiled-map-contract.md)。

## 关键文档

- [`AGENTS.md`](AGENTS.md)：开发规则手册（技术栈边界、数据驱动约定、MVVM 规范、资源规范等），改代码前务必先看。
- [`Docs/overview.md`](Docs/overview.md)：知识库入口，按主题导航到架构、依赖、资源、数值基线、世界图谱、术语表等文档。
