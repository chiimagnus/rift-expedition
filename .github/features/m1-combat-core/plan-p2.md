# plan-p2.md — M1 战斗核心 · Phase 2（战斗结算服务）

> 本文档只写实施细节，不重复需求背景——需求真源见 `idea.md`（核心需求 3/4）。
> 数值锚点全部来自设计蓝图 A/03《战斗与相克》，禁止自行推导。
> 已经结合 M1 P1 全部源码（weapons/units/terrain/battleState/prng/reachable）与根 AGENTS.md 审核；审核发现的问题已写入各 task 与末尾「开放问题」节。

Goal：在 Phase 1 已交付的静态数据（terrain/weapons/units）与 PRNG 服务之上，实现 A/03 的**完整战斗结算**：物理/魔法伤害、相克、特攻、命中（双 RNG）、暴击（仅命中率与事件标记）、攻速与追击、六步确定性结算顺序。交付一个纯逻辑、可在 node 下单测、不依赖 Phaser 的 `src/services/combat.ts`。

Non-goals：
- 不写平衡模拟 CLI、AI、循环赛统计（Phase 3）。
- 不写 `BattleState` 的回合推进/阶段切换等状态机行为（Phase 3）。
- 不实现技能/被动/羁绊/龙痕的具体效果。**而且：不写“会被调用却什么都不做”的 no-op 占位函数**（idea.md 核心需求 1，已在 `terrain.ts` 强制；tsconfig `noUnusedParameters:true` 也会直接报错）——第 5 步仅用代码注释标明未来挂载点，不落为可调用空函数。
- 不实现连击武器（brave）——idea.md 核心需求未列入。
- 不实现武器重量/体格（con）数据字段——现有 `WeaponDef`/`Stats`（已核实源码）刻意未含这两个字段。攻速公式按“重量=0、体格=0”退化为 `攻速=速度`（A/03 三个演算示例正是这么算），公式保留 weight/con 形参但**不新增任何数据字段**（避免死字段）。真正的重武器压攻速待 M3 引入重甲/法师、确有重量数据时再补。
- **不做逐回合地形扣血（periodicDamage 实际扣血）**——A/03 边界规则明确地形/回血属“回合开始/回合结算段”（第 6 步之外），且需要遍历场上单位与网格（属 M2/回合结算）。本阶段的 combat.ts 只管单次“一次交锈”。
- 不碰 `src/ui`/`src/viewmodels`/`src/entrypoints`。

Approach：
- combat 服务是 `services` 层，可 `import` `@models/*`（weapons/units/terrain），**禁止反向**，禁止引用 Phaser/DOM（根 AGENTS.md 分层职责）。
- 战斗函数**不直接吃 `UnitInstance` 也不做地形查表**，而是吃“已解析好的参战方描述”`Combatant`（含最终属性、武器/法术、特攻标签、以及调用方从 `TERRAIN_BY_ID` 查好的地形回避数值）。理由：①让单测能精确构造 A/03 三个演算示例的原始数字（示例里的 剑士/法师/将军/弓手/天马 都不是我们的 3 个基础兵种）；②保持 combat 与 terrain 查表解耦（E/22 第二节单一职责）。
- 所有随机（命中/暴击）只经 `@services/prng` 的 `next(state) => [value, newState]`（已核实签名），禁止 `Math.random`（A/03 第七节 + 根 AGENTS.md）。
- 结算结果返回**确定性事件日志 + 新 rngState**，纯函数、无副作用、可复现。

Acceptance（本 phase 相关，摘自 idea.md 验收标准）：
- 复现 A/03 三个演算示例：①物理伤害=17（守方真实处于森林）、命中=88%、可追击；②魔法伤害=20；③特攻伤害=57。
- 双 RNG 命中：固定种子 ≥1000 次，显示 88% 时经验命中率接近 ~97%（统计断言，容差区间 [0.94,0.99]）。
- `npx tsc --noEmit`、`npx --no-install tsx --test 'src/**/*.test.ts'`、`bash scripts/gate.sh` 全绿（exit 0）。
- `git log --oneline` 每个 task 一次原子提交，subject 以稳定 task id 开头。

