# TypeScript 项目开发规范 for AI

这份参考用于你在“生成/更新仓库的 AGENTS.md”时，遇到 TypeScript/JavaScript 项目（如 Node/React/Vite/Vitest/Playwright、浏览器扩展、脚手架工具等）可以遵循的通用约定。

## 1) 结构与分层（优先“少而清晰”）

- 优先把业务能力沉到 `services/`（数据访问、集成、编排、纯逻辑），UI/交互放 `ui/`，状态与用例编排放 `viewmodels/`。
- 若项目有“平台/入口”概念（如 `entrypoints/`、`platform/`、`collectors/`），可以与 `services/` 平级；但跨层依赖需保持单向：`ui -> viewmodels -> services`（入口层可依赖所有层）。
- 避免“同名能力在多处各自实现”，优先收敛为单一真源，并在 AGENTS.md 中指明真源路径。

## 2) 导入路径与别名（减少 `../../..`）

- 推荐使用 TS `paths` 做别名（例如 `@ui/*`、`@viewmodels/*`、`@services/*` 等），让导入表达层次而不是文件系统相对路径。
- 采用别名通常不仅是“替换 import 字符串”，还需要维护：
  - `tsconfig*.json`（`compilerOptions.baseUrl` + `paths`）
  - bundler 配置（如 Vite/Webpack/Rollup）或运行时（如 ts-node）对别名的解析
  - 测试运行器的别名映射（若测试也使用别名）
- 如果某个目录（例如 `tests/`）明确不使用别名，应在 AGENTS.md 中写清楚，并保持一致。

## 3) 配置文件最小化（尊重现状）

- 默认遵循仓库现有工具链与配置；除非明确被要求，不要引入新的 lint/format/test 配置文件来“补齐规范”。
- 若必须新增/调整配置，优先复用已有文件（例如在既有 `tsconfig.json` 中扩展），避免堆叠多个相近配置产生漂移。

## 4) 代码风格与格式化（以仓库为准）

- 缩进、引号、换行等格式化细节以仓库现有规范为准；不要在重构中顺手做大规模格式化改动，避免噪音 diff。
- 如果仓库已有统一入口脚本（如 `gate`、`lint:fix`、`format`），优先通过这些入口来保证一致性。

## 5) 验证与回归（写进 AGENTS.md）

- 在 AGENTS.md 中列出最小可验证链路（例如：`compile`、`test`、`build`），并说明各命令的“目的”和“适用范围”（例如只跑 Web 项目或只跑扩展）。
- 对易回归区域（路由、打包产物、消息协议、别名解析）给出最小冒烟检查建议。
