# plan-p1.md — M1 战斗核心 · Phase 1（静态数据与确定性基础设施）

> 本文档只写实施细节，不重复需求背景——需求真源见 `idea.md`。

Goal：为 M1 战斗结算（Phase 2）搭好它依赖的所有静态数据与基础服务：地形/武器/单位数据、PRNG 服务、可达域计算。本 phase 结束时还没有伤害/命中等战斗公式，那是 Phase 2（`plan-p2.md`，待本 phase 审计通过后再写）。

Non-goals：不写伤害/命中/追击公式（Phase 2）；不写平衡 CLI/贪心 AI（Phase 3）；不写 BattleState 的回合推进/阶段切换等行为逻辑，即“状态机”本身（Phase 3）——本 phase 新增的 BattleState/UnitInstance 只是纯数据类型定义（见 P1-T7），不含任何状态转换函数；不碰 UI/viewmodels/entrypoints。

Approach：严格按 [E/20] 分层，数据定义放 `src/models/*.ts`（纯数据+类型，无行为副作用），可达域计算服务放 `src/services/reachable.ts`（可以 `import` models，反之禁止）。所有数值直接抄自设计蓝图表格，不自行推导或估算。

Acceptance：见 `idea.md` 验收标准中与本 phase 相关的条目（地形 18 种数值比对、武器/魔法矩阵行和=0、可达域正确性）；伤害/命中示例复现等属于 Phase 2 验收，本 phase 不要求。

**Rules:**
- 不要 `git add`/`git commit` `.github/features/**` 下的规划文件。
- 一个 task 一次原子提交，commit subject 以稳定 task id 开头（中文描述 + Conventional Commits 前缀）。
- 本 phase 不写任何战斗公式、不写 AI、不写技能/转职/存档。
- 数据一律用 `.ts` 常量模块导出，不建 `.json` 运行时文件（原因见 `idea.md` 核心需求 8）。
- `src/services/*` 可以 `import` `src/models/*`（经 `@models/*` 别名），`src/models/*` 禁止反向 `import` `src/services/*`。
- 每条数值必须能指向设计蓝图中的具体表格行，不允许“看起来合理”的自编数值。
- 地形/武器/单位数据模块之间不要互相 `import`（三者都是平行的纯数据模块，参数引用关系留到 P1-T6 用单测断言，不要写成运行时交叉引用）。

---

## P1-T1 可注入种子 PRNG 服务

Files：
- `src/services/prng.ts`（新建）
- `src/services/prng.test.ts`（新建）

实现步骤：
1. 实现 mulberry32 算法，纯函数接口：
   ```typescript
   export type PrngState = number
   export function seed(n: number): PrngState { return n >>> 0 }
   export function next(state: PrngState): [number, PrngState] {
     let t = (state + 0x6D2B79F5) >>> 0
     t = Math.imul(t ^ (t >>> 15), t | 1)
     t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
     const value = ((t ^ (t >>> 14)) >>> 0) / 4294967296
     return [value, t >>> 0]
   }
   ```
2. `state` 必须是普通 `number`（对应 [E/21] `BattleState.rngState: number`），不要用 class/闭包持有可变状态——保持可序列化、可复现。
3. 禁止在此文件以外的任何地方直接调用 `Math.random`（本 task 只需自测，后续 task 遵守）。
4. 测试断言：同一种子连续调用 `next` 两次产生不同值；两个相同种子独立调用产生相同序列（确定性）；连续 10000 次调用的均值在 0.45～0.55 之间（粗略均匀性检查）。

验证命令：`npx --no-install tsx --test src/services/prng.test.ts` → exit code 0。

提交：`git add src/services/prng.ts src/services/prng.test.ts && git commit -m "feat: P1-T1 - 实现可注入种子 PRNG 服务"`。

---

## P1-T2 地形数据模块（18 种）

Files：
- `src/models/terrain.ts`（新建）
- `src/models/terrain.test.ts`（新建）

实现步骤：
1. 定义类型：
   ```typescript
   export type MoveCost = number // Infinity 表示不可通行
   export interface TerrainDef {
     id: string
     name: string
     moveCost: { foot: MoveCost; horse: MoveCost; fly: MoveCost }
     def: number
     avo: number
     effect?: 'periodicDamage' | 'none'
     effectNote?: string // 仅文字记录，不执行（龙痕祭坛/王座/废墟等特殊效果）
   }
   export const TERRAIN_DEFS: TerrainDef[] = [ /* 全部 18 条 */ ]
   export const TERRAIN_BY_ID: Record<string, TerrainDef> =
     Object.fromEntries(TERRAIN_DEFS.map(t => [t.id, t]))
   ```
