# plan-p3.md — M1 战斗核心 · Phase 3（回合状态机与平衡模拟）

> 本文档只写实施细节，需求真源见 `idea.md`。数值/阈值锚点全部来自 A/03 / A/09 / E/22，禁止自行推导。
> 已结合 M1 P1 全部源码与 Phase 2 交付面（`src/services/combat.ts`）审核；审核发现写入各 task。
> 前置：Phase 2（`plan-p2.md`）全部 task 已完成、`audit-p2.md` 审计通过。

Goal：在 Phase 2 的战斗结算之上，交付两件纯逻辑产物：
1. **回合阶段状态机**（`src/services/turnState.ts`）——对已构造好的 `BattleState` 做确定性阶段推进的纯函数。
2. **平衡模拟**（`src/services/simulate.ts` + CLI 入口 `src/entrypoints/sim.ts`）——兵种循环赛、种子化胜率统计与超阈值告警（A/09 / E/22 量化验收）。

Non-goals：
- **不建任何测试地图/初始 `BattleState` 工厂函数**——见下「M1-P3 vs M2 边界」。
- 不写 AI 决策（走位/目标选择）；simulateDuel 仅做“相邻 1v1 对砍”的最小可判定模型（验相克方向与胜率收敛足矣）。
- 不向 `scripts/gate.sh` 加入 sim（模拟负重，属手动/CI 另跳；E/22 第五节）。
- 不碰 `src/ui`/`src/viewmodels`；`src/entrypoints/sim.ts` 仅作 CLI 组装（entrypoints 可依赖下层）。
- 不写 no-op 占位函数、不留 dead code（idea 核心需求 1 + YAGNI）。

Approach：
- turnState / simulate 均属 `services` 层，可 `import` `@models/*` 与同层 `@services/*`（prng/combat），**禁止反向**，禁止 Phaser/DOM（根 AGENTS.md 分层职责）。
- `sim.ts` 在 `entrypoints`（可依赖所有层，但只做组装），仅 import `@services/simulate`，**绝不引 Phaser/UI/main.ts**。
- 所有随机经 `@services/prng.next` 串行推进 rngState，结果确定可复现（E/22 第五节）。

**❗ M1-P3 vs M2 边界（与 M2 plan 不重叠，已核 `m2-vertical-slice` plan）：**
M2 `plan-p1` 的 P1-T2 已安排“合成测试地图 + 初始 `BattleState` 工厂函数”。为避免重复：
- M1-P3 的 `turnState.ts` **只对已构造好的 `BattleState` 做阶段推进**，单测用**内联字面量**构造最小 state，**不对外提供任何场景/地图工厂**。
- M1-P3 的 `simulate.ts` 自己拼的是 `combat.Combatant`（不是 `BattleState`），不依赖任何地图。真正的战斗场景工厂留给 M2 P1-T2。

**Rules（严格遵守根 AGENTS.md）：**
- 不 `git add` `.github/features/**`；一 task 一原子提交；subject `<type>: <task-id> - <中文>`。
- 某 task 替换/废弃旧代码必须在同一 task 内删除（本 phase 无已知需删旧代码；viewmodels/.gitkeep 属 M2，不动）。
- 随机只经 `@services/prng`；禁 `Math.random`。
- turnState/simulate/sim 不引 Phaser/DOM；sim 不入 gate。
- 每条阈值必须指向 A/09 / E/22 具体行；无锚点数值入末尾「开放问题」。
- service 文件顶部写 `Goal:`/`Non-goals:`/`错误处理:` 注释头（E/22 第二节）。
- 测试发现固定 `npx --no-install tsx --test 'src/**/*.test.ts'`；单 task 可跑单个显式文件，但**提交前跑一次完整 `bash scripts/gate.sh`**。

---

## P3-T1 回合阶段状态机 turnState.ts

Files：
- `src/services/turnState.ts`（新建）
- `src/services/turnState.test.ts`（新建）

背景（已核实源码）：`@models/battleState` 已定义 `BattlePhase = 'deploy'|'player'|'enemy'|'resolve'` 与 `BattleState`（含 `gridWidth/gridHeight/grid/units/phase/rngState/turnCount`，均为必填），但**无任何行为函数**（纯类型）。本 task 提供阶段推进纯函数。

