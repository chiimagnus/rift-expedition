# idea.md — M1 战斗核心（双生圣痕 · 血脉宿命战棋）

> 需求真源。plan-pN.md 只负责实现拆分与执行细节，不重复这里的决策背景。

## 背景 / 触发

- M0 引擎骨架已完成规划复审（见 `../m0-engine-skeleton/idea.md` / `plan-p1.md`），仓库分层目录、路径别名、`tsx --test`、`scripts/gate.sh` 已就绪（尚待实际编码提交）。按 [F/24 路线图]依赖顺序 `M0 → M1 → M2 → ...`，本 feature 规划 **M1 战斗核心**。
- F/24 对 M1 的定义：目标「相克/移动/攻击/追击/地形」；交付物「战斗 services + models + 单测 + 平衡 CLI」；验收「一张测试图可完整对战，回报矩阵行和=0」。M1 **不含**地图关卡、剧情、UI 渲染、真实美术/音频——那些是 M2 垂直切片的范畴。
- 依据设计蓝图：[A/02 系统架构]（构建顺序第一条："先核心循环系统：战斗+地形+移动"）、[A/03 战斗与相克]（公式核心）、[A/04 单位与职业]、[A/06 地形系统]、[A/09 平衡设计]、[E/20 技术架构]、[E/21 数据模型与存档]、[E/22 可执行规格与测试]。
- 本 feature 只往 `src/services/`、`src/models/` 填真实逻辑，不碰 `src/ui/`、`src/viewmodels/`、`src/entrypoints/`（那些留给 M2 垂直切片接线时再动）。

## 核心需求

1. **地形数据**（对应 [A/06]）：设计文档正文写「目标约 15 种地形」，但该页表格实际逐条列出了 **18 种**具体地形（平原/道路/森林/密林/山地/山峰/要塞/村庄/河流/浅滩/桥/沙地/毒沼/火山岩/废墟/龙痕祭坛/王座/断崖），数值均已给出。**以表格为准**（正文"约 15"只是约数，不是精确目标），本阶段完整收录全部 18 种地形的 `moveCost{foot,horse,fly}`、`def`、`avo` 数值。
   - 地形「特殊」字段中，只有「每回合扣血」这一类效果（毒沼/火山岩）在 M1 实现为真正可调用的 effect handler；「视野遮挡」「预警高亮」「Boss 回血」「龙裔增益」「坠落即死」等效果依赖尚不存在的视野系统/剧情系统/AI 阶段机制，本阶段只作为数据字段的文字记录，不实现执行逻辑（见非目标）。「断崖」通过 `moveCost=∞`（步/骑）+ 允许飞兵通行已经足够表达核心移动限制，坠落即死判定不在本阶段实现。