2. 逐条录入 [A/06] 表格中全部 18 种地形（平原/道路/森林/密林/山地/山峰/要塞/村庄/河流/浅滩/桥/沙地/毒沼/火山岩/废墟/龙痕祭坛/王座/断崖），数值严格按表格拄（不要只抄正文的“约 15 种”结论而漏掉剩余）。不可通行用 `Infinity` 表示（如河流对步/骑，断崖对步/骑）。
3. 只有毒沼、火山岩两种的 `effect` 写 `'periodicDamage'`；其余有文字描述但无执行逻辑的地形（山峰视野/废墟遮挡/龙痕祭坛增益/王座回血/断崖坠落）写 `effect: 'none'` + `effectNote` 文字说明，**不要**写会被调用却什么都不做的占位函数。
4. 测试断言：`TERRAIN_DEFS.length === 18`；逐条根据 id 查 `TERRAIN_BY_ID` 断言 `moveCost`/`def`/`avo` 与设计蓝图表格完全一致（至少对平原/森林/河流/断崖/毒沼这 5 种具代表性地形写明确数值断言，其余 13 种至少断言存在且字段完整）。

验证命令：`npx --no-install tsx --test src/models/terrain.test.ts` → exit code 0。

提交：`git add src/models/terrain.ts src/models/terrain.test.ts && git commit -m "feat: P1-T2 - 添加 18 种地形数据模块"`。

---

## P1-T3 武器/魔法相克矩阵与 COMBAT 参数表

Files：
- `src/models/weapons.ts`（新建）
- `src/models/weapons.test.ts`（新建）

实现步骤：
1. 定义：
   ```typescript
   export type WeaponType = 'sword' | 'axe' | 'lance' | 'bow'
   export type MagicType = 'fire' | 'ice' | 'thunder'
   export interface WeaponDef {
     id: string; type: WeaponType
     might: number; hit: number; crit: number
     minRange: number; maxRange: number // 弓=1..2，其余近战=1..1
     antiAirBonus?: boolean // 对空特攻标记，用于 P1-T4 单位标签匹配
   }
   export const WEAPON_TRIANGLE: Record<WeaponType, Partial<Record<WeaponType, number>>> = {
     sword: { axe: 1, lance: -1 },
     axe:   { lance: 1, sword: -1 },
     lance: { sword: 1, axe: -1 },
     bow: {},
   }
   export const MAGIC_TRIANGLE: Record<MagicType, Partial<Record<MagicType, number>>> = {
     fire: { ice: 1, thunder: -1 },
     ice: { thunder: 1, fire: -1 },
     thunder: { fire: 1, ice: -1 },
   }
   export const COMBAT = {
     minDamage: 1, counterHit: 15, counterMight: 1,
     doublingThreshold: 4, critFromSkill: 0.5, doubleRNG: true, effMultiplier: 3,
   } as const
   export const WEAPON_DEFS: WeaponDef[] = [ /* 剑/斧/枪/弓各一件，数值抄 [A/03] 示例中的具体数值 */ ]
   ```
2. `WEAPON_TRIANGLE`/`MAGIC_TRIANGLE` 的正数表示“克制时获得的加成/命中加成”，负数表示被克制时的惩罚，数值大小必须与 [A/03] 正文描述一致（剑克斧/斧克枪/枪克剑，循环）。
3. `bow` 不进入任何三角关系（空表对象），但其 `minRange:1, maxRange:2` 必须正确——这是验证“1–2 射程”规则的唱一数据锥。
4. 测试断言：对 `WEAPON_TRIANGLE` 与 `MAGIC_TRIANGLE` 分别写一个通用断言函数，对每个类型把它对其他所有类型的优势值求和（缺失键视为 0），断言总和为 0；`COMBAT.minDamage === 1`、`COMBAT.doublingThreshold === 4`等关键常量与 [A/03]/[E/22] 文本一致。

验证命令：`npx --no-install tsx --test src/models/weapons.test.ts` → exit code 0。

提交：`git add src/models/weapons.ts src/models/weapons.test.ts && git commit -m "feat: P1-T3 - 添加武器相克矩阵与 COMBAT 参数��"`。

---

## P1-T4 单位数据模块（步/骑/飞）