**Rules（严格遵守根 AGENTS.md）：**
- 不要 `git add`/`git commit` `.github/features/**` 下的规划文件。
- 一个 task 一次原子提交；commit subject `<type>: <task-id> - <中文描述>`（Conventional Commits 前缀 `feat:`/`test:`/`docs:`）。
- **某 task 替换/废弃旧代码必须在同一 task 内直接删除，不得拖到最后清理**（本 phase 具体：P2-T2 删 `src/services/.gitkeep`）。
- Phaser 只走 `vendor/phaser.min.js`（vendor-only，不走 CDN）；本 phase 不碰渲染，无需引用 Phaser。
- 每条数值必须能指向 A/03 具体公式/示例行；不允许“看起来合理”的自编数值。无锚点的数值（如暴击伤害倍率、魔法射程、地形 def 是否减伤）一律列入末尾「开放问题」，不得自行拍板。
- combat 服务顶部必须写 `Goal:`/`Non-goals:`/`错误处理:` 注释头（E/22 第二节）。
- 命中/暴击百分比在取随机前先 `clampPct` 到 `[0,100]`；伤害恒过 `max(1, …)`（`COMBAT.minDamage`）。
- 数值随机一律经 `@services/prng.next`，禁止 `Math.random`。
- 严禁在 `combat.ts` 里做回合循环/AI/状态机/逐回合地形扣血——那是 Phase 3 / M2。
- 测试发现固定用 `npx --no-install tsx --test 'src/**/*.test.ts'`；单 task 开发时可跑单个显式文件（如 `… --test src/services/combat.test.ts`，这是显式文件不是裸目录，安全），但**提交前必跑一次完整 `bash scripts/gate.sh`**。

---

## P2-T1 魔法法术数据 MagicDef + MAGIC_DEFS

Files：
- `src/models/weapons.ts`（修改：新增魔法法术数据）
- `src/models/weapons.test.ts`（修改：追加断言）

背景（已核实源码）：`weapons.ts` 已含 `MagicType='fire'|'ice'|'thunder'` 与 `MAGIC_TRIANGLE`，但无 `MagicDef`/`MAGIC_DEFS`；A/03 演算示例②需要一个「火焰 威7 命95」的法术实例才能复现（魔伤=20）。法术数据并入同一模块，概念内聚。

实现步骤：
1. 在 `weapons.ts` 追加（不改动已有 `WeaponDef`/`WEAPON_DEFS`/`WEAPON_TRIANGLE`/`MAGIC_TRIANGLE`/`COMBAT`）：
   ```typescript
   export interface MagicDef {
     id: string
     type: MagicType
     might: number
     hit: number
     crit: number
     minRange: number
     maxRange: number
   }
   export const MAGIC_DEFS: MagicDef[] = [
     { id: 'fireTome',    type: 'fire',    might: 7, hit: 95, crit: 0, minRange: 1, maxRange: 2 },
     { id: 'iceTome',     type: 'ice',     might: 7, hit: 95, crit: 0, minRange: 1, maxRange: 2 },
     { id: 'thunderTome', type: 'thunder', might: 7, hit: 95, crit: 0, minRange: 1, maxRange: 2 },
   ]
   export const MAGIC_BY_ID: Record<string, MagicDef> = Object.fromEntries(
     MAGIC_DEFS.map((m) => [m.id, m]),
   )
   ```
   - 注释说明：`fireTome might7/hit95` 锚定 A/03 示例②（唯一硬锚点）。
   - `iceTome/thunderTome` A/03 未给具体数值表，按与火焰同档定价（与 P1 对斧/枪的处理一致），待 A/09 平衡模拟（Phase 3）回调。
   - ❗ **开放问题（写入注释）**：魔法射程 `minRange:1,maxRange:2` 是沿用弓的约定，A/03 未明确规定法术射程；待关卡设计（A/07）确认。
