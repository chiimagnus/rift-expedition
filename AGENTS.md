# Apple App 开发规范

## 核心技术栈
平台支持：macOS 14.0+

- 架构模式：MVVM (Model-View-ViewModel)
- 编程范式：Protocol-Oriented Programming（面向协议）
- UI：SwiftUI等
- 状态管理：Observation（`@Observable` / `@Bindable`）；必要时使用 Swift Concurrency；仅在需要 Publisher 管道时引入 Combine
- 持久化：SwiftData（按需）
- Swift：Swift 6.0+
- 游戏相关框架：SpriteKit（2D 渲染/场景）、GameplayKit（ECS/状态机/寻路/随机源）、SwiftUI（菜单/HUD/面板）、SKTiled（Tiled 地图接入）

## 本项目游戏边界

项目目标：macOS 原生中文 2D 开放式箱庭 CRPG。首章必须最终做到“村庄 + 野外 + 洞穴”的中箱庭完整章，而不是只停在竖切 demo。

首章范围：
- 平台只做 macOS，默认中文。
- 2 人小队，开局从战士、弓箭手、法师、刺客中选 2 人。
- 自由距离回合制，整数 AP；移动、技能、消耗品都消耗 AP。
- 技能发动先检查距离与视线，再按技能配置处理闪避、伤害、治疗、状态、地表。
- 元素系统首版包含地表状态与角色状态；不要一开始追完整元素百科。
- 地图为 8-10 个区域，目标游玩 45-60 分钟，4-5 场手工固定战斗。
- 剧情为单结局狗血主线 + 1 个无选择支线；对话支持接任务、交任务、触发战斗。
- 敌人不区分 Boss 类型；玩家、NPC、敌人统一建模为 Actor，通过阵营、职业/技能、等级、装备区分。
- 不做大开放世界、随机遭遇、刷怪、商店经济、复杂分支结局、高低差、动态破坏地形。

## 数据驱动与协议边界

- 内容数据用 JSON：职业、武器、装备、饰品、技能、物品、敌人、任务、对话、经验曲线。
- 地图用 Tiled 文件作为编辑源，SKTiled 负责读取/渲染；不要自造完整地图编辑器。
- 启动时必须校验配置引用，开发期必须有独立校验脚本。
- 存档使用版本化 JSON，包含 `schemaVersion`；5 个手动存档 + 5 个自动存档。
- 自动存档只在安全点写入，不允许在战斗中或团灭前覆盖唯一恢复点。
- 职业、武器、技能相互独立：职业只决定初始属性、初始技能、默认装备，不限制后续装备或技能学习。
- 技能效果协议化/组合化：伤害、治疗、加状态、生成地表、位移、召唤等是 effect；不要为每个技能写一套特殊逻辑。
- 引擎规则不要 DSL 化：回合流、AP 结算、寻路、渲染、存档保持 Swift 类型代码。

## 地图与资源规范

- Tiled 对象层命名固定：`spawn`、`npc`、`encounter`、`trigger`、`exit`、`navObstacle`、`surface`、`item`。
- 地图视觉可以用 tileset；移动、技能距离、视线和障碍按连续坐标处理，优先用 GameplayKit 的连续空间 pathfinding。
- 每次生成或大改地图，输出预览图和校验报告：区域连通、出口存在、出生点可达、敌人/宝箱/触发器不在障碍内。
- 美术只能用 CC0 / 自制 / AI 静态图；禁止引入 GPL、CC-BY-SA 或来源不明资源。
- 主分支不能提交灰盒占位图作为正式资源。若临时调试资源不可避免，文件名和注释必须明确 `debug-only`，并在合并前移除。
- 资源必须记录来源、license、下载日期；玩家可见文本用中文，内部 id / 文件名用英文。
- 首版视觉风格以 CC0 像素/俯视 RPG 资源为主；AI 只补头像、图标等静态单图，不依赖 AI 生成成套动画帧。

## 战斗与内容规范

- 全部战斗实体共用 AP + 技能系统；动物咬击、怪物毒液也是技能配置。
- 友军误伤默认关闭，但技能保留 `affectsAllies` 配置。
- 闪避是概率躲避攻击；元素地表、燃烧、中毒等持续效果默认不被闪避，法术是否可闪避由技能配置。
- 敌人 AI 用职业倾向规则：近战贴近、弓手保持距离、法师偏元素、刺客偏绕后；不要首版做复杂规划器。
- 经验升级给属性点，玩家分配生命值、攻击值、防御值、闪避值、魔法值；首版不洗点。
- 装备做武器、护甲、饰品；队伍共享背包；不做随机词条。
- 技能获取来自任务、宝箱、探索奖励；首版不做购买技能书、货币商店。
- 战斗中可用消耗品，消耗品按技能效果处理。
- 全队倒下读取最近安全自动存档；单人倒下战斗胜利后自动复活。