Files：
- `src/models/units.ts`（新建）
- `src/models/units.test.ts`（新建）

实现步骤：
1. 定义：
   ```typescript
   export type MoveType = 'foot' | 'horse' | 'fly'
   export interface Stats {
     hp: number; str: number; mag: number; skl: number
     spd: number; lck: number; def: number; res: number; mov: number
   }
   export interface GrowthRates extends Record<keyof Stats, number> {} // 百分比，本阶段不参与计算，仅声明
   export interface UnitDef {
     id: string; name: string; moveType: MoveType
     base: Stats; growth: GrowthRates
     tags: string[] // 特攻标签匹配用，如 'flying'
   }
   export const UNIT_DEFS: UnitDef[] = [ /* infantry / cavalry / flier 各一条 */ ]
   ```
2. 三个单位的 `base` 属性数值直接抄 [A/04] 给出的具体数值区间取中间代表值（不要自己发明数值）；`flier`（飞兵）必须带 `tags: ['flying']`，供 P1-T3 的 `antiAirBonus` 日后在 Phase 2 匹配。
3. `growth` 字段必须存在且类型完整，但本 task 不写任何消费该字段的代码（非目标）。
4. 测试断言：`UNIT_DEFS.length === 3`；每个 `UnitDef` 的 `moveType` 与 id 命名对应（infantry→foot、cavalry→horse、flier→fly）；`flier` 包含 `'flying'` tag；所有 `base`/`growth` 字段均为有限数字（`Number.isFinite`）。

验证命令：`npx --no-install tsx --test src/models/units.test.ts` → exit code 0。

提交：`git add src/models/units.ts src/models/units.test.ts && git commit -m "feat: P1-T4 - 添加步/骑/飞单位数据模块"`。

---

## P1-T5 可达域计算服务（Dijkstra）

Files：
- `src/services/reachable.ts`（新建）
- `src/services/reachable.test.ts`（新建）

实现步骤：
1. 定义输入：`grid: TerrainDef[][]`（从 `@models/terrain` 导入类型）、`start: {x:number;y:number}`、`moveType: MoveType`（从 `@models/units` 导入）、`movePower: number`。
2. 实现标准 Dijkstra（四方向相邻，不对角）：从 `start` 出发，累加目标格 `terrain.moveCost[moveType]`，若累加代价 > `movePower` 则不可达；`moveCost === Infinity` 的格子无论代价均不可通行且不可穿越。返回 `Set<string>`（`"x,y"` 键）代表可达格。
3. 本 task 不实现路径重建（不返回具体走法），只返回可达格集合——路径重建属于 M2（idea.md 核心需求 6）。
4. 测试用一张 5x5 手写测试网格（中间一列全部设为密林）：断言 `moveType:'foot', movePower:5` 时能绕过密林但不能直接穿越；`moveType:'horse'` 在相同网格下可达格数严格少于 `foot`（骑兵进密林代价更高，[A/06]）；`moveType:'fly'` 能直接穿越密林列。

验证命令：`npx --no-install tsx --test src/services/reachable.test.ts` → exit code 0。

提交：`git add src/services/reachable.ts src/services/reachable.test.ts && git commit -m "feat: P1-T5 - 实现基于 Dijkstra 的可达域计算服务"`。

---

## P1-T6 跨模块数据引用完整性单测

Files：
- `src/models/dataIntegrity.test.ts`（新建）

实现步骤：
1. 本 task 不新增任何运行时校验代码，只写单测（idea.md 核心需求 8：TS 联合类型已提供编译期安全，本 task 补充编译期无法捕获的跨模块一致性）。
2. 断言：每个 `UNIT_DEFS[i].tags` 中若含 `'flying'`，则对应 `moveType` 必须为 `'fly'`（交叉校验 units 内部一致性）。
3. 断言：`WEAPON_DEFS` 中每一件武器的 `type` 都在 `WEAPON_TRIANGLE` 的 key 集合中（包含 `bow`，即使它没有克制关系）。
4. 断言：`TERRAIN_DEFS` 中每一项的 `moveCost.foot/horse/fly` 都是 `>= 1` 或 `=== Infinity`（不允许出现 0 或负数这类无意义数值）。
5. 本 task 目的是在三个数据模块写好之后做一次交叉安全网，不是引入新的运行时概念。

验证命令：`npx --no-install tsx --test src/models/dataIntegrity.test.ts` → exit code 0。