2. 测试追加：`MAGIC_DEFS.length === 3`；每件法术 `type` 都是 `MAGIC_TRIANGLE` 的 key；`MAGIC_BY_ID['fireTome'].might === 7 && .hit === 95`（示例②锚点）。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/models/weapons.test.ts` → exit 0。

提交：`git add src/models/weapons.ts src/models/weapons.test.ts && git commit -m "feat: P2-T1 - 添加魔法法术数据 MagicDef/MAGIC_DEFS（火焰锚定示例②）"`。

---

## P2-T2 Combatant 输入类型与伤害计算（物理/魔法/相克/特攻）

Files：
- `src/services/combat.ts`（新建）
- `src/services/combat.test.ts`（新建）
- 删除 `src/services/.gitkeep`（老旧占位，见下）

❗ **同 task 清理旧代码（根 AGENTS.md 硬规则）**：`src/services/.gitkeep` 是建目录占位，但 P1 已向 `src/services/` 加入 `prng.ts`/`reachable.ts`，该占位早已冗余；本 task 新增 `combat.ts` 后它彻底无意义。**在本 task 内 `git rm src/services/.gitkeep`**，不拖到最后。（`src/viewmodels/.gitkeep` 仍保留——viewmodels 目录仍为空，属 M2。）

实现步骤：
1. 文件顶部写可执行规格头注释：
   ```
   // Goal: 给定攻/守参战方（已解析属性+武器/法术+地形回避）产出伤害/命中/暴击/追击/结算结果。
   // Non-goals: 不做动画、不读存档、不做回合循环/AI/状态机（Phase 3）、不做地形查表（调用方解析后传入）、不做逐回合地形扣血。
   // 错误处理: 非法输入（负 hp、未知武器）由调用方保证；本服务对数值一律 clamp/max(1,…)，不抛错。
   ```
2. 定义参战方输入类型（不复用 `UnitInstance`）：
   ```typescript
   import type { Stats } from '@models/units'
   import type { WeaponDef, MagicDef } from '@models/weapons'
   import { WEAPON_TRIANGLE, MAGIC_TRIANGLE, COMBAT } from '@models/weapons'

   export type Armament =
     | { kind: 'physical'; def: WeaponDef }
     | { kind: 'magical'; def: MagicDef }

   export interface Combatant {
     stats: Stats            // 已含最终 str/mag/skl/spd/lck/def/res 等
     armament: Armament
     tags: string[]          // 自身标签，如 'flying'（供对方特攻匹配）
     terrainAvo: number      // 调用方从 TERRAIN_BY_ID 查好的地形回避（仅用于命中计算）
   }
   ```
   - ❗ **关键修正（审核发现 F1）**：**不设 `terrainDef` 字段**。A/03 示例①中斧兵真实站在森林（森林 def=1/avo=20），但伤害计算 `18+5+1+0−7=17` 只减了单位防 7，**并未减地形 def 1**（若减则为 16≠锚点 17）；地形只通过 avo 20 作用于命中。若加 `terrainDef` 且参与减伤，会直接拆毁示例①。因此地形 def 不进伤害公式，也不加死字段。
3. 相克修正（`triangleModifier`，缺失键视为 0）：物理用 `WEAPON_TRIANGLE[atkType]?.[defType] ?? 0`；魔法用 `MAGIC_TRIANGLE`。约定（对齐 A/03 §二 与 COMBAT：“相克/counter”即武器三角克制，非“反击”）：矩阵值 `+1` → `mightDelta=+COMBAT.counterMight`(+1)、`hitDelta=+COMBAT.counterHit`(+15)；`-1` → `-1`/`-15`；`0` → `0`/`0`。物理 vs 魔法、或含 `bow`（空表）时无相克（0/0）。导出 `triangleModifier(attacker, defender) => { mightDelta, hitDelta }`。
4. 特攻：导出 `effectivenessMultiplier(attacker, defender) => number`。规则（A/03）：攻方 `armament.kind==='physical'` 且 `armament.def.antiAirBonus === true` 且守方 `tags` 含 `'flying'` → `COMBAT.effMultiplier`（=3）；否则 1。**特攻不叠乘**：多标签取最高（本阶段仅对空一种，先实现“取最高”的通用写法，返回单一最大倍率）。
5. 伤害（导出 `computeDamage(attacker, defender) => number`）：
   ```
   物理: max(1, (力 + 武威)*eff + 相克威 + 合击/地形(本阶段0) - 敌单位防)
     → eff 乘在 (str+might) 上（A/03 示例③ (12+9)×3−6=57）；相克威不乘 eff（两例均满足）。
     → 仅减 defender.stats.def，不减地形 def（见 F1）。
   魔法: max(1, (魔 + 法威)*eff + 相克 - 敌魔防)   // 减 defender.stats.res；魔法特攻本阶段恒 eff=1
   ```
   - ❗ **开放问题（写入注释 + 本文末尾汇总）**：A/06 地形 `def` 字段（森林1/山地2/山峰3…）在 A/03 战斗公式中未被消费（示例①已证）。地形 def 到底该不该减物理伤害需设计拍板；若置为“该减”则 A/03 示例①需同步修正。本阶段按示例实现（不减），YAGNI；待确认再加。
6. 测试（逐一断言 A/03 示例，忠实复现）：
   - 示例①物理：攻 `{str:18, 铁剑 might5}` vs 守 `{def:7, terrainAvo:20}`（**真实森林 avo**）且剑克斧 → `computeDamage === 17`（证地形 def 不进伤害式）。
   - 示例②魔法：攻 `{mag:16, fireTome might7}` vs 守 `{res:3}` 无相克 → `computeDamage === 20`。
   - 示例③特攻：攻 `{str:12, strongBow might9(antiAirBonus)}` vs 守 `{def:6, tags:['flying']}` → `effectivenessMultiplier === 3` 且 `computeDamage === 57`。
   - `triangleModifier` 剑→斧 = `{mightDelta:1, hitDelta:15}`；斧→剑 = `{mightDelta:-1, hitDelta:-15}`；bow→任意 = `{0,0}`。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/combat.test.ts && git ls-files src/services/.gitkeep`（第二段应无输出，证已删除）。

