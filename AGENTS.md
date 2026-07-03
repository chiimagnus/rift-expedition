# 项目开发规范与指南

本仓库当前是《双生圣痕 · 血脉宿命战棋》的设计蓝图与技术规格仓库；可执行 Web/Phaser/TypeScript 工程尚未落地。

## 项目结构与模块组织

- `.github/docs/`：项目蓝图主体，按 A-F 六个领域分组；当前没有 `.github/docs/README.md`。
- `.github/docs/A-玩法设计/`：玩法、战斗、单位、技能、地形、关卡与平衡设计。
- `.github/docs/B-叙事与导演/`：世界观、主线分支、角色、支援会话与演出导演。
- `.github/docs/C-美术与动画/`：美术风格、动画与 UI/HUD 规格。
- `.github/docs/D-音频/`：音乐与音效设计。
- `.github/docs/E-技术工程/`：Web / Phaser / TypeScript 架构、数据模型、存档、测试与门禁规格。
- `.github/docs/F-制作管理/`：路线图、内容规模、开放问题与决策日志。
- `vendor/phaser.min.js`：仓库内已有 Phaser 压缩构建产物；不要手改压缩文件。
- 当前根目录没有 `README.md`、`CONTRIBUTING.md`、`package.json`、`tsconfig*.json`、源码目录或测试目录。

## 代码风格与命名规范

- 现阶段主要维护 Markdown 规格文档：沿用既有中文标题、领域前缀与两位编号文件名，不做批量改名。
- 技术方向已在 `.github/docs/E-技术工程/20-技术架构.md` 与 `.github/docs/F-制作管理/25-开放问题与决策日志.md` 拍板为 Web + Phaser + TypeScript。
- 开始 M0 引擎骨架时，再按技术规格创建 `entrypoints/`、`ui/`、`viewmodels/`、`services/`、`models/` 等目录；未开始前不要空搭脚手架。
- 业务规则放在 `services/` / `models/`，Phaser 表现层留在 `ui/`；依赖方向保持 `ui -> viewmodels -> services -> models`。
- 已有第三方压缩产物不参与格式化、重构或人工风格统一。

## 测试指南

- 当前仓库没有可运行测试脚本或包管理配置，不要凭空新增 lint/format/test 配置。
- 一旦加入 TypeScript 工程，门禁以 `.github/docs/E-技术工程/22-可执行规格与测试.md` 为准：类型检查、`node --test`、构建、冒烟检查。
- 非平凡规则必须有最小可跑检查：战斗结算、寻路、AI、存档迁移、PRNG 与平衡模拟优先覆盖。
- 表现层以冒烟和手玩验证为主；纯逻辑保持不依赖 Phaser，便于在 Node 下直接测试。

## 开发规范（详细）

对齐说明：
- 根目录 `README.md` 与 `CONTRIBUTING.md` 当前不存在；原 `AGENTS.md` 为空文件。
- 当前没有 `package.json`、`tsconfig*.json`、源码目录或测试目录，因此还不能列出真实可运行命令。
- 仓库技术蓝图已明确 Web + Phaser + TypeScript；本节收录 TypeScript / JavaScript 真源规范全文，作为当前协作约束。
- 测试策略以 `.github/docs/E-技术工程/22-可执行规格与测试.md` 的 `node --test`、平衡模拟 CLI 与冒烟检查为落地目标。

### TypeScript 项目开发规范 for AI

这份参考用于你在“生成/更新仓库的 AGENTS.md”时，遇到 TypeScript/JavaScript 项目（如 Node/React/Vite/Vitest/Playwright、浏览器扩展、脚手架工具等）可以遵循的通用约定。

#### 1) 结构与分层（优先“少而清晰”）

- 优先把业务能力沉到 `services/`（数据访问、集成、编排、纯逻辑），UI/交互放 `ui/`，状态与用例编排放 `viewmodels/`。
- 若项目有“平台/入口”概念（如 `entrypoints/`、`platform/`、`collectors/`），可以与 `services/` 平级；但跨层依赖需保持单向：`ui -> viewmodels -> services`（入口层可依赖所有层）。
- 避免“同名能力在多处各自实现”，优先收敛为单一真源，并在 AGENTS.md 中指明真源路径。

#### 2) 导入路径与别名（减少 `../../..`）

- 推荐使用 TS `paths` 做别名（例如 `@ui/*`、`@viewmodels/*`、`@services/*` 等），让导入表达层次而不是文件系统相对路径。
- 采用别名通常不仅是“替换 import 字符串”，还需要维护：
  - `tsconfig*.json`（`compilerOptions.baseUrl` + `paths`）
  - bundler 配置（如 Vite/Webpack/Rollup）或运行时（如 ts-node）对别名的解析
  - 测试运行器的别名映射（若测试也使用别名）
- 如果某个目录（例如 `tests/`）明确不使用别名，应在 AGENTS.md 中写清楚，并保持一致。

#### 3) 配置文件最小化（尊重现状）

- 默认遵循仓库现有工具链与配置；除非明确被要求，不要引入新的 lint/format/test 配置文件来“补齐规范”。
- 若必须新增/调整配置，优先复用已有文件（例如在既有 `tsconfig.json` 中扩展），避免堆叠多个相近配置产生漂移。

#### 4) 代码风格与格式化（以仓库为准）

- 缩进、引号、换行等格式化细节以仓库现有规范为准；不要在重构中顺手做大规模格式化改动，避免噪音 diff。
- 如果仓库已有统一入口脚本（如 `gate`、`lint:fix`、`format`），优先通过这些入口来保证一致性。

#### 5) 验证与回归（写进 AGENTS.md）

- 在 AGENTS.md 中列出最小可验证链路（例如：`compile`、`test`、`build`），并说明各命令的“目的”和“适用范围”（例如只跑 Web 项目或只跑扩展）。
- 对易回归区域（路由、打包产物、消息协议、别名解析）给出最小冒烟检查建议。

## 参考资料

- `.github/docs/E-技术工程/20-技术架构.md`
- `.github/docs/E-技术工程/22-可执行规格与测试.md`
- `.github/docs/F-制作管理/25-开放问题与决策日志.md`
