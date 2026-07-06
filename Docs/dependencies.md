# 依赖清单

## 允许的运行时依赖

- Apple 官方框架：SwiftUI、SpriteKit、GameplayKit、Foundation、CoreGraphics、AVFoundation、OSLog。
- SwiftPM 第三方包：SKTiled，锁定在 commit `9ca740baffcfbeb296a1f5ebc57d0bc2f4bda1fe`（来自 `https://github.com/mfessenden/SKTiled.git`），用于读取 / 渲染 Tiled 地图。

## 首章明确不允许引入

- ECS 框架库。
- A* 或寻路库（用 GameplayKit 自带的连续空间寻路）。
- JSON Schema 校验库。
- 几何计算库。
- 任何网络、埋点、广告、内购、遥测 SDK。

## 边界约束

`Packages/RiftCore` 必须保持纯 Swift 逻辑，不允许 import SwiftUI、SpriteKit、SKTiled 或 OSLog —— 这样才能脱离 App 独立跑单元测试（见 [`architecture.md`](architecture.md)）。

新增第三方依赖默认不允许；确有必要时，需要在提交信息里说明收益、维护成本与授权协议（见根目录 `AGENTS.md` 的「执行约定」一节）。