提交：`git add -A src/services && git commit -m "feat: P2-T2 - 实现 Combatant 与伤害/相克/特攻计算并清理 services/.gitkeep（复现 A03 示例①②③）"`。

---

## P2-T3 命中与暴击（含双 RNG 命中）

Files：
- `src/services/combat.ts`（修改）
- `src/services/combat.test.ts`（修改）

实现步骤：
1. 命中率（显示值，A/03 第四节）：`命中% = 武器/法术命中 + 技巧×2 + 相克命中(±15) + 支援(本阶段0) - (敌速×2 + 敌幸 + 敌地形回避)`。导出 `computeHit(attacker, defender) => number`（返回未 clamp 原始显示命中供断言）；导出 `clampPct(n)=min(100,max(0,n))`。敌地形回避取 `defender.terrainAvo`。
2. 暴击率（A/03）：`暴击% = 武器暴击 + floor(技巧 × COMBAT.critFromSkill) - 敌幸`，导出 `computeCrit`。（`critFromSkill=0.5` 即技巧÷2。）
   - ❗ **开放问题（写入注释 + 末尾汇总）**：A/03 与 `COMBAT` **均未定义暴击伤害倍率**。故 `computeCrit`/后续 `rollCrit` 产出的 crit **仅作为事件标记**（真实数据，供后续 UI 演出/日志消费，非 no-op），**不自行推导×2/×3 伤害倍率**；倍率待 A/09 拍板后再接入。
3. 双 RNG 命中判定：导出 `rollHit(displayedHit, rngState) => [boolean, number]`：
   - 若 `COMBAT.doubleRNG`：经 `@services/prng.next` 连取两次得 r1,r2（注意 `next` 返回 `[value,newState]`，第二次用第一次的 newState），`avg=(r1+r2)/2*100`，命中=`avg < clampPct(displayedHit)`，返回第二次的 state。
   - 否则单 RNG：`r*100 < clampPct(displayedHit)`。
   导出 `rollCrit(displayedCrit, rngState) => [boolean, number]`（单 RNG，A/03 未规定暴击双 RNG）。
4. 测试：
   - 示例①命中：攻 `{skl:12, 铁剑 hit90}` vs 守 `{spd:9, lck:3, terrainAvo:20}` 且剑克斧(+15) → `computeHit === 88`。
   - 双 RNG 统计：`seed(42)` 起，循环 ≥2000 次对 `displayedHit=88` 调 `rollHit`（滚动 state），命中频率落在 `[0.94,0.99]`（理论 ~0.971）。
   - 退化对照：`displayedHit=100`→必命中；`=0`→必不命中。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/combat.test.ts` → exit 0。

提交：`git add src/services/combat.ts src/services/combat.test.ts && git commit -m "feat: P2-T3 - 实现命中/暴击与双 RNG 命中判定（复现示例①命中88%/统计~97%）"`。

---

## P2-T4 攻速与追击判定

Files：
- `src/services/combat.ts`（修改）
- `src/services/combat.test.ts`（修改）

实现步骤：
1. 攻速（A/03，退化实现见本文 Non-goals）：
   ```typescript
   // weight/con 本阶段无数据来源，默认 0 → 攻速 = 速度；形参均在 return 中使用（不触 noUnusedParameters）。
   export function attackSpeed(spd: number, weight = 0, con = 0): number {
     return spd - Math.max(0, weight - con)
   }
   ```
2. 追击：导出 `canDouble(attacker, defender) => boolean` = `attackSpeed(atk.spd) - attackSpeed(def.spd) >= COMBAT.doublingThreshold`（=4）。
3. 测试：示例① atk spd14 vs def spd9 → 差5≥4 → `true`；差3（spd12 vs spd9）→ `false`；差恰4 → `true`。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/combat.test.ts` → exit 0。