实现步骤：
1. 文件顶部写规格头（Goal: 对 BattleState 做确定性阶段推进；Non-goals: 不造地图/state、不处理 AI/移动/战斗；错误处理: 未知 phase 抛错）。
2. 导出 `nextPhase(phase: BattlePhase): BattlePhase`（纯映射，不碰 turnCount）：
   ```
   deploy  -> player
   player  -> enemy
   enemy   -> resolve
   resolve -> player   // 不回 deploy（部署只发生一次）
   ```
   未知 phase 抛 `Error`（`noFallthroughCasesInSwitch` 已开，switch 需穷尽）。
3. 导出 `advancePhase(state: BattleState): BattleState`（返回新对象，不变更入参）：`phase = nextPhase(state.phase)`；**当且仅当 `resolve -> player` 时 `turnCount + 1`**（一个完整回合 = player+enemy+resolve）；其余字段原样展开。用 `{ ...state, phase, turnCount }` 保留不变量。
4. 测试（内联字面量构造最小 state，**必填全部字段**，否则 strict 下 tsc 报错）：
   ```typescript
   import type { BattleState } from '@models/battleState'
   const base: BattleState = {
     gridWidth: 1, gridHeight: 1, grid: [['plain']],
     units: [], phase: 'player', rngState: 0, turnCount: 1,
   }
   ```
   - `nextPhase` 四条转移各一条断言；deploy->player、resolve->player 重点验。
   - `advancePhase({...base, phase:'resolve', turnCount:1})` → `phase==='player' && turnCount===2`。
   - `advancePhase({...base, phase:'player', turnCount:1})` → `phase==='enemy' && turnCount===1`（不加）。
   - 断言不变更入参（原 `base.phase` 仍为 'player'）。
   - 非法 phase 强转后调 `nextPhase` 抛错（`assert.throws`）。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/turnState.test.ts` → exit 0。

提交：`git add src/services/turnState.ts src/services/turnState.test.ts && git commit -m "feat: P3-T1 - 实现回合阶段状态机 advancePhase（resolve->player 时 turnCount++）"`。

---

## P3-T2 单决斗模拟 simulateDuel

Files：
- `src/services/simulate.ts`（新建）
- `src/services/simulate.test.ts`（新建）

背景（已核 Phase 2 接口）：`combat.resolveCombat(ctx, atkHp, defHp)`，其中 `ctx: CombatContext = { attacker, defender, distance, rngState }`，返回 `CombatResult = { events, attackerHpAfter, defenderHpAfter, rngState }`。simulateDuel 需基于此接口交替出手。

实现步骤：
1. 文件顶部规格头（Goal: 固定种子下两个 Combatant 相邻 1v1 对砍至一方倒下/到回合上限，返回胜方；Non-goals: 不做 AI/移动/地形；错误处理: roundCap 夹取防死循环）。
2. 导出：
   ```typescript
   import { resolveCombat, type Combatant } from '@services/combat'
   export type DuelOutcome = 'a' | 'b' | 'draw'
   export interface DuelResult { winner: DuelOutcome; rounds: number; rngState: number }
   export function simulateDuel(
     a: Combatant, aHp: number,
     b: Combatant, bHp: number,
     rngState: number, roundCap = 100,
   ): DuelResult
   ```
3. 循环：每回合由 a 作为攻方调 `resolveCombat({ attacker:a, defender:b, distance:1, rngState }, aHp, bHp)`（distance=1 相邻，守方可反击），用返回的 `attackerHpAfter/defenderHpAfter` 更新 aHp/bHp、`rngState` 串行；若未分胜负，下一回合改由 b 作攻方（交替先手）。任一方 hp≤0 即结束。
4. `rounds` 达 `roundCap` 仍未分胜负 → `winner:'draw'`。
5. 测试：
   - 确定性：同一输入+同种子调两次 → `winner`/`rounds`/`rngState` 完全相同。
   - 碾压：高攻高血 a vs 极脆 b → `winner==='a'`（少回合）。
   - 僵局防护：两个敌防极高、伤害恒为 minDamage 1 的 Combatant + 小 roundCap → `winner==='draw'`（验 roundCap 生效）。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/simulate.test.ts` → exit 0。

提交：`git add src/services/simulate.ts src/services/simulate.test.ts && git commit -m "feat: P3-T2 - 实现单决斗模拟 simulateDuel（交替先手/roundCap）"`。

---

## P3-T3 兵种循环赛 runMatchups

