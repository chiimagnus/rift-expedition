# plan-p1.md — M3 Act 1 · Phase 1（羁绊/存档基础设施 + 第 1 章可玩内容）

> 本文档只写实施细节，不重复需求背景——需求真源见 `idea.md`。

Goal：交付 M3 第一个可玩垂直切片——第 1 章「边境遭遇」可从开场打到胜利/失败，并搭好它依赖的四项基础设施：`BattleState` 字段扩展、`SaveGame` 持久化（含永久死亡）、羁绊值结算、转职服务。本阶段只需覆盖第 1 章实际登场的 4 名角色（奥德里克、瓦伦丁、圣殿卫队长、少年弓手）。

Non-goals：不做第 2–8 章内容（后续 Phase）；不做剩余 8 名角色数据（后续 Phase 按登场章节补齐）；不做完整转职树（只做本阶段用到的枪骑→圣骑士一条路径）；不做合击技的战斗内数值效果（只做羁绊值累计与阈值判定）；不做龙化效果/真结局判定（只做 `dragonTaint` 字段本身）；不做完整分支交互 UI（只做最小 `flags` 读写）。

Approach：在不破坏 M1/M2 已交付字段语义的前提下，对 `src/models/battleState.ts` 做向后兼容的字段新增；新增的剧情/角色/章节数据仍用 M1 建立的 `.ts` 常量模块形式；新增服务（bonds/promotion/saveGameStore）严格遵守分层：只 `import` `src/models/*`，不反向依赖。

Acceptance：见 `idea.md` 验收标准中与本 phase 相关的条目（第 1 章可通关、四名角色数据完整、转职服务可用、羁绊累计可用、永久死亡可用）；剩余轮库/章节属后续 Phase。

**前置确认（执行者开工前必做）**：
- 确认 M1 P1-T7 `src/models/battleState.ts` 已存在且字段为 `gridWidth/gridHeight/grid/units/phase/rngState/turnCount`；`UnitInstance` 已存在 `id/unitDefId/weaponId?/faction/pos/hp/hpMax`。若字段名与本文档假设不符，先更新本文档再继续。
- 确认 M2 实际代码交付状态（`src/viewmodels/`、`src/ui/` 实际目录命名），本文档 P1-T7 中的目录/类名只是基于 M2 `plan-p1.md` 描述的推测约定，若与 M2 实际交付目录不一致，以实际代码为准并相应调整。

**Rules:**
- 不要 `git add`/`git commit` `.github/features/**` 下的规划文件。
- 一个 task 一次原子提交，commit subject 以稳定 task id 开头。
- 修改 `src/models/battleState.ts` 只能新增字段，不得改名/删除/改变类型 M1/M2 已依赖的现有字段。
- 所有新增服务文件严禁直接操作 DOM/Phaser（那是 `src/viewmodels`/`src/ui` 层的事）。
- 剧情文本、角色人设严格按 [B/11]/[B/12] 原文，不自行发挥。

---

## P1-T1 扩展 BattleState（bonds/dragonTaint/flags + UnitInstance.alive）

Files：
- `src/models/battleState.ts`（修改）
- `src/models/battleState.test.ts`（修改/新增断言）

实现步骤：
1. 在 `UnitInstance` 新增字段 `alive: boolean`（不删改已有字段）。
2. 在 `BattleState` 新增字段：
   ```typescript
   export type BondPairId = string // 约定格式 `${unitIdA}:${unitIdB}`，小字典序排列保证唯一性
   export interface BattleStateExtras {
     bonds: Record<BondPairId, number>
     dragonTaint: Record<string, number> // key = unitId
     flags: Record<string, number | boolean>
   }
   ```
   直接将 `bonds`/`dragonTaint`/`flags` 三个字段平铺加入 `BattleState` interface 本体（不单独保留 `BattleStateExtras` 作为独立类型，避免多一层组合增加调用方复杂度）。
3. 在文件头部注释标注：`// [M3 P1-T1] 新增 bonds/dragonTaint/flags 字段，向后兼容扩展，见 M3 idea.md 核心需求 4/7/8`。
4. 回归验证：重跑 M1/M2 已有的 `battleState.test.ts`/消费方单测，确保它们在新字段加入后仍全部通过（旧测试构造的 `BattleState` 字面量需要补充新必填字段，否则 TS 编译不过）。
5. 新增断言：构造一个最小 `BattleState` 字面量，包含空 对象 `bonds:{}`、`dragonTaint:{}`、`flags:{}`，`UnitInstance` 含 `alive:true`，TS 编译通过即为通过。