提交：`git add src/models/dataIntegrity.test.ts && git commit -m "test: P1-T6 - 添加跨模块数据引用完整性单测"`。

---

## P1-T7 运行时战斗状态模型 BattleState/UnitInstance

Files：
- `src/models/battleState.ts`（新建）
- `src/models/battleState.test.ts`（新建）

实现步骤：
1. 定义纯类型（无函数/无行为）：
   ```typescript
   export type Faction = 'player' | 'enemy'
   export type BattlePhase = 'deploy' | 'player' | 'enemy' | 'resolve'
   export interface UnitInstance {
     id: string; unitDefId: string; weaponId?: string
     faction: Faction; pos: { x: number; y: number }
     hp: number; hpMax: number
   }
   export interface BattleState {
     gridWidth: number; gridHeight: number
     grid: string[][]        // grid[y][x] = 地形 id（字符串），行优先
     units: UnitInstance[]
     phase: BattlePhase
     rngState: number         // 与 [E/20] PRNG 服务的 state 同型
     turnCount: number
   }
   ```
2. 本 task 只交付类型定义，不实现任何状态转换/回合推进函数（那是“状态机行为”，属于 Phase 3 范围，见本文档 Non-goals）；不要顺手写 `createBattleState`/`advancePhase` 等函数。
3. 严禁 `import` 任何 `src/services/*` 内容（哪怕是 type-only import）——`rngState` 字段直接用 `number`，不要引用 `@services/prng` 的 `PrngState` 类型别名。
4. 测试断言：用 `fs.readFileSync` 读 `battleState.ts` 源码字符串，断言其中不包含 `from '@services` 或 `from '../services` 子串；再构造一个符合类型的最小 `BattleState` 字面量对象（TS 编译期类型检查即可，无需运行时校验函数）确认类型可用。

验证命令：`npx --no-install tsx --test src/models/battleState.test.ts` → exit code 0。

提交：`git add src/models/battleState.ts src/models/battleState.test.ts && git commit -m "feat: P1-T7 - 添加运行时战斗状态模型 BattleState/UnitInstance"`。

---

## P1-T8 更新根 AGENTS.md 记录 M1 Phase1 新增模块

Files：
- `AGENTS.md`（修改，不是 `.github/features/**` 下的计划文件，需要提交）

实现步骤：
1. 在根 `AGENTS.md`末尾新增一节 `## M1 Phase 1 新增模块`，列出：
   - `src/models/terrain.ts` / `weapons.ts` / `units.ts`：纯数据常量模块，无行为，数值来源于设计蓝图 A/03、A/04、A/06。
   - `src/models/battleState.ts`：运行时战斗状态纯类型定义（`BattleState`/`UnitInstance`），无行为代码，供 M2+ 消费。
   - `src/services/prng.ts`：可注入种子 PRNG，战斗/平衡 CLI 必须通过它取随机数，禁止 `Math.random`。
   - `src/services/reachable.ts`：可达域计算，不含路径重建。
   - 明确标注：本阶段数据是 `.ts` 常量模块而非 `.json` 运行时文件（及其原因简要一句话）。
2. 不要删改 M0 已写入的分层/别名/测试命令章节，只追加。
3. 验证：人工 `cat AGENTS.md` 确认新小节存在且未破坏已有内容（无自动化断言，因为这是文档变更，不是代码行为）。

验证命令：`grep -q "M1 Phase 1" AGENTS.md && echo OK`。

提交：`git add AGENTS.md && git commit -m "docs: P1-T8 - 记录 M1 Phase1 新增模块"`。

---

## Phase 1 完成后的审计约定（audit-p1.md）

Phase 1 全部 8 个 task 完成并提交后，必须进入 `audit-p1.md` 审计闭环，重点检查：
- 18 种地形数值是否逐条与 [A/06] 表格比对无误（不是只抽查了少数几条）。
- 武器/魔法三角的方向性（剑克斧而非斧克剑）与 [A/03] 一致。
- `src/models/*` 确实无任何行为代码（无函数调用副作用，只有常量导出），`src/services/*` 确实未引用 Phaser 或 DOM。
- 确认没有任何文件误引入了本阶段明确禁止的内容（技能/转职/存档/AI）。
- 重跑 `npx tsc --noEmit`、`npx --no-install tsx --test`、`bash scripts/gate.sh` 三者均通过。
审计通过后才能开始规划 Phase 2（`plan-p2.md`：战斗结算服务）。