Files：
- `src/services/simulate.ts`（修改）
- `src/services/simulate.test.ts`（修改）

实现步骤：
1. 导出统计类型：
   ```typescript
   export interface MatchupStat { aId: string; bId: string; aWins: number; bWins: number; draws: number; iters: number; aWinRate: number }
   export interface MatchupReport { stats: MatchupStat[]; warnings: string[] }
   export function runMatchups(iters: number, seed: number): MatchupReport
   ```
2. 兵种与默认武器（模拟测床默认，写注释说明是测床选型非设计硬锚点）：用 `@models/units` `UNIT_DEFS`（infantry/cavalry/flier）与 `@models/weapons` `WEAPON_BY_ID`；infantry->ironSword、cavalry->ironLance、flier->ironSword。由 `UnitDef.base`（Stats）+ WeaponDef 拼 `combat.Combatant`：`{ stats: base, armament:{kind:'physical',def:weapon}, tags: unit.tags, terrainAvo: 0 }`（平地无回避；**无 terrainDef 字段**，对齐 Phase 2 Combatant）。
   - 注：默认武器均无 antiAirBonus → 模拟不引入对空秒杀（特攻另行验证），避免扭曲平衡。
3. 对每对兵种（含镜像同种）跑 `iters` 局：**半数局 a 先手、半数 b 先手（交替）**以抵消先手优势；每局初始 hp 取各自 `base.hp`；rngState 全程由 `seed(seed)` 起串行推进（确定可复现）。
4. 告警（A/09 / E/22 量化阈值）：
   - 镜像对战（同兵种）`aWinRate` 偏离 50%±5% → push 告警。
   - 任一兵种对全体平均胜率 >60% → push 告警。
5. 测试（小 iters 保证快）：
   - 确定性：`runMatchups(50, 42)` 调两次 → stats 完全相同。
   - 相克方向：同底板换武器（infantry 分别持 ironSword/ironAxe/ironLance）验证 剑>斧>枪>剑 胜率方向（放到 P3-T5 平衡测试也可；本 task 至少验 runMatchups 产出结构正确）。
   - 镜像对战 aWinRate 在 [0.45,0.55]（交替先手下对称收敛）。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/simulate.test.ts` → exit 0。

提交：`git add src/services/simulate.ts src/services/simulate.test.ts && git commit -m "feat: P3-T3 - 实现兵种循环赛 runMatchups 与超阈值告警"`。

---

## P3-T4 平衡模拟 CLI 入口 sim.ts + npm run sim

Files：
- `src/entrypoints/sim.ts`（新建）
- `package.json`（修改：加 `sim` 脚本）

背景（已核实源码）：`scripts/build.mjs` 的 `entryPoints` 固定为 `['src/entrypoints/main.ts']`（非 glob）→ 新增 `sim.ts` **不会被 gate 的 build 步骤打包进浏览器 bundle**，也不影响冲烟（smoke 只加载 index.html）。无需改 build.mjs。

实现步骤：
1. `sim.ts`（纯 Node CLI，**不引 Phaser/UI/main.ts**）：解析 `--matchup`（暂只支持 `all`）/`--iters`（默认 2000，E/22 示例）/`--seed`（默认 42）；调 `runMatchups(iters, seed)`；`console.log` 打印每对兵种胜率表 + 告警清单；有告警时 `process.exitCode = 1`（供 CI 可选卡控）。参数解析用纯手写（不引依赖，沙箱无网）。
2. `package.json` `scripts` 加：`"sim": "npx --no-install tsx src/entrypoints/sim.ts"`（`--no-install` 用本地 tsx；tsx 遵 tsconfig paths 解析别名）。**不动 `scripts/gate.sh`**（sim 不入门禁）。
3. 不写单测（CLI 组装层，非平凡逻辑已在 simulate 测过；E/22 第七节反过度工程）。

验证命令（手动跑一次小规模验证 CLI 可运行，不入 gate）：
`cd /data/rift-expedition && npm run sim -- --matchup all --iters 100 --seed 42` → 打印胜率表；再跑 `npx tsc --noEmit` → exit 0（确保 sim.ts 类型正确）。

提交：`git add src/entrypoints/sim.ts package.json && git commit -m "feat: P3-T4 - 新增平衡模拟 CLI sim.ts 与 npm run sim（不入 gate）"`。

---

## P3-T5 平衡量化验收测试

Files：
- `src/services/simulate.balance.test.ts`（新建）

背景：E/22 第四节量化验收需作为可执行文档入测（纳入 gate 的 test glob，命名 `*.test.ts`）。

实现步骤（每条锚 A/03/A/09/E/22）：
1. **相克方向**：同底板 infantry 换三种武器两两对打（用 simulateDuel 或 runMatchups 子集，固定种子多局），断言 剑>斧、斧>枪、枪>剑 的胜率方向（>50%）——E/22 “剑>斧>枪>剑”。
2. **对称收敛**：镜像对战（同兵种同武器，交替先手）`aWinRate` ∈ 50%±5%（A/09 / E/22）。
3. **无支配策略**：`runMatchups` 结果中无任一兵种平均胜率 >60%（无则断言 warnings 不含该项；若有则测试红灯暴露需调参）。
4. iters 取可接受的中等量（如 300～500，兼顾 gate 时长与统计稳定；若 gate 超时可降）；固定 seed 保证确定。
5. ❗ **开放问题：** 若当前武器/兵种数值（斧 8/75、枪 7/80 等非锜点定价）导致某阈值不过，**不得为过测试而自行改数值**；应在 audit-p3.md 记录并回到 A/09 调参工作流（×2/÷2 → 二分），由用户/设计拍板后再改 `WEAPON_DEFS`。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/simulate.balance.test.ts` → exit 0。