2. **单位/兵种最小数据集**（对应 [A/04]）：只建 MVG 范围内的 3 个基础兵种（步兵/骑兵/飞兵），含属性块（HP/力量/魔力/技巧/速度/幸运/防御/魔防/移动）与成长率字段（成长率字段本阶段只声明、不参与任何计算——升级/经验系统属于成长养成域，明确列为非目标）。
3. **武器与相克矩阵**（对应 [A/03]）：武器三角（剑/斧/枪）+ 魔法三系（炎/冰/雷）两张回报矩阵；`COMBAT` 可调参表：`{ minDamage:1, counterHit:15, counterMight:1, doublingThreshold:4, critFromSkill:0.5, doubleRNG:true, effMultiplier:3 }`。另加一把远程武器（弓）用于验证「1–2 射程」与「对空特攻」边界规则。
4. **战斗结算服务**：实现 [A/03] 给出的完整公式——物理伤害、魔法伤害、命中%（含双 RNG）、暴击%、追击判定、特攻倍率、六步结算顺序（判定射程→攻方一击→守方反击→追击判定→被动/羁绊/龙痕 hook（M1 阶段为空 no-op，占位给 M2+ 挂载）→异常/地形效果结算）。
5. **可注入种子 PRNG 服务**（对应 [E/20]）：mulberry32 算法，纯函数式 `next(state) => [value, newState]`，`state` 是可序列化的 `number`（对应 [E/21] `BattleState.rngState`）。战斗结算与平衡 CLI 全程通过该服务取随机数，禁止直接调用 `Math.random`。
6. **可达域计算**（对应 [A/06] 地形×移动 + [E/20] 寻路）：给定起点、移动力、地形网格，用 Dijkstra（按地形 moveCost 加权、按兵种类型 foot/horse/fly 分别计费）算出可达格集合；`moveCost=∞` 视为不可通行（骑兵不可进森林以上密度地形）。本阶段只需可达域判定，不需要路径重建/寻路可视化（那是 M2 需要"走位动画"时才加，A\* 路径重建延后）。
7. **平衡模拟 CLI 与最小贪心 AI**（对应 [A/09] + [E/22]）：`npm run sim -- --matchup all --iters N --seed S`，对每对基础兵种做 1v1 相邻对砍直到一方阵亡，重复 N 次，输出胜率表；驱动对战的决策逻辑只需最简单的贪心（每回合攻击当前唯一可及目标，无需选择——1v1 场景没有"选谁打"的决策空间，因此本阶段甚至不需要真正的贪心择敌算法，只需"回合制轮流攻击直到一方阵亡"）；Minimax/α-β／行为树 Boss AI 是 [E/20] 标注的「精英/Boss」分级，属于 M2+ 需要真实多单位关卡时才做，本阶段不实现。
8. **数据文件形式（实现细节决策，供低上下文执行者知悉）**：[E/21] 提到的 `terrain.json`/`units.json`/`weapons.json` 命名是内容组织方式的示意，不是「必须是运行时加载的 .json 文件」的硬性要求。M1 数据量小（18 地形/3 兵种/4 武器），选择用 **TypeScript 常量模块**（`src/models/terrain.ts` 导出 `TERRAIN_DEFS`、`src/models/weapons.ts` 导出矩阵与 `COMBAT`、`src/models/units.ts` 导出 `UNIT_DEFS`），理由：①获得编译期类型检查与跨模块引用完整性（TS 联合类型即可防止「武器类型拼写错误却不报错」，不需要额外运行时 schema 校验器）；②避免引入 JSON 运行时加载路径（`fetch` 或 import assertion）在 esbuild 打包 / `tsx --test` 两套环境下的兼容性不确定性（YAGNI：M1 无「非工程师改数据」的真实需求）。等 M3+ 批量填充 35 角色/70 技能等大体量内容、且确有「策划直接编辑数据不碰代码」的真实需求时，再引入真正的运行时 `.json` 加载与 schema 校验管线。
9. **运行时战斗状态模型 `BattleState`/`UnitInstance`**（对应 [E/21] 核心运行时模型）：M2 垂直切片需要一个具体的、可实例化的战斗运行时状态对象才能渲染画面和接线 ViewModel，而核心需求 1–8 只交付了静态数据定义（`TerrainDef`/`WeaponDef`/`UnitDef`）与纯函数服务（`prng`/`reachable`），从未定义过承载"一局具体对战"的运行时状态类型——这是本阶段必须补的缺口，否则 M2 无米下锅。新增 `src/models/battleState.ts`：
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
     rngState: number         // 与 [E/20] PRNG 服务的 state 同型，但本文件不 import services
     turnCount: number
   }
   ```
   本阶段的 `BattleState` 只含 M1/M2 垂直切片阶段用得到的最小字段集合；[E/21] 文档里额外列出的 `bonds`/`dragonTaint`/`flags` 字段属于羁绊/龙痕觉醒/剧情分支机制（[A/05]/[B/11]/[B/13]），那些系统要到 M3 Act 1 才投入使用，本阶段**刻意不提前加**这些字段（YAGNI——加了也没有任何代码会读写，属于死字段），待 M3 规划时再评估以"新增字段"的方式向后兼容扩展 `BattleState`。**该文件只是纯类型定义（`interface`/`type`），不含任何函数/逻辑，不 `import` `src/services/*` 任何内容**——`services` 层可以消费这些类型，但类型定义本身不依赖 services（避免 models→services 反向依赖）。也修正核心需求 6 的可达域输入类型：`computeReachable` 的 `grid` 参数应为地形 id 的二维数组 `string[][]`（与 `BattleState.grid` 同型），而不是完整 `TerrainDef[][]`——调用方按需自行用 `TERRAIN_BY_ID[id]` 查具体地形数值。

## 默认值与兼容策略

- 复用 M0 已建立的分层目录、路径别名（`@models/*` `@services/*`）、`tsx --test`、`scripts/gate.sh`，不新增顶层目录、不新增构建工具。
- 不需要新增 npm 依赖：PRNG、Dijkstra、平衡模拟 CLI 全部手写 TypeScript，沙箱已有 node 24 + typescript + tsx。
- `npm run sim` 是独立命令，**不**纳入 `scripts/gate.sh` 的强制四步门禁（tsc → test → build → smoke）——因为它是「验证平衡性的探索性工具」而非「编译/测试/构建/冒烟」四类快速门禁之一；跑 1000+ 局模拟耗时较长，不适合作为每次提交都强制跑的门禁步骤。`gate.sh` 保持 M0 定义的四步不变。

## 非目标（明确不做什么）

- 不实现技能系统（被动/主动/职业专属/羁绊合击/龙痕觉醒）——见 [A/05]，属于 M2+（需要 UI 交互与内容批量投放才有意义）。六步结算顺序中的「触发被动/羁绊/龙痕」步骤本阶段实现为空 no-op 钩子，仅占位以保证后续接入不用改结算主流程。
- 不实现转职树、成长升级、经验值计算——见 [A/04]/[A/08]。成长率字段只声明不参与运算。
- 不实现存档系统（localStorage/SaveGame/版本迁移）——见 [E/21]，M1 是纯内存战斗模拟，无持久化需求。
- 不实现 Minimax/α-β 敌方 AI、行为树 Boss——见「核心需求 7」的范围说明。
- 不接入 `src/ui`/`src/viewmodels`/`src/entrypoints` 层，不渲染任何画面，不消费 Phaser。
- 不做全部 10 类兵种——只做步/骑/飞 3 类（MVG 范围内）；其余 7 类（重甲/法师/弓兵/治疗/盗贼/魔导炮/龙裔）延后到内容批量投放阶段（[F/23]）。**例外**：本阶段允许额外建「弓」这一件武器（不是新兵种，只是步兵可以换装的远程武器数据），用于验证 1–2 射程与对空特攻边界规则，不建"弓兵"这个兵种本身。
- 不实现「视野遮挡」「预警高亮」「Boss 回血」「龙裔增益」「坠落即死」等依赖视野/剧情/AI 系统的地形特殊效果执行逻辑（见核心需求 1）。
- 不引入运行时 JSON 数据加载与 schema 校验管线（见核心需求 8 的决策说明）。

## 验收标准（可检查）

- [ ] `src/models/battleState.ts` 存在且导出完整的 `BattleState`/`UnitInstance`/`Faction`/`BattlePhase` 类型（字段集合见核心需求 9），且该文件源码中不出现 `from '@services` 或 `from '../services` 等任何指向 services 层的 import 字符串（单测里用字符串扫描源码文本来断言，而不是只做 TS 编译期检查——防止后续有人临时加一行 import 但编译因为 type-only import 被擦除而没报错）。
- [ ] `src/models/terrain.ts` 完整收录表格中全部 **18 种**地形，逐条数值（moveCost/def/avo）与 [A/06] 表格一致（单测逐条断言，不是抽样）。
- [ ] 武器三角矩阵（剑/斧/枪）每行和为 0；魔法三系矩阵（炎/冰/雷）每行和为 0——单元测试断言。
- [ ] 战斗结算服务对 [A/03] 给出的 3 个数值演算示例逐一复现并断言：①剑士攻斧兵，伤害=17、命中=88%、可追击；②法师攻将军，魔法伤害=20；③弓手攻天马，特攻伤害=57。
- [ ] 双 RNG 命中：给定固定种子跑 ≥1000 次统计，显示命中 88% 时真实命中的经验频率接近文档给出的约 97%（统计断言允许合理误差区间，不对单次随机结果做断言）。
- [ ] 可达域计算：给定一张含至少 3 种地形（含至少一种 `moveCost=∞` 对某兵种类型不可通行）的测试网格，断言移动力边界内外的格子集合正确，且骑兵确实不能进入密林/山地。
- [ ] 平衡模拟 CLi 对步/骑/飞两两组合（3 对）各跑 1000+ 局：若两者之间存在武器/相克优势差异，胜率应体现该差异方向；若刻意构造对称对局（同兵种同装备），胜率收敛 50%±5%。
- [ ] `npx tsc --noEmit`、`npx --no-install tsx --test`、`bash scripts/gate.sh` 全部通过（exit code 0）；`npm run sim -- --matchup all --iters 1000 --seed 42` 能跑完并输出胜率表，不在 `gate.sh` 强制链路中。
- [ ] `git log --oneline` 每个 task 对应一次原子提交，commit subject 以稳定 task id 开头。

## 移交备注（给低上下文执行者）

1. 严格只做 M1 范围内的事：不要顺手实现技能/转职/存档/UI/Minimax AI/视野系统，哪怕看起来顺手好加。
2. 复用 M0 已建好的 `tsconfig.json`、路径别名、`tsx --test`、`scripts/gate.sh`，不要重新配置或引入新工具链、不要新建 `.json` 运行时数据文件（本阶段数据是 `.ts` 常量模块，见核心需求 8）。
3. 每个 task：先跑该 task 的验证命令确认通过，再一次性 `git add` 该 task 涉及文件后 `git commit`；commit subject 以稳定 task id 开头（如 `P1-T3 - ...`），中文描述，Conventional Commits 前缀（`feat:`/`test:`/`chore:` 等）。
4. 不要 `git add`/`git commit` `.github/features/**` 下的规划文件（`idea.md`/`todo.toml`/`plan-pN.md`/`audit-pN.md`）。
5. 数值必须与设计蓝图 [A/03]（战斗公式与三个演算示例）、[A/04]（属性范围）、[A/06]（18 种地形数值表）逐字核对，不要凭感觉估算——验收标准里的示例数字（伤害 17、命中 88%、特攻 57 等）就是防止数值算错的校验锚点。
6. 分层依赖方向不能反：`src/services/*` 可以 `import` `src/models/*`（通过 `@models/*` 别名），但 `src/models/*` 不能 `import` `src/services/*` 之类的上层——`src/models/battleState.ts` 尤其要注意，它是纯类型文件，不得 `import type { PrngState } from '@services/prng'` 这类看似无害的类型引用，`rngState` 字段直接声明为 `number` 即可。
7. 完成本 feature 全部 phase 的 task 后，进入对应 audit 闭环（发现问题→修复→重跑验证命令），确认通过后才能开始规划 M2（`m2-vertical-slice`）。
