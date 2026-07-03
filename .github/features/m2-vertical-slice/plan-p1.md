# plan-p1.md — m2-vertical-slice · Phase 1：渲染+移动骨架

目标：让 M1 的无头 headless 服务（地形/单位数据+可达域计算）驱动一个真实 Phaser 画面：能看到网格/地形/单位，能选中单位并点击移动。**不做攻击/AI/HUD 伤害预览/存档/过场/音频**——那些是后续 phase。

## Rules

- 每个 task 完成后先跑验证命令，通过再 commit：commit subject 以 task id 开头（例 `P1-T1: add battle viewmodel skeleton`）。
- 分层严格单向：`src/ui/*` 只 `import` `src/viewmodels/*`；`src/viewmodels/*` 可 `import` `src/models/*` 与 `src/services/*`；反向 import 禁止。不得为了方便让 UI 直接读 model/service。
- `.github/features/**` 下的规划文件不进 git。
- 本 phase 的测试地图/单位是**合成数据**，不是真实第 1 章内容；代码不得硬编码假定“这就是第1章地图”，工厂函数命名要体现“测试用”（如 `createPhase1TestBattle()`，不叫 `createChapter1Battle()`）。
- 伤害预览/HUD/攻击相关的 Command（`attack`/`useSkill`/`endTurn`）在本 phase 只需 stub（接受但 no-op + `// TODO(phase2)` 注释），不要报错中断，保证 UI 不会因未实现 Command 而崩溃。
- 本 phase 完成后写 `audit-p1.md`（自我复盘：对照 idea.md 验收项逐条自检，记录偏差与待办），然后等审计通过再开 Phase 2。

## P1-T1 · BattleViewModel 脚手架

- **Goal**：建立 `src/viewmodels/battleViewModel.ts`，作为 ui 层唯一能依赖的层。
- **Files**：新建 `src/viewmodels/battleViewModel.ts`，`src/viewmodels/types.ts`（Command 与投影类型）。
- **Steps**：
  1. 定义 `type Command = { type: 'selectUnit'; unitId: string } | { type: 'moveTo'; pos: { x: number; y: number } } | { type: 'attack'; targetId: string } | { type: 'useSkill'; skillId: string; targetId?: string } | { type: 'endTurn' }`（字段名与 [E/20] 保持一致，入库前先 `loadPage` 确认字段名）。
  2. 定义 `type BattleProjection`（只读）：`grid`（地形 id 二维数组）、`units`（id/faction/class/pos/hp/hpMax）、`selectedUnitId`、`reachableCells`（当前选中单位的可移动格，无选中则空数组）。
  3. `class BattleViewModel` 构造函数接受 `BattleState`（来自 M1 models）+ `reachableService`（来自 M1 Phase 1），提供 `getProjection(): BattleProjection` 与 `dispatch(cmd: Command): void`。
  4. `dispatch` 处理 `selectUnit`（设置 `selectedUnitId`，调 `reachableService` 算 `reachableCells`）、`moveTo`（校验目标在 `reachableCells` 内才写入 `unit.pos`，写完后清空 `selectedUnitId`与`reachableCells`）。`attack`/`useSkill`/`endTurn`先 `// TODO(phase2)` no-op。
  5. 不要引入任何 Phaser 类型——本文件必须可在无 DOM 环境跡 `tsx --test` 直接单测。
- **Verification**：新增 `src/viewmodels/battleViewModel.test.ts`，覆盖：选中单位后 `reachableCells` 非空；向可达格移动后 `unit.pos` 更新且选中态清空；向不可达格移动被拒绝（报错或无操作，二选一但要有测试断言）。跑 `npx --no-install tsx --test src/viewmodels/battleViewModel.test.ts` 全绿。
- **Commit**：`P1-T1: add battle viewmodel with select/move commands`

## P1-T2 · Phase 1 合成测试地图

- **Goal**：提供一个确定性初始 `BattleState` 工厂函数，供本 phase 渲染与后续 phase 复用。
- **Files**：新建 `src/models/fixtures/phase1TestBattle.ts`（或根据已有目录约定调整路径，但要与 M1 目录分层一致）。
- **Steps**：
  1. 先 `loadDatabase`/本地读 `src/models/terrain.ts`、`src/models/units.ts` 确认导出的类型与 id 命名（不要猜）。
  2. 构造 8 列 × 6 行的网格，至少混合 4 种地形 id（平原/森林/山地/河流——具体取实际 `terrain.ts` 里的 id 值，不要自创新 id），确保至少有一块地形对步兵不可通行/对飞兵可通行（用于后续验证可达域差异）。
  3. 放 2 个玩家方单位（1 步兵 + 1 骑兵）+ 2 个敌方单位（1 步兵 + 1 飞兵），均取自 `units.ts` 现有定义，不新增单位类型。
  4. 导出 `createPhase1TestBattle(): BattleState`，命名明确标注为测试用（参见 Rules 第 4 条）。
- **Verification**：新增单测断言 `createPhase1TestBattle()` 返回的网格尺寸/单位数量正确且所有单位的 `classId`/`terrainId` 引用都能在 M1 的 P1-T6 引用完整性检查函数中通过（直接调用该函数，不重实现）。
- **Commit**：`P1-T2: add phase1 synthetic test battle fixture`

## P1-T3 · entrypoints 真实组装