验证命令：`npx --no-install tsx --test src/models/battleState.test.ts` → exit code 0；`npx tsc --noEmit` 确认全仓库无新增类型错误。

提交：`git add src/models/battleState.ts src/models/battleState.test.ts && git commit -m "feat: P1-T1 - 扩展 BattleState 支持羁绊/龙化/剧情标记"`。

---

## P1-T2 SaveGame 模型与持久化服务（含永久死亡 fallen 列表）

Files：
- `src/models/saveGame.ts`（新建）
- `src/services/saveGameStore.ts`（新建）
- `src/services/saveGameStore.test.ts`（新建）

实现步骤：
1. 在 `src/models/saveGame.ts` 定义纯类型（不 import services）：
   ```typescript
   export interface RosterEntry {
     unitId: string; characterId: string; classId: string
   }
   export interface SaveGame {
     version: number
     chapter: string
     roster: RosterEntry[]
     fallen: string[]         // 永久阵亡角色 id 列表
     bonds: Record<string, number>
     taint: Record<string, number>
     flags: Record<string, number | boolean>
     mode: 'classic' | 'casual'
     seed: number
     savedAt: number
   }
   export const SAVE_GAME_VERSION = 1
   ```
2. 在 `src/services/saveGameStore.ts` 实现 `save(game: SaveGame): void`（写 `localStorage`，key 用固定常量 `'tst:save:v1'`）、`load(): SaveGame | null`（读取并做 `version` 校验，`version` 不匹配时返回 `null` 而不是抛错或强行解析——为后续版本迁移留口子，本阶段不实现迁移逻辑本身）、`addFallen(game: SaveGame, unitId: string): SaveGame`（返回新对象，若已存在则不重复添加，纯函数不做原地修改）。
3. **不要**依赖或修改 M2 可能已交付的旧版最小快照存档（若 M2 已实现，二者是不同 key/不同数据形状，本 task 的 `SaveGameStore` 是本 feature 引入的正式存档系统，用于章节间持久化；M2 的快照若仅用于战斗内单局调试可继续保留，不要求本 task 删除它——如确认功能重叠废弃，需要在本 task 内一并清理旧实现并说明原因，而不是留到最后再清）。
4. 测试断言：`save` 后 `load` 能还原全部字段（含 `fallen` 数组、`bonds`/`taint`/`flags` 对象内容）；`addFallen` 对同一 `unitId` 调用两次，`fallen.length` 仍为 1（幂等）；`load` 在 `localStorage` 为空时返回 `null`；手工写入一个 `version: 999` 的假数据，`load` 返回 `null`（不崩溃）。

验证命令：`npx --no-install tsx --test src/services/saveGameStore.test.ts` → exit code 0。

提交：`git add src/models/saveGame.ts src/services/saveGameStore.ts src/services/saveGameStore.test.ts && git commit -m "feat: P1-T2 - 添加 SaveGame 模型与持久化服务"`。

---

## P1-T3 羁绊值结算服务（每回合累计 + C/B/A/S 阈值判定）

Files：
- `src/services/bonds.ts`（新建）
- `src/services/bonds.test.ts`（新建）

实现步骤：
1. 定义：
   ```typescript
   export const BOND_THRESHOLDS = { C: 0, B: 40, A: 100, S: 180 } as const
   export type BondTier = 'none' | 'C' | 'B' | 'A' | 'S'
   export function pairKey(unitIdA: string, unitIdB: string): string {
     return [unitIdA, unitIdB].sort().join(':')
   }
   export function tierForValue(value: number): BondTier {
     if (value >= BOND_THRESHOLDS.S) return 'S'
     if (value >= BOND_THRESHOLDS.A) return 'A'
     if (value >= BOND_THRESHOLDS.B) return 'B'
     if (value > BOND_THRESHOLDS.C) return 'C'
     return 'none'
   }
   export interface TurnBondEvents {
     adjacentAlivePairs: Array<[string, string]>  // 本回合结束时相邻且均存活的单位对
     healOrBuffPairs: Array<[string, string]>     // 一方对另一方治疗/增益
     comboPairs: Array<[string, string]>          // 合击/援护触发
     sameSameTargetKillPairs: Array<[string, string]> // 同回合击杀同一目标
   }
   export function accumulateBonds(
     bonds: Record<string, number>,
     events: TurnBondEvents,
   ): Record<string, number> {
     const next = { ...bonds }
     const add = (pairs: Array<[string, string]>, amount: number) => {
       for (const [a, b] of pairs) {
         const key = pairKey(a, b)
         next[key] = (next[key] ?? 0) + amount
       }
     }
     add(events.adjacentAlivePairs, 3)
     add(events.healOrBuffPairs, 5)
     add(events.comboPairs, 5)
     add(events.sameSameTargetKillPairs, 2)
     return next
   }
   ```