提交：`git add src/services/simulate.balance.test.ts && git commit -m "test: P3-T5 - 平衡量化验收（相克方向/对称收敛/无支配策略）"`。

---

## P3-T6 更新根 AGENTS.md 记录 M1 Phase 3 模块

Files：
- `AGENTS.md`（修改，需要提交）

实现步骤：
1. 末尾新增 `## M1 Phase 3 新增模块`：
   - `src/services/turnState.ts`：`nextPhase`/`advancePhase`（纯函数，resolve->player 时 turnCount++）；不造 state/地图。
   - `src/services/simulate.ts`：`simulateDuel`/`runMatchups`（种子化循环赛 + 超阈值告警）；自拼 `combat.Combatant`，不依赖 BattleState/地图。
   - `src/entrypoints/sim.ts` + `npm run sim`：平衡模拟 CLI，**不入 gate**（build.mjs entryPoints 固定 main.ts，sim 不进 bundle）。
   - 标注 M1-P3 vs M2 边界：M1-P3 不造战斗场景/BattleState 工厂（那是 M2 P1-T2）。
2. 只追加不删改。

验证命令：`cd /data/rift-expedition && grep -q "M1 Phase 3" AGENTS.md && echo OK`。

提交：`git add AGENTS.md && git commit -m "docs: P3-T6 - 记录 M1 Phase3 回合状态机与平衡模拟模块"`。

---

## 开放问题汇总（需设计/用户拍板）

1. **非锜点武器数值导致平衡阈值不过时的处置**（P3-T5）：不自行改数，走 A/09 调参工作流，拍板后再改。
2. 模拟默认武器映射（infantry->剑、cavalry->枪、flier->剑）为测床选型，非设计硬锚点；若设计有兵种专属武器约束，待确认后调整。

## Phase 3 完成后的审计约定（audit-p3.md）

Phase 3 全部 task 完成并提交后，进入 `audit-p3.md` 审计闭环，重点检查：
- `advancePhase` 四条转移与 turnCount++ 时机（仅 resolve->player）正确；不变更入参；非法 phase 抛错。
- simulateDuel 确定可复现、交替先手、roundCap 生效。
- runMatchups 镜像对战 50%±5%、无兵种 >60%、相克方向 剑>斧>枪>剑（均有断言）。
- sim.ts 不引 Phaser/UI；sim 未入 gate.sh；build.mjs 未被改动（仍只打包 main.ts）。
- **无 no-op 占位函数、无 dead code；turnState/simulate/sim 零 `Math.random`、零 Phaser/DOM；无跨层反向依赖。**
- 未为过测试而擅自改数值；未提前建 BattleState 工厂（与 M2 P1-T2 不重叠）。
- 重跑 `npx tsc --noEmit`、`npx --no-install tsx --test 'src/**/*.test.ts'`、`bash scripts/gate.sh` 均 exit 0；另手动 `npm run sim -- --iters 2000 --seed 42` 胜率表合理。
