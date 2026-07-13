# Rift Expedition（裂隙远征）

macOS 原生中文 2D 箱庭 CRPG。首章目标是做出「村庄 + 野外 + 洞穴」的完整可玩章节，而不是只停在竖切 demo：2 人小队、自由距离回合制战斗、整数 AP。

## 技术栈

- Swift 6.0，SwiftUI（菜单/HUD/面板）+ SpriteKit（2D 场景渲染）+ GameplayKit（寻路/随机源）
- 地图空间数据使用标准 Tiled TMX（`.tmx`），运行时由本地 vendored 的 SKTiled 读取；TMX 由项目脚本自动生成和维护，不要求手动使用 Tiled GUI
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
| `Tools/RiftValidator` | 独立命令行工具：校验地图、image layer、内容引用与资源完整性，生成地图预览 |
| `Tools/MapArtPipeline` | 无需打开 Tiled：自动裁切地图原画、写入 TMX 图层、更新碰撞与生成覆盖预览 |
| `AGENTS.md` | 面向开发者/AI 的强约束规则手册，改代码前先看 |
| `Docs/` | 项目知识库，入口见 [`Docs/overview.md`](Docs/overview.md) |

## 怎么编译 / 测试

```sh
# App 主 target + App 层单元测试
rtk xcodebuild test -scheme RiftExpedition -destination 'platform=macOS'

# RiftCore 纯逻辑包的单元测试（不需要打开 Xcode）
rtk swift test --package-path Packages/RiftCore

# 地图/资源校验工具自身的单元测试
rtk swift test --package-path Tools/RiftValidator
```

## UI 截图验收（Debug）

在 Xcode Scheme 的 Run Arguments 加 -uiState <状态>，可直接进入带示例队伍与内容的界面，用于窗口截图和布局核对。支持 party、exploration、inventory、skills、quests、save；不传参数仍从主菜单启动。该入口仅存在于 Debug 构建，不读取或修改玩家存档。

## 自动地图构建、校验与预览

用户不需要手动打开 Tiled。先由脚本生成正式地图背景并更新 TMX：

```sh
python3 Tools/MapArtPipeline/build_map_art.py --area village_square
```

随后用 validator 校验对象层、出口/出生点、image layer、内容引用和资源登记：

```sh
rtk swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources \
  --chapter chapter1 \
  --write-preview Docs/Reports/map-previews/chapter1 \
  --write-report Docs/Reports/map-previews/chapter1/report.md
```

预览图与报告是生成产物，已在 `.gitignore` 忽略、不入库；需要时现生成即可。地图对象层的具体约定见 [`Docs/tiled-map-contract.md`](Docs/tiled-map-contract.md)。

## 关键文档

- [`AGENTS.md`](AGENTS.md)：开发规则手册（技术栈边界、数据驱动约定、MVVM 规范、资源规范等），改代码前务必先看。
- [`Docs/overview.md`](Docs/overview.md)：知识库入口，按主题导航到架构、依赖、资源、数值基线、世界图谱、术语表等文档。

## 本轮地图自动化升级

详见 [`Docs/map-art-automation-upgrade-20260712.md`](Docs/map-art-automation-upgrade-20260712.md)。