提交：`git add src/services/combat.ts src/services/combat.test.ts && git commit -m "feat: P2-T4 - 实现攻速与追击判定（复现示例①差5可追击）"`。

---

## P2-T5 六步确定性结算编排 resolveCombat

Files：
- `src/services/combat.ts`（修改）
- `src/services/combat.test.ts`（修改）

实现步骤：
1. 定义上下文与结果类型：
   ```typescript
   export interface CombatContext {
     attacker: Combatant
     defender: Combatant
     distance: number      // 攻守曼哈顿距离（调用方给出，本服务不查网格）
     rngState: number
   }
   export interface StrikeEvent {
     side: 'attacker' | 'defender'
     hit: boolean; crit: boolean; damage: number   // 未命中 damage=0；crit 仅标记不改伤害（见 P2-T3 开放问题）
     targetHpAfter: number  // 该击作用目标的剩余 hp
   }
   export interface CombatResult {
     events: StrikeEvent[]
     attackerHpAfter: number
     defenderHpAfter: number
     rngState: number
   }
   export function resolveCombat(ctx: CombatContext, atkHp: number, defHp: number): CombatResult
   ```
2. 严格按 A/03 六步顺序（确定性）：
   1) 判定射程：`inRange(armament, distance)`（`minRange<=distance<=maxRange`）。攻方须在射程内才可发起；守方仅当其武器射程覆盖 `distance` 才可反击（不可反击：2 格弓风筝近战、法师贴脸）。
   2) 攻方一击：`rollHit`→命中则 `rollCrit`→`computeDamage`（命中时）。crit 只写入事件标记、**不改伤害**。扣守方 hp（`max(0,…)`）。
   3) 守方反击：若守方存活且射程覆盖 → 同流程反打攻方（反击以守方为“攻”、攻方为“守”套公式，无额外修正）。
   4) 追击：`canDouble` 成立方，若仍存活且（攻方追击需在射程、守方追击需其可反击）→ 再打一次。攻守各自独立判断。
   5) 被动/羁绊/龙痕：**不写任何函数**，仅一行代码注释 `// 第5步：被动/羁绊/龙痕——M3 接入触发源后在此挂载（本阶段无触发源，跳过）` 占位。（❗ F2/F3：不得写 `applyHooks(ctx)` 空函数——既违反 idea 核心需求 1，又因 `noUnusedParameters` 使 tsc 报错。）
   6) 异常/地形结算：本入口不处理逐回合地形扣血（那是回合结算段/M2）；此处仅收口返回 `CombatResult`。
