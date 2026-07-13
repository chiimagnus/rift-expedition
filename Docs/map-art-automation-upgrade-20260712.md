# 纯 2D 俯视地图自动化升级记录

日期：2026-07-12

## 本轮目标

- 修复 `BattleHUDView.swift` 的 SwiftUI 类型检查超时。
- 保留 TMX / SKTiled 作为运行时地图格式，但不要求开发者手动使用 Tiled。
- 把俯视环境画真正接入可玩地图，而不是只作为菜单插图。
- 修复此前新增任务、对话、遭遇和音频改造中的数据兼容问题。

## 已完成

### 1. 编译问题

`BattleHUDView` 中技能按钮的复杂内联表达式已拆为：

- `skillActionButton(_:)`
- `skillSubtitle(for:)`

这减少了 SwiftUI 泛型推断规模，针对 Xcode 报告的 `unable to type-check this expression in reasonable time`。

隔离类型检查还发现并修复了 `BattleViewModel` 战斗特效样式 `switch` 漏掉 `.move` 分支的问题。

### 2. 无需手动 Tiled 的地图管线

新增 `Tools/MapArtPipeline`。脚本会自动：

1. 将源环境画裁切、缩放到 TMX 的精确像素尺寸。
2. 在 TMX 中创建或更新 `background_art` 图片层。
3. 调整出生点、NPC、触发器、出口和碰撞矩形。
4. 更新 `assets-manifest.json`。
5. 输出碰撞覆盖预览与 Markdown 报告。
6. 保持重复执行结果一致。

命令示例：

```bash
python3 Tools/MapArtPipeline/build_map_art.py --area village_square
```

用户不需要安装或学习 Tiled GUI。

### 3. 首批实装地图

- `village_square`：俯视村庄广场正式背景、重新对齐交互点和建筑碰撞。
- `cave_depths`：俯视裂隙洞心正式背景、保留并验证遭遇、触发器、毒雾和出口布局。

`GameScene` 已识别：

- `background_art`：位于角色下方。
- `foreground_*`：预留为透明屋顶、树冠、洞顶遮挡层，位于角色上方。

启用正式地图画后，旧的通用木堆障碍占位图不会覆盖环境原画。

### 4. Validator

`RiftValidator` 新增：

- 图片层资源路径检查。
- 图片尺寸与地图像素尺寸一致性检查。
- 图片层位置与可见性检查。
- 出生点到其他出生点和出口的栅格可达性检查。
- Linux 下直接读取 PNG 头部尺寸，不依赖 AppKit。

首章 9 张地图当前问题数量为 0。

### 5. 内容与音频修复

- 新增支线任务改回现有 `QuestDefinition` 数据格式。
- 新增对话改回现有 `DialogScript` 格式。
- 新增遭遇改回 `EncounterDefinition` 的完整 Actor 格式。
- TMX 中 `encounterId`、`itemId` 大小写已统一。
- 音频服务恢复 `AVAudioPlayer` 协议签名与 Observation 状态更新，同时增加区域音乐层、环境层和战斗音乐层。

## 验证结果

- `RiftCore`：39 项测试通过。
- `RiftValidator`：14 项测试通过。
- 首章地图校验：9 张地图，0 个问题。
- Swift 语法扫描：99 个文件通过。
- 所有资源 JSON 和 TMX XML 均可解析。
- MapArtPipeline 重复执行散列一致。

## 仍需在 macOS/Xcode 验收

当前环境为 Linux，不能执行完整的 SwiftUI、SpriteKit、AVFoundation 和 SKTiled macOS 应用构建。因此仍需在 Xcode 中确认：

- `BattleHUDView` 在真实 SwiftUI 编译器中的类型检查结果。
- SKTiled 图片层的运行时 Y 轴、缩放和 zPosition 显示。
- 角色脚底与地图道路、门口和碰撞边缘的视觉对位。
- 分层音频在真实设备上的音量与循环衔接。

这些项目已通过可在 Linux 完成的语法、数据、规则和验证器检查，但不应把它们描述为已经完成 macOS 实机渲染验收。