- **Goal**：`src/entrypoints/main.ts` 从 “创建空 Phaser Game” 升级为 “创建持有真实战斗数据的 Game”。
- **Files**：改 `src/entrypoints/main.ts`，新增/改 `src/ui/scenes/battleScene.ts`（M0 已有则改，无则新建，先 `loadPage` 确认 M0 交付物实际文件名）。
- **Steps**：
  1. `main.ts` 中调用 `createPhase1TestBattle()` 得到 `BattleState`，构造 `reachableService` 实例，新建 `BattleViewModel`。
  2. 通过 Phaser 场景 `init(data)` 或构造函数注入把 `BattleViewModel` 传给 `BattleScene`（不要用全局变量/单例还依赖注入，保持可测试性）。
  3. 移除/替换 M0 遗留的占位场景内容（如果 M0 里有纯文字 “Hello” 占位，在本 task 内直接删除，不拖到后面——对齐 M0 idea.md 对“同 task 内完成清理”的约定）。
- **Verification**：`npx tsc --noEmit` 通过；`npm run build`（或 M0 定义的等价构建命令）成功。
- **Commit**：`P1-T3: wire real battle state into entrypoint`

## P1-T4 · 地形+网格渲染

- **Goal**：`BattleScene` 能把 `BattleProjection.grid` 画成彩色格子 + 网格线，复用 M0 的整数缩放相机配置。
- **Files**：`src/ui/scenes/battleScene.ts`，新增 `src/ui/placeholderPalette.ts`（地形 id → 十六进制颜色的占位色表）。
- **Steps**：
  1. `placeholderPalette.ts` 导出 `TERRAIN_COLOR: Record<string, number>`，至少覆盖 P1-T2 用到的 4 种地形 id，未覆盖的 id 统一回退到灰色 `0x999999`（不报错）。
  2. `BattleScene.create()` 中递归 `projection.grid`，每格用 `this.add.rectangle(x, y, 32, 32, color)` 画实心色块，再用 `this.add.grid(...)` 或手动 `strokeRect` 叠一层细线框。
  3. 复用/确认 M0 已有的整数 zoom 适配逻辑仍旧生效（参考 [C/15] 缩放数学：`zoom = floor(min(屏宽/逻辑宽, 屏高/逻辑高))`）——不重写，只确认新的网格内容能在现有相机下完整可见。
- **Verification**：手动/自动化 headless 浏览器截图或 DOM 断言（取决于 M0 smoke 脚本能力，先 `loadPage`/`readFiles` 确认 M0 smoke 脚本实现方式）确认画面中出现 8×6=48 个格子且至少 2 种不同颜色。
- **Commit**：`P1-T4: render terrain grid in battle scene`

## P1-T5 · 单位渲染 + 选中/移动交互

- **Goal**：能看到单位，点单位选中并高亮可移动格，再点可移动格完成移动。
- **Files**：`src/ui/scenes/battleScene.ts`。
- **Steps**：
  1. 每个 `projection.units` 画一个带阵营色描边的方块（玩家 = 蓝色描边 `0x3366ff`，敌方 = 红色描边 `0xff3333`），内部颜色可用职业区分或统一白色，本 task 不要求精致区分。
  2. 给每个格子/单位绑定 `pointerdown`：若点到本方单位 → `viewModel.dispatch({ type: 'selectUnit', unitId })`；若已有选中且点到的格子在 `reachableCells` 内 → `dispatch({ type: 'moveTo', pos })`。
  3. 每次 `dispatch` 后重新 `getProjection()` 并重绘整个场景（本 phase 不要求性能优化/增量更新，先销毁重建即可）。
  4. `reachableCells` 内的格子面部叠加半透明蓝色高亮层（另一个 `rectangle`，`setAlpha(0.4)`）。
- **Verification**：手动在本地浏览器预览验证交互（或若 M0 smoke 脚本支持模拟点击，写自动化断言）：选中步兵后高亮格数量 > 0；点高亮格后单位方块位置确实移动。
- **Commit**：`P1-T5: add unit rendering and click-to-move interaction`

## P1-T6 · smoke 脚本与 AGENTS.md 更新

- **Goal**：让自动化门禁能拦住本 phase 的回归，并记录新模块分层归属。
- **Files**：改 M0 的 smoke 脚本（先 `readFiles` 确认实际路径，可能是 `scripts/smoke.mjs` 或类似），根 `AGENTS.md`。
- **Steps**：
  1. 扩展 smoke 脚本：除了 M0 已有的 “window.game 存在” 断言外，新增断言场景中存在至少 1 个代表单位的渲染对象（具体方式取决于 smoke 脚本现有能力，不硬求新引入重型依赖）。
  2. 根 `AGENTS.md` 新增一节“M2 Phase1 新增模块”：列出 `src/viewmodels/*`（可被 ui 引用）、`src/ui/scenes/battleScene.ts`、`src/models/fixtures/*`（仅测试用，不进生产数据目录）的分层归属与禁止事项（ui 不得 import models/services）。
- **Verification**：跑完整 gate（`tsc` → `test` → `build` → `smoke`，具体命令以 M0 `gate.sh` 为准）全绿。
- **Commit**：`P1-T6: extend smoke assertions and document phase1 modules`

## Phase 结束

- 写 `audit-p1.md`：逐条对照 idea.md 里标记为“Phase 1”的验收项，说明是否通过及依据（具体命令输出/截图描述）。
- 等用户审核 `idea.md` + 本 `plan-p1.md` 通过后再开写 `plan-p2.md`（攻击+伤害预览 HUD，需依赖 M1 Phase 2 战斗结算服务先完成）。