2. 本 task **不负责**从 `BattleState` 里自动推导 `TurnBondEvents`（例如自动计算网格相邻关系）——那属于消费方（战斗结算服务/ViewModel）在回合结束时组装事件对象后调用本服务，本服务只做纯粹的累计与分级判定。这样可以保持本服务无需 `import` `reachable`/`battleState` 之外的任何战斗上下文类型。
3. 测试断言：`accumulateBonds` 对同一对多次调用值正确累加；`pairKey('a','b') === pairKey('b','a')`（无序性）；`tierForValue` 在 0/39/40/99/100/179/180 等边界值上返回正确档位（边界值全部覆盖，不只测中间值）。

验证命令：`npx --no-install tsx --test src/services/bonds.test.ts` → exit code 0。

提交：`git add src/services/bonds.ts src/services/bonds.test.ts && git commit -m "feat: P1-T3 - 实现羁绊值累计与等级判定服务"`。

---

## P1-T4 转职服务与首批职业数据（枪骑→圣骑士）

Files：
- `src/models/classes.ts`（新建）
- `src/services/promotion.ts`（新建）
- `src/services/promotion.test.ts`（新建）

实现步骤：
1. `src/models/classes.ts` 定义（对应 [A/04] 四节转职树，本阶段只收录本 phase 用得到的节点，其余 ~35 个职业节点留给后续 Phase 按角色登场批次补充）：
   ```typescript
   export interface ClassDef {
     id: string; name: string; moveType: 'foot' | 'horse' | 'fly'
     promotesTo?: string[]  // 可转职到的 ClassDef id 列表
     statBonus: Partial<Record<keyof import('./units').Stats, number>> // 转职即时加成
   }
   export const CLASS_DEFS: ClassDef[] = [
     { id: 'lancer', name: '枪骑', moveType: 'horse', promotesTo: ['paladin'], statBonus: {} },
     { id: 'paladin', name: '圣骑士', moveType: 'horse', statBonus: { hp: 3, def: 2, mov: 1 } },
   ]
   export const CLASS_BY_ID: Record<string, ClassDef> = Object.fromEntries(CLASS_DEFS.map(c => [c.id, c]))
   ```
   `statBonus` 数值为占位保守值，后续内容批量阶段（[F/23]）按 [A/04] 精确数值表逐条核对修正。
2. `src/services/promotion.ts` 实现：
   ```typescript
   export function canPromote(currentClassId: string, targetClassId: string): boolean {
     const cur = CLASS_BY_ID[currentClassId]
     return !!cur?.promotesTo?.includes(targetClassId)
   }
   export function applyPromotion(unit: UnitInstance, targetClassId: string): UnitInstance {
     if (!canPromote(unit.classId ?? '', targetClassId)) {
       throw new Error(`invalid promotion: ${unit.classId} -> ${targetClassId}`)
     }
     // 返回新对象，不原地修改；stats 加成部分本 task 只做占位说明，
     // 因为 UnitInstance（M1 P1-T7）本身不含完整 Stats 字段（只有 hp/hpMax），
     // 完整属性加成的落地依赖后续把 UnitInstance 与 Stats 打通的任务，本 task 只验证 classId 切换与非法转职拦截。
     return { ...unit, classId: targetClassId }
   }
   ```
   **注意**：`UnitInstance`（M1 交付）当前没有 `classId` 字段——本 task 需要在 `battleState.ts` 里补一个可选字段 `classId?: string`（视为 P1-T1 遗漏的一个必要字段，若 P1-T1 尚未提交，合并进 P1-T1 一并做；若已提交，作为本 task 的一个前置小修订单独一次 commit）。
3. 测试断言：`canPromote('lancer','paladin') === true`；`canPromote('lancer','sage') === false`；`applyPromotion` 对合法转职返回 `classId` 更新后的新对象且不修改原对象（浅比较原对象字段不变）；对非法转职抛出异常。

验证命令：`npx --no-install tsx --test src/services/promotion.test.ts` → exit code 0。

提交：`git add src/models/classes.ts src/services/promotion.ts src/services/promotion.test.ts && git commit -m "feat: P1-T4 - 实现转职服务与枪骑/圣骑士职业数据"`。

---

## P1-T5 第 1 章数据模块（边境遭遇：地图/敌方/胜负条件）

Files：
- `src/models/chapters/chapter01.ts`（新建）
- `src/models/chapters/chapter01.test.ts`（新建）

