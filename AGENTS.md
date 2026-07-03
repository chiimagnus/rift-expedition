# 双生圣痕 · 开发规范（仓库根）

本文件是本仓库的开发约定，任何在此仓库工作的人/agent 都必须遵守。

## 分层架构

依赖方向严格从左到右，禁止反向：

```
entrypoints → ui → viewmodels → services → models
```

- `entrypoints` 可依赖所有层（只做组装）；其余层不得反向依赖上层。
- `ui` 只能经由 `viewmodels` 访问下层，不得跳过 `viewmodels` 直达 `services`/`models`。

## 分层职责边界（对齐设计蓝图 E/20，严守）

- **ui**：渲染只读状态、播放演出、收集输入。禁止写规则、禁止直接改 `models`。
- **viewmodels**：组织表现状态、把 Command 派发给 `services`。禁止依赖 Phaser、禁止写战斗规则。
- **services**：结算/寻路/AI/存档等纯逻辑。禁止引用 Phaser、禁止读 DOM。
- **models**：只放纯数据结构与不变量。禁止含行为副作用。

## 路径别名

- `@ui/*`、`@viewmodels/*`、`@services/*`、`@models/*` 均指向 `src/*`。
- `entrypoints` 不设别名（没有层需要反向 import 它）。
- 修改别名需同步改 `tsconfig.json`；esbuild 自动跟随 `tsconfig.json` 的 `paths`，无需单独改。

## 测试

- 测试运行器固定用 `npx --no-install tsx --test 'src/**/*.test.ts'`（用显式 glob 限定，切勿写成裸目录 `tsx --test src`——那会把 `src` 当字面文件名导致测试直接失败），不要用裸 `node --test`：已实测 Node 原生 `--test` 无法解析 `tsconfig.json` 的 `paths` 别名（`ERR_MODULE_NOT_FOUND`），`tsx` 可以。
- 测试发现必须限定在 `src/**/*.test.ts` glob，不要跑裸 `tsx --test`（Node 测试运行器会把任何 `test/` 目录下的文件都当测试执行，也可能拾取非预期文件而报错）。
- 测试文件放在被测模块旁，命名 `*.test.ts`。不要把非测试文件放进任何 `test/` 目录（测试运行器会误当测试执行）。

## Phaser

- Phaser 一律从本地 `vendor/phaser.min.js`（锁定 `4.2.0`）引入：`index.html` 用 `<script src="./vendor/phaser.min.js">`，**不走 CDN**。源代码里绝不 `import`/`require('phaser')`，仅用 `src/types/phaser-global.d.ts` 的全局声明兜底。
- `vendor/phaser.min.js` 是生产依赖，**纳入 git**（放仓库根 `vendor/` 而非 `test/`，以免被测试运行器误当测试执行）。冒烟测试 `scripts/smoke.mjs` 的静态服务器直接托管 `vendor/`，无需任何 CDN 请求拦截/回填。
- 不要 `npm install phaser`。

## 验证

- 提交前必须跑 `bash scripts/gate.sh`（类型检查 / 测试 / 构建 / 冒烟四步全绿）。
- 沙箱默认无网络，不要尝试 `npm install` / `npm ci`。

## 提交约定

- commit subject 格式：`<type>: <task-id> - <中文描述>`，例如 `feat: P1-T3 - 实现 BootScene 占位场景`。
- 一个 task 一个原子提交；某 task 替换/废弃旧代码必须在同一 task 内直接删除，不得拖到最后清理。
- `.github/features/**` 下的规划文件不纳入 git 提交，仅作工作区文件保留。

## M1 Phase 1 新增模块（m1-combat-core）

本阶段只铺“数据 + 纯函数服务”地基，尚无战斗结算/渲染。所有数值逐条对齐 `.github/docs/` 设计蓝图（A/03 战斗、A/04 兵种、A/06 地形）。

- `@models/terrain`：`TerrainDef` / `TERRAIN_DEFS`（18 种）/ `TERRAIN_BY_ID`。`moveCost` 按 foot/horse/fly 分存，`Infinity` 表不可通行；仅毒沼/火山岩为 `effect:'periodicDamage'`，其余特殊仅 `effectNote` 文字记录。
- `@models/weapons`：`WEAPON_TRIANGLE` / `MAGIC_TRIANGLE`（每行和=0）、`COMBAT` 可调参表、`WEAPON_DEFS`（剑/斧/枪/弓，弓 1-2 射程带 `antiAirBonus`）/ `WEAPON_BY_ID`。
- `@models/units`：`Stats` / `GrowthRates` / `UnitDef` / `UNIT_DEFS`（步 foot / 骑 horse / 飞 fly）/ `UNIT_BY_ID`；飞兵带 `tags:['flying']`。成长率仅声明，本阶段不参与运算。
- `@models/battleState`：`BattleState` / `UnitInstance` 等运行时纯类型。`grid` 为 `string[][]`（地形 id，行优先 grid[y][x]），`rngState:number`。严禁 import `services` 层（含 type-only）。
- `@services/prng`：`seed` / `next`（mulberry32，可注入种子、纯函数、可复现）。
- `@services/reachable`：`computeReachable(grid, start, moveType, movePower)` — Dijkstra 四方向可达域，返回 `Set<"x,y">`。**grid 按 idea.md 核心需求 9 修正为 `string[][]`（地形 id，与 `BattleState.grid` 同型）**，而非 plan-p1 早期写的 `TerrainDef[][]`；调用方自行用 `TERRAIN_BY_ID[id]` 查具体地形。

约定：数据模块（terrain/weapons/units）之间不得互相 import；service 可 import models（反向禁止）。