3. 每次扣血后即时判死，死亡方不再进行后续步骤。所有 hp 用 `max(0,…)`。
4. rngState 在每次 `rollHit`/`rollCrit` 后串行推进，最终写回 `result.rngState`。
5. 测试：
   - 示例①对砍（攻 spd14 可追、守近战可反击、distance=1）：固定 seed，断言事件序列含攻方两击（追击）、命中时伤害=17、rngState 前后不同、hp 单调不增。
   - 不可反击：“攻 2 格弓 vs 守近战 min1/max1，distance=2” → 守方无反击事件。
   - 秒杀：示例③特攻 57 对 hpMax 20 天马 → 一击 targetHpAfter=0，无后续。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/combat.test.ts` → exit 0。

提交：`git add src/services/combat.ts src/services/combat.test.ts && git commit -m "feat: P2-T5 - 实现六步确定性结算编排 resolveCombat"`。

---

## P2-T6 战斗边界规则（伤害下限/不可反击/特攻不叠乘/射程对称）

Files：
- `src/services/combat.ts`（修改：如需小幅补充，主要补测试）
- `src/services/combat.test.ts`（修改：追加断言）

❗ **审核发现（F-terrain）：移除原计划的 `applyTerrainTick` helper。** 原草稿拟在本 task 加一个地形逐回合扣血 helper，但 M1 内**无任何调用方**（逐回合扣血属回合结算段，需遍历场上单位/网格，属 M2）→ 会成为 dead code，违反 idea 核心需求 1 与 YAGNI。因此不写；periodicDamage 的实际扣血延后到 M2/回合结算真正消费时再实现。

实现步骤（均为已存在逻辑的边界断言，确保 resolveCombat/computeDamage 健壮）：
1. 伤害下限：`computeDamage` 已用 `max(1,…)`；补测试 力2 武威1 vs 防99 → 伤害=1（`COMBAT.minDamage`）。
2. 特攻不叠乘：`effectivenessMultiplier` 已取最高；补测试（构造假想双标签场景）断言不出现 ×9，只取最高倍率。
3. 不可反击：补测试 `inRange` 对 `min1/max1` 在 distance 2 不可反击；对 `min1/max2`（弓/法术）在 distance 1 与 2 均可反击、distance 3 不可。
4. 测试：上述三项各至少一条断言。

验证命令：`cd /data/rift-expedition && npx --no-install tsx --test src/services/combat.test.ts` → exit 0。

提交：`git add src/services/combat.ts src/services/combat.test.ts && git commit -m "test: P2-T6 - 补齐伤害下限/特攻不叠乘/射程反击边界"`。

---

## P2-T7 更新根 AGENTS.md 记录 M1 Phase 2 模块

Files：
- `AGENTS.md`（修改，需要提交）

实现步骤：
1. 末尾新增一节 `## M1 Phase 2 新增模块`：
   - `src/models/weapons.ts`：新增 `MagicDef`/`MAGIC_DEFS`/`MAGIC_BY_ID`（火焰/冰/雷，火焰锚定 A/03 示例②）。
   - `src/services/combat.ts`：纯战斗结算服务——`Combatant`/`Armament`（**仅 terrainAvo，无 terrainDef**）、伤害（物理/魔法/相克/特攻）、命中（双 RNG）、暴击（仅命中率+事件标记）、攻速/追击、六步 `resolveCombat`；随机只经 `@services/prng`。
   - 明确标注：combat 不做地形查表、不做回合循环/AI/状态机、不做逐回合地形扣血（均属 Phase 3 / M2）。
   - 记一笔开放问题（地形 def 是否减伤、暴击伤害倍率、魔法射程）待设计确认。
2. 不删改已有章节，只追加。

验证命令：`cd /data/rift-expedition && grep -q "M1 Phase 2" AGENTS.md && echo OK`。

提交：`git add AGENTS.md && git commit -m "docs: P2-T7 - 记录 M1 Phase2 战斗结算模块"`。

---

## 开放问题汇总（需设计/用户拍板，不得自行推导）

1. **地形 def 是否减物理伤害？**（F1）A/06 各地形有 `def`（森林1/山地2/山峰3/王座3…），但 A/03 示例①（斧兵在森林）伤害=17 未减地形 def。本阶段按示例实现（地形只给 avo 不给 def 减伤）。若设计意图是地形 def 应减伤，需同步修正 A/03 示例①与本 plan/测试。
2. **暴击伤害倍率？**（F6）A/03 与 COMBAT 未定义。本阶段 crit 仅作事件标记，不改伤害；待 A/09 定值后接入（建议入 COMBAT 可调参表 如 `critMultiplier`）。
3. **魔法射程？**（F8）A/03 未规定；暂沿弓约定 1-2，待 A/07 关卡设计确认。
4. **魔法是否享地形 avo？** 本阶段命中公式对物理/魔法一视同仁减 `terrainAvo`（A/03 命中公式未区分）；若魔法应无视地形回避，待确认。

## Phase 2 完成后的审计约定（audit-p2.md）

Phase 2 全部 task 完成并提交后，进入 `audit-p2.md` 审计闭环，重点检查：
- A/03 三个演算示例（伤 17 / 命 88% / 魔伤 20 / 特攻 57）是否逐一被测试断言复现，且示例①用真实森林 avo=20（而非把 terrainDef 归 0 掩盖问题）。
- 双 RNG 命中统计断言存在且区间合理（~97%）。
- 结算顺序严格六步、死亡即止、不可反击/追击边界正确。
- **第 5 步无任何 no-op 占位函数（仅注释）；无 dead code（无 applyTerrainTick 等无调用方函数）；`combat.ts` 零 `Math.random`、零 Phaser/DOM。**
- **`src/services/.gitkeep` 已在 P2-T2 删除（`git ls-files` 无输出）；无其他向后兼容/双模式旧代码残留。**
- crit 未擅自加伤害倍率；terrain def 未擅自减伤（与开放问题一致）。
- 重跑 `npx tsc --noEmit`、`npx --no-install tsx --test 'src/**/*.test.ts'`、`bash scripts/gate.sh` 均 exit 0。
审计通过后才能开始 Phase 3（`plan-p3.md`）。