实现步骤：
1. 定义：
   ```typescript
   export interface ChapterDef {
     id: string; title: string
     gridWidth: number; gridHeight: number
     terrainGrid: string[][]        // 值为 TERRAIN_BY_ID 的 id
     playerStartPositions: Record<string, { x: number; y: number }> // key = characterId
     enemyUnits: Array<{ unitDefId: string; pos: { x: number; y: number } }>
     victoryCondition: 'routEnemies' | 'seizeThrone' | 'surviveTurns'
     defeatCondition: 'allPlayerUnitsDead' | 'protagonistDead'
     introText: string
     outroText: string
   }
   export const CHAPTER_01: ChapterDef = { /* ... */ }
   ```
2. `terrainGrid` 用一张小型（建议 8x6 或类似规模）地图，地形取自 [A/06]/M1 `TERRAIN_DEFS` 已有 id（不要发明新地形 id），体现"边境"场景（平原为主、少量森林/河流制造地形博弈）。
3. `enemyUnits` 复用 M1 `UNIT_DEFS` 里的 `infantry`（步兵）作为"蛮族"敌方泛用单位外观占位（本阶段不新增蛮族专属 UnitDef，理由：[B/11] 第 1 章的"蛮族"只是战术教学用途的通用敌人，无独立人设/剧情分量，不值得为此新增数据类型，YAGNI），`victoryCondition: 'routEnemies'`（歼灭全部敌人），`defeatCondition: 'protagonistDead'`（奥德里克阵亡即失败——主角保护是本作贯穿设定）。
4. `introText`/`outroText` 内容需与 [B/11] 第 1 章一句话纲要"兄阵营劏蛮族，初遇妹（不知情）"一致：开场白交代奥德里克所在索雷因边境巡逻队遭遇袭击；结尾白暗示远处有一名陌生的诺德海姆战士（艾拉菈）目睹了战斗但未直接介入，为第 4 章双线切换埋伏笔。**不要**在本章文本里让两人正式碰面或对话——[B/11] 明确"初遇不知情"，直接互动要到第 7 章。
5. 测试断言：`terrainGrid` 的行列数与 `gridWidth`/`gridHeight` 一致；`playerStartPositions`/`enemyUnits` 中的坐标均落在网格范围内；`enemyUnits.length >= 1`。

验证命令：`npx --no-install tsx --test src/models/chapters/chapter01.test.ts` → exit code 0。

提交：`git add src/models/chapters/chapter01.ts src/models/chapters/chapter01.test.ts && git commit -m "feat: P1-T5 - 添加第1章边境遭遇数据模块"`。

---

## P1-T6 首批 4 名角色数据（奥德里克/瓦伦丁/圣殿卫队长/少年弓手）

Files：
- `src/models/characters.ts`（新建）
- `src/models/characters.test.ts`（新建）

实现步骤：
1. 定义：
   ```typescript
   export interface CharacterDef {
     id: string; name: string; faction: 'sorraine' | 'nordheim' | 'church' | 'neutral'
     startingClassId: string
     base: Stats; growth: GrowthRates   // 复用 @models/units 的 Stats/GrowthRates 类型
     tags: string[]
     joinsChapter: number
   }
   export const CHARACTER_DEFS: CharacterDef[] = [
     { id: 'aldric', name: '奥德里克', faction: 'sorraine', startingClassId: 'dragonbornSword', /* ... */ joinsChapter: 1 },
     { id: 'valentine', name: '瓦伦丁', faction: 'sorraine', startingClassId: 'lancer', /* ... */ joinsChapter: 1 },
     { id: 'templarCaptain', name: '圣殿卫队长', faction: 'sorraine', startingClassId: 'armor', /* ... */ joinsChapter: 1 },
     { id: 'youngArcher', name: '少年弓手', faction: 'sorraine', startingClassId: 'archer', /* ... */ joinsChapter: 1 },
   ]
   ```
2. `startingClassId` 中 `dragonbornSword`/`armor`/`archer` 目前不在 `src/models/classes.ts`（P1-T4 只建了 `lancer`/`paladin`）——本 task 需要把这三个基础职业节点也补进 `CLASS_DEFS`（`dragonbornSword` 无 `promotesTo`，标注注释"高级转职龙王/圣痕使留待后续 Phase，需觉醒剧情前置条件"；`armor`/`archer` 同理留空 `promotesTo`）。
3. 属性数值参考 [A/04] 二/三节区间与职业基准成长率（龙裔主角组用 [A/04] 表格最后一行"龙裔主角"基准，其余三人对照对应职业基准行），不要凭感觉估算。
4. 测试断言：`CHARACTER_DEFS.length === 4`；每条记录的 `startingClassId` 都能在 `CLASS_BY_ID` 中查到；`joinsChapter === 1`（本批次全部第 1 章登场）；`base`/`growth` 字段全部为有限数字。

