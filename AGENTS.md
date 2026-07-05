# Apple App 开发规范

## 核心技术栈
平台支持：macOS 14.0+

- 架构模式：MVVM (Model-View-ViewModel)
- 编程范式：Protocol-Oriented Programming（面向协议）
- UI：SwiftUI
- 状态管理：Observation（`@Observable` / `@Bindable`）；必要时使用 Swift Concurrency；仅在需要 Publisher 管道时引入 Combine
- 持久化：SwiftData（按需）
- Swift：Swift 6.0+
- 游戏相关的开发框架包括：<需要补充>

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
