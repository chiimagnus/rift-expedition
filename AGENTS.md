# 项目开发规范与指南

本仓库当前是《双生圣痕 · 血脉宿命战棋》的设计蓝图与 Web/Phaser/TypeScript 可执行工程。

## 项目结构与模块组织

- `.github/docs/`：项目蓝图主体，按 A-F 六个领域分组；当前没有 `.github/docs/README.md`。
- `.github/docs/A-玩法设计/`：玩法、战斗、单位、技能、地形、关卡与平衡设计。
- `.github/docs/B-叙事与导演/`：世界观、主线分支、角色、支援会话与演出导演。
- `.github/docs/C-美术与动画/`：美术风格、动画与 UI/HUD 规格。
- `.github/docs/D-音频/`：音乐与音效设计。
- `.github/docs/E-技术工程/`：Web / Phaser / TypeScript 架构、数据模型、存档、测试与门禁规格。
- `.github/docs/F-制作管理/`：路线图、内容规模、开放问题与决策日志。
- `vendor/phaser.min.js`：仓库内已有 Phaser 压缩构建产物；不要手改压缩文件。
- `src/data/`：数据化内容真源，当前包含全地形、起始技能、24 章战役链、4 个结局与首批角色/武器/职业。
- `src/models/`：纯类型与运行时状态模型。
- `src/services/`：战斗、移动、AI、技能/状态、战役存档、章节初始化、PRNG 等纯逻辑。
- `src/viewmodels/`：把 UI Command 翻译成 service 调用。
- `src/ui/`：Phaser Scene 与 HUD，只读渲染状态并上抛操作。
- `src/entrypoints/`：浏览器入口。
- `tests/`：Node test 覆盖非平凡规则。
- `scripts/`：测试构建、冒烟和 gate 脚本。
- 当前根目录没有 `README.md`、`CONTRIBUTING.md`。

## 代码风格与命名规范

- 规格文档沿用既有中文标题、领域前缀与两位编号文件名，不做批量改名。
- 技术方向已在 `.github/docs/E-技术工程/20-技术架构.md` 与 `.github/docs/F-制作管理/25-开放问题与决策日志.md` 拍板为 Web + Phaser + TypeScript。
- TypeScript 路径别名配置在 `tsconfig.json`：`@data/*`、`@models/*`、`@services/*`、`@ui/*`、`@viewmodels/*`。新增导入优先保持分层清晰。
- 业务规则放在 `src/services/` / `src/models/`，Phaser 表现层留在 `src/ui/`；依赖方向保持 `ui -> viewmodels -> services -> models`。
- 已有第三方压缩产物不参与格式化、重构或人工风格统一。

## 测试指南

- 最小门禁：`npm run compile`、`npm test`、`npm run build`、`npm run smoke`；完整入口为 `npm run gate` 或 `scripts/gate.sh`。
- 测试运行方式：`npm test` 先用 esbuild 打包 `tests/*.test.ts` 到 `dist-tests/`，再用 `node --test` 执行。
- 非平凡规则必须有最小可跑检查：战斗结算、寻路、AI、存档迁移、PRNG 与平衡模拟优先覆盖。
- 表现层以冒烟和手玩验证为主；纯逻辑保持不依赖 Phaser，便于在 Node 下直接测试。

## 开发规范（详细）

对齐说明：
- 根目录 `README.md` 与 `CONTRIBUTING.md` 当前不存在。
- 当前可运行命令来自 `package.json`：`compile`、`test`、`build`、`smoke`、`gate`、`dev`。
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
