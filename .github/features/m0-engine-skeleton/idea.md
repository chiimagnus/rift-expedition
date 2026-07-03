# idea.md — M0 引擎骨架（双生圣痕 · 血脉宿命战棋）

> 需求真源。plan-p1.md 只负责实现拆分与执行细节，不重复这里的决策背景。

## 背景 / 触发

- 项目《双生圣痕 · 血脉宿命战棋》设计蓝图已完成（6 域 25 篇设计文档 + 决策日志），技术栈已在设计蓝图 E-技术工程/20 与 F-制作管理/25 中拍板：**Web + Phaser 3（CDN 引入）+ TypeScript（严格模式）**，无后端，桌面端优先。
- 按 F/24 路线图，开发从 **M0 引擎骨架** 开始：先搭好分层架构与 Phaser 启动骨架，不含任何游戏规则/内容，为 M1（战斗核心）打地基。M0 → M1 → M2 → (M3 → M4 → M5 → M6) 存在严格依赖顺序，不能跳过或合并。
- 本 feature 只覆盖 M0。M1（战斗核心：相克/移动/攻击/追击/地形/PRNG/单测/平衡 CLI）在 M0 完成审计后另起 `m1-combat-core` feature 规划，避免一次性铺开过多范围（阶梯原则 / YAGNI）。
- 沙箱环境已核实：Node 24 + TypeScript + esbuild + webpack + headless Chromium 均已预装；沙箱**默认无网络访问**（`curl` 测试超时），且未安装 `phaser` npm 包（连类型声明也没有）；因此 Phaser 只能走 CDN `<script>` 全局引入，TS 侧需要一份 ambient 类型声明兜底。

## 核心需求（原始需求精炼）

1. 建立单向依赖分层目录：`src/entrypoints → src/ui → src/viewmodels → src/services → src/models`（依赖方向只能由左到右；entrypoints 可依赖任意层，其余层不得反向依赖上层）。
2. TypeScript 严格模式（`strict: true`），配置路径别名 `@ui/* @viewmodels/* @services/* @models/*`（不含 `entrypoints`：设计蓝图 [E/20] 明确只列了这 4 个别名，且没有任何层会反向 import `entrypoints`——entrypoints 只是可执行入口，给它设别名是没人用的死配置，违反阶梯第 1 级 YAGNI）；别名需要在 `tsconfig.json`、esbuild 打包、**测试运行器**三处都能一致解析（三处同步，禁止只改一处）。**已实测确认**：Node 24 原生 `--test`（无 loader）无法解析 `tsconfig.json` 的 `paths` 别名（报 `ERR_MODULE_NOT_FOUND`），因此测试运行器必须用沙箱预装的 `tsx`（`npx --no-install tsx --test`），不能用裸 `node --test`。
3. Phaser 3 通过 **CDN** 加载（锁定具体版本号，不用 `latest`），游戏代码本身用 esbuild 打包成单个 `dist/main.js`（ESM），`index.html` 依次引入 CDN Phaser 与 `dist/main.js`。
4. Phaser 初始化配置：`pixelArt: true`、`roundPixels: true`、`antialias: false`、整数倍缩放（`Phaser.Scale.FIT` + 手动计算的整数 zoom），逻辑分辨率 448×320（14×10 格 × 32px，对应设计蓝图 15/16 的像素网格约定）。
5. 三个初始 Scene：
   - `BootScene`：占位加载与进度文字，完成后立即启动 `BattleScene` 与 `UIScene`。
   - `BattleScene`：空场景（只渲染一个占位背景色块），用于验证渲染管线跑通。
   - `UIScene`：独立叠加场景，与 `BattleScene` 并行运行，避免战场相机缩放影响 HUD（为后续 HUD 开发预留场景边界）。
6. 建立门禁脚本 `scripts/gate.sh`，按顺序执行且任一步失败即整体失败：类型检查（`tsc --noEmit`）→ 单元测试（`npx --no-install tsx --test`，已实测确认 Node 原生 `--test` 无法解析路径别名）→ 构建（`node scripts/build.mjs`）→ 冒烟检查（`node scripts/smoke.mjs`，headless Chromium 加载 `index.html` 并断言无 JS 报错、`window.game` 是 `Phaser.Game` 实例）。
7. 仓库根目录补一份精简 `AGENTS.md`：记录分层规则、别名映射表、`gate` 命令用途与运行方式，供后续没有额外聊天上下文的执行者（包括 `executing-plans`）也能正确操作。

## 默认值与兼容策略

- 全新仓库，没有历史代码/配置需要兼容，不考虑旧版本迁移。
- 若 M1 之后需要新增 npm 依赖：默认只用沙箱已预装或可离线获得的包；若必须联网安装，先跟用户确认网络访问权限，不能默认假设可以 `npm install`。
- Phaser CDN 版本：锁定一个具体稳定版本（如 `3.80.1`），后续升级需显式修改 `index.html` 里的版本号，不自动跟随 `latest`。