验证命令：`npx --no-install tsx --test src/models/characters.test.ts` → exit code 0。

提交：`git add src/models/characters.ts src/models/characters.test.ts src/models/classes.ts && git commit -m "feat: P1-T6 - 添加首批4名角色数据"`。

---

## P1-T7 最小过场/对话文本呈现（DialogueViewModel + 场景接线）

Files：
- `src/viewmodels/DialogueViewModel.ts`（新建，若 M2 已交付不同的 viewmodels 目录结构，路径按实际调整）
- `src/viewmodels/DialogueViewModel.test.ts`（新建）

实现步骤：
1. 实现一个不依赖 Phaser 的纯 ViewModel：
   ```typescript
   export interface DialogueLine { text: string }
   export class DialogueViewModel {
     private lines: DialogueLine[]
     private index = 0
     constructor(lines: DialogueLine[]) { this.lines = lines }
     current(): DialogueLine | null { return this.lines[this.index] ?? null }
     advance(): boolean {
       if (this.index >= this.lines.length - 1) return false
       this.index += 1
       return true
     }
     isFinished(): boolean { return this.index >= this.lines.length - 1 }
   }
   ```
2. 本 task 只做"整段文本按行推进"的最小能力，用于呈现 `chapter01.ts` 的 `introText`/`outroText`（每段可以按句号/换行切成多条 `DialogueLine`）——**不实现**分支选择、变量插值、打字机效果，那些留给后续 Phase 按需加。
3. 场景接线（`src/ui`/`src/entrypoints` 层的实际 Phaser 渲染代码）本 task **不实现**——依赖 M2 已交付的场景注入模式，若本 task 执行时 M2 尚未编码完成实际的 `BattleScene`/`UIScene`，本 task 到 `DialogueViewModel` 为止即完成，场景接线留到 M3 的下一个 Phase（待 M2 编码完成后再排期）。
4. 测试断言：3 行文本的 `DialogueViewModel`，初始 `current()` 返回第 1 行；连续 `advance()` 两次后 `isFinished() === true` 且第三次 `advance()` 返回 `false`（到底后不再前进）。

验证命令：`npx --no-install tsx --test src/viewmodels/DialogueViewModel.test.ts` → exit code 0。

提交：`git add src/viewmodels/DialogueViewModel.ts src/viewmodels/DialogueViewModel.test.ts && git commit -m "feat: P1-T7 - 实现最小对话文本推进 ViewModel"`。

---

## P1-T8 更新根 AGENTS.md 记录 M3 Phase1 新增模块

Files：
- `AGENTS.md`（修改）

实现步骤：
1. 在根 `AGENTS.md` 末尾新增一节 `## M3 Phase 1 新增模块`，列出本 phase 新增/修改的模块：`battleState.ts`（字段扩展）、`saveGame.ts`/`saveGameStore.ts`、`bonds.ts`、`classes.ts`/`promotion.ts`、`chapters/chapter01.ts`、`characters.ts`、`DialogueViewModel.ts`，并注明各自所属分层。
2. 不要删改此前 M0/M1/M2 已写入的章节，只追加。
3. 验证：人工 `cat AGENTS.md` 确认新小节存在。

验证命令：`grep -q "M3 Phase 1" AGENTS.md && echo OK`。

提交：`git add AGENTS.md && git commit -m "docs: P1-T8 - 记录 M3 Phase1 新增模块"`。

---

## Phase 1 完成后的审计约定（audit-p1.md）

Phase 1 全部 8 个 task 完成并提交后，进入 `audit-p1.md` 审计闭环，重点检查：
- `BattleState`/`UnitInstance` 字段扩展未破坏 M1/M2 现有测试与调用方（回归测试全过）。
- 角色属性/成长率数值与 [A/04] 表格逐条核对（不是抽查）。
- 第 1 章文本内容与 [B/11] 第 1 章纲要及"初遇不知情"的分支时序约束一致。
- 永久死亡 `fallen` 写入路径在"玩家操作阵亡"与"剧情性阵亡（瓦伦丁第6章，属于后续 Phase）"两种场景下是否共用同一入口（本 phase 只搭基础设施，实际接线验证留到后续涉及具体阵亡场景的 Phase）。
- 重跑 `npx tsc --noEmit`、`npx --no-install tsx --test`、`bash scripts/gate.sh` 三者均通过。
审计通过后开始规划 Phase 2（`plan-p2.md`：第 2–3 章内容 + 剩余首批角色分批）。