## 执行约定

- 所有 shell 命令统一前缀 `rtk`。
- 定位和理解代码优先尝试 CodeGraph；若仓库未初始化，明确说明后再用 `rg` / 文件读取兜底。
- 非平凡逻辑必须配最小可跑检查：单测、校验脚本或 `demo()`/`assert` 自检。
- 新增第三方依赖默认不允许；当前只确认 SKTiled。必须新增时先说明收益、维护成本、授权。
- 每个实现任务保持最小可用 diff；删除优于新增，不为“以后可能需要”搭框架。

## 设计原则

- 组合优于继承：优先依赖注入
- 接口优于单例：利于测试与替换
- 显式优于隐式：数据流与依赖清晰可追踪
- 协议驱动：优先“新增实现”而不是“改 switch”

工程简洁性：
- KISS：能简单就别复杂
- YAGNI：不为不确定未来预埋
- DRY + WET：避免重复，但别过早抽象（通常重复 2–3 次后再抽）

## MVVM 架构规范

职责划分：
- **Model**：纯数据结构；不放 UI 逻辑（避免引用 SwiftUI/Observation/Combine）
- **ViewModel**：业务流程编排、状态管理、数据转换；不直接做 UI 操作；避免隐藏单例依赖
- **View**：渲染与交互绑定；不写业务逻辑；不直接访问数据库/网络
- **Service/Repository**：网络、持久化、文件 IO 等副作用；优先协议抽象 + 注入

### 模块化规范

当项目允许时，可把“逻辑层”下沉到 SwiftPM，以便：
- 更快的单元测试（测试执行方式按项目工具链约束选择）
- 更强的可复用性与跨平台能力

建议依赖方向保持单向：
`SwiftUI 层 → ViewModel → Services → Models`

建议拆分：
- `Models` target：纯数据结构，尽量零依赖
- `Services` target：业务逻辑与基础设施，依赖 `Models`

注意：若项目本身不采用 SwiftPM 拆分（例如以 Xcode 项目为主），仍然可以遵循上述“职责划分 + 依赖注入 + 单向依赖”的原则。

### ViewModel 规范（Observation 优先）

- 避免单例：不要用 `static let shared`
- 依赖注入优先：初始化参数或 `.environment(...)`

## 协议驱动开发

原则：
1. 先定义协议，再实现类型
2. 用协议消除类型分支（减少 `switch` 的维护成本）
3. 新增能力优先“增加实现”而不是“修改中心分发器”

## 测试与调试

工具约束（本机 Apple/Swift 技能默认）：
- 本目录下涉及 build/test/run 的操作，统一使用原生 `xcodebuild`。
- 涉及 Simulator/Device 与日志相关的操作，按需使用原生 `xcrun simctl` / `log stream` 等系统工具。

单元测试优先级建议：
- **逻辑层 / ViewModel / UI 层**：统一用 XCTest（通过 `xcodebuild test` 跑）

调试与日志：
- 日志用 `os.Logger`，明确 `subsystem` 与 `category`，便于过滤与定位

## Swift 语言规范

- **严格并发:** 默认假设项目可能启用 Swift 6 严格并发检查；以编译器诊断为准，避免 `nonisolated(unsafe)` 之类逃生舱。
- **Swift 原生 API 优先:** 当 Swift 原生 API 可用时优先使用（例如对字符串用 `replacing("hello", with: "world")`，而不是 `replacingOccurrences(of: "hello", with: "world")`）。
- **现代 Foundation API:** 优先使用现代 Foundation API，例如用 `URL.documentsDirectory` 获取 documents 目录，用 `appending(path:)` 拼接 URL。
- **数字格式化:** 不要用 C 风格格式化（例如 `Text(String(format: "%.2f", abs(myNumber)))`）；应使用 `Text(abs(change), format: .number.precision(.fractionLength(2)))`。
- **静态成员查找:** 能用静态成员就用静态成员（例如 `.circle` 而不是 `Circle()`，`.borderedProminent` 而不是 `BorderedProminentButtonStyle()`）。
- **现代并发:** 不要使用旧式 GCD（例如 `DispatchQueue.main.async()`）。需要类似行为时使用 Swift Concurrency。
- **文本过滤:** 基于用户输入进行文本过滤时，使用 `localizedStandardContains()`，不要用 `contains()`。
- **强解包:** 避免强制解包与 `try!`，除非它确实不可恢复。