## 非目标（明确不做什么）

- 不实现任何战斗规则、寻路、AI、地形、技能、存档等游戏逻辑（属于 M1 及之后，见 `m1-combat-core`）。
- 不接入真实美术/音频资源（设计蓝图 F/25 决策 Q1：先占位期，后续替换开源像素素材）。
- 不做移动端/触屏适配（决策 Q4：桌面端优先）。
- 不引入状态管理库、ECS 框架、额外的打包工具链（沿用 esbuild + TS 原生能力）。
- 不创建 `CutsceneScene`：设计蓝图 [E/20] 正文提到 4 个 Scene（Boot/Battle/UI/Cutscene），但给出的具体 Phaser 配置示例只实例化了 3 个（`scene: [BootScene, BattleScene, UIScene]`）；Cutscene 服务于 [B/14] 演出 DSL，属于 M2+ 内容驱动阶段才需要，M0 严格按配置示例走，只建 3 个 Scene。
- 不为 M0（没有业务逻辑）编造非平凡单元测试；本阶段唯一允许存在的测试文件是验证「路径别名三处同步」这一 M0 自身交付物的最小探针测试（见 P1-T9），不是游戏逻辑测试；M1 引入真实 models/services 单测后应删除这个探针文件，避免遗留占位代码。

## 验收标准（可检查）

- [ ] 目录结构存在且依赖方向正确：`src/entrypoints`、`src/ui/scenes`、`src/viewmodels`、`src/services`、`src/models`（后三者本阶段允许为空目录，用 `.gitkeep` 占位）。
- [ ] `npx tsc --noEmit` 零错误退出（exit code 0）。
- [ ] `npx --no-install tsx --test` 以 exit code 0 结束，且能通过验证 `@models/*` 别名解析成功的最小探针测试（已实测：裸 `node --test` 无法解析 tsconfig 别名，必须用 `tsx`）。
- [ ] `node scripts/build.mjs` 成功产出非空的 `dist/main.js`。
- [ ] `node scripts/smoke.mjs` 用 headless Chromium 加载打包后的 `index.html`：控制台无 JS 错误，且能检测到 `window.game instanceof Phaser.Game`。
- [ ] `bash scripts/gate.sh` 一键跑完“类型检查 → 测试 → 构建 → 冒烟”四步且全部成功（exit code 0）。
- [ ] `git log --oneline` 能看到每个 task 对应一次原子提交，且 `.git/` 历史可读（`git log --oneline --max-count=5` 有输出）。

## 移交备注（给低上下文执行者）

1. 严格只做 M0 范围内的事：不要提前实现 M1 的战斗/相克/寻路/AI 逻辑，哪怕顺手写一点也不行。
2. 不要 `git add`/`git commit` `.github/features/**` 下的计划文件（`idea.md`/`todo.toml`/`plan-p1.md`/`audit-p1.md`）；只提交 `src/`、`scripts/`、`index.html`、`package.json`、`tsconfig.json`、根 `AGENTS.md` 等真实代码文件。
3. 每个 task：先跑该 task 的验证命令确认通过，再一次性 `git add` 该 task 涉及的文件后 `git commit`；commit subject 以稳定 task id 开头（如 `P1-T3 - ...`），使用中文描述，遵循 Conventional Commits 前缀（`feat:`/`chore:`/`test:` 等）。
4. 路径别名必须同时在 `tsconfig.json` 的 `compilerOptions.paths`（含正确的 `baseUrl`）、esbuild 打包与测试运行器中生效；**已在本沙箱实测确认**：esbuild 会自动读取 `tsconfig.json` 的 `baseUrl`/`paths` 并正确打包别名导入，不需要额外插件；但 Node 原生 `--test` 不会读取 `paths`（会报 `ERR_MODULE_NOT_FOUND`），必须改用沙箱预装的 `tsx`（`npx --no-install tsx --test`）作为测试运行器，三处（tsc / esbuild / tsx）才能真正同步。
5. 沙箱默认无网络访问；`esbuild`、`typescript`、`chromium` 已预装，不需要 `npm install`。若发现某个包缺失，先判断是否真的必要（阶梯第 5 级），不要默认尝试联网安装。
6. Phaser 只通过 CDN `<script>` 标签引入（形成全局 `Phaser` 变量），不要 `npm install phaser`、不要用 `import Phaser from 'phaser'`（沙箱未装该包，线上交付也约定走 CDN）。TS 侧用 `src/types/phaser-global.d.ts` 声明一个宽松的全局 `Phaser: any` 兜底，避免类型报错；用 `// ponytail:` 注释标注这是有意的简化及后续升级路径（改成官方类型包）。
7. 完成本 phase 全部 task 后，必须先进入 `audit-p1.md` 的审计闭环（发现问题→修复→重跑验证命令），确认通过后才能开始规划下一个 feature（M1）。
