# plan-p1.md — m2-vertical-slice · Phase 1：渲染+移动骨架

目标：让 M1 的无头 headless 服务（地形/单位数据+可达域计算+`BattleState`/`UnitInstance` 模型）驱动一个真实 Phaser 画面：能看到网格/地形/单位，能选中单位并点击移动。**不做攻击/AI/HUD 伤害预览/存档/过场/音频**——那些是后续 phase。

> **本次审计总结（请执行者先读）**：对照完整 M0/M1 文档逐字核对后，发现以下问题并已修正：
> 1. **文件名大小写错误**：M0 实际创建的是 `src/ui/scenes/BattleScene.ts`（首字母大写，导出 `export default class BattleScene`），但本文档之前写成了小写的 `battleScene.ts`。因为 `tsconfig.json` 开了 `forceConsistentCasingInFileNames`，且沙箱文件系统区分大小写，若按错误大小写新建会变成另一个完全新的文件，而不是修改 M0 已有的场景！已全文统一改为 `BattleScene.ts`。
> 2. **依赖了一个 M1 从未定义过的类型**：原文把 `BattleState` 写成“来自 M1 models”，但 M1 之前从未定义过它。已在 M1 plan-p1.md 新增 P1-T7 补上 `src/models/battleState.ts`（详见 M2 idea.md“发现的不一致之处 5”），本文档已同步更新引用。
> 3. **`reachableService` 不存在**：原文把可达域计算当作一个可注入的“服务对象”，但 M1 实际导出的只是一个纯函数 `computeReachable`（无状态、无副作用，不需要 mock/注入）。已改为直接 `import`。
> 4. **验证方法不可行**：Phaser 渲染到 Canvas/WebGL，没有 DOM 节点可供 Playwright 直接查询；原文“具体方式取决于 smoke 脚本现有能力”过于含糊。已改为明确的 `window.__battleDebugHooks` 调试钩子方案。
> 5. **单位引用完整性验证写错**：原文说要“直接调用 M1 P1-T6 引用完整性检查函数”，但 M1 P1-T6 只是一个测试文件，无任何导出函数可被外部调用。已改为 M2 自己写直接存在性断言。
> 6. **Phaser 场景注入方式含糊且与 M0 现有 `scene: [BootScene, BattleScene, UIScene]` 数组写法兼容性未确认**：已改为明确的单一方案（预实例化 Scene 实例而非传类）。
> 7. **清理时机**：用户要求“需要及时清理掉老旧代码而不是在最后一次 task 中清理”——已逐 task 检查，确保 P1-T3（唐换 M0 占位场景内容）在自己那一步就删旧内容，不拖到 P1-T6。

## Rules

- 每个 task 完成后先跑验证命令，通过再 commit：commit subject 以 task id 开头（例 `P1-T1: add battle viewmodel skeleton`）。
- 分层严格单向：`src/ui/*` 只 `import` `src/viewmodels/*`；`src/viewmodels/*` 可 `import` `src/models/*` 与 `src/services/*`；反向 import 禁止。不得为了方便让 UI 直接读 model/service（比 M0 AGENTS.md 的描述更严格，见 idea.md 移交备注 2）。
- `.github/features/**` 下的规划文件不进 git。
- 本 phase 的测试地图/单位是**合成数据**，不是真实第 1 章内容；代码不得硬编码假定“这就是第1章地图”，工厂函数命名要体现“测试用”（如 `createPhase1TestBattle()`，不叫 `createChapter1Battle()`）。
- 伤害预览/HUD/攻击相关的 Command（`attack`/`useSkill`/`endTurn`）在本 phase 只需 stub（接受但 no-op + `// TODO(phase2)` 注释），不要报错中断，保证 UI 不会因未实现 Command 而崩溃。
- **同 task 内清理（用户明确要求）**：若某 task 的实现替换/废弃了之前 task（包括 M0）写的内容，必须在替换发生的同一个 task 内直接删除旧代码，不要拖到最后一个 task 或 Phase Audit 才清理。本 phase 具体适用于：P1-T3 删除 M0 BattleScene 的占位背景色/console.log；无其他已知需要废弃的代码。
- 本 phase 完成后写 `audit-p1.md`（自我复盘：对照 idea.md 验收项逐条自检，记录偏差与待办），然后等审计通过再开 Phase 2。

## P1-T1 · BattleViewModel 脚手架

- **Goal**：建立 `src/viewmodels/battleViewModel.ts`，作为 ui 层唯一能依赖的层。
- **Files**：新建 `src/viewmodels/battleViewModel.ts`，`src/viewmodels/types.ts`（Command 与投影类型）。
- **Steps**：
  1. 先 `loadPage` 确认 [E/20] 中 `Command` 的字段命名，定义：`type Command = { type: 'selectUnit'; unitId: string } | { type: 'moveTo'; pos: { x: number; y: number } } | { type: 'attack'; targetId: string } | { type: 'useSkill'; skillId: string; targetId?: string } | { type: 'endTurn' }`。
  2. 定义 `type BattleProjection`（只读）：
     ```typescript
     interface BattleProjection {
       gridWidth: number
       gridHeight: number
       grid: string[][]        // 直接搬运 BattleState.grid（地形 id，grid[y][x]）
       units: Array<{ id: string; unitDefId: string; faction: 'player' | 'enemy'; pos: { x: number; y: number }; hp: number; hpMax: number }>
       selectedUnitId: string | null
       reachableCells: Array<{ x: number; y: number }>   // 无选中则为空数组
     }
     ```
  3. `class BattleViewModel` 构造函数**只**接受 `BattleState`（从 `@models/battleState` 导入类型，M1 Phase1 P1-T7 交付），**不**接受任何“`reachableService`”参数——直接在文件顶部 `import { computeReachable } from '@services/reachable'`（它是纯函数，无需注入/mock）。提供 `getProjection(): BattleProjection` 与 `dispatch(cmd: Command): void`。
  4. `dispatch` 处理：
     - `selectUnit`：根据 `unitId` 在 `state.units` 中找到对应 `UnitInstance`，再从 `UNIT_DEFS`（`@models/units`）按 `unitDefId` 查到 `moveType`/`base.mov`，调用 `computeReachable({ grid: state.grid, start: unit.pos, moveType, movePower: base.mov })` 得到 `Set<string>`，转换为 `Array<{x,y}>` 写入 `reachableCells`，同时设 `selectedUnitId`。若 `unitId` 不存在或 `faction !== 'player'`，视为无效操作（不报错、不改状态）——本 phase 不允许选中敌方单位。
     - `moveTo`：校验目标坐标的 `"x,y"` 键在上一步缓存的可达域 `Set<string>` 内才写入 `unit.pos`，写完后清空 `selectedUnitId` 与 `reachableCells`。若不在可达域内，拒绝（no-op，不抛异常）。
     - `attack`/`useSkill`/`endTurn`：`// TODO(phase2)` no-op。
  5. 不要引入任何 Phaser 类型——本文件必须可在无 DOM 环境跑 `tsx --test` 直接单测。
- **Verification**：新增 `src/viewmodels/battleViewModel.test.ts`，覆盖：选中本方单位后 `reachableCells` 非空；选中敌方单位时无效（`selectedUnitId` 仍为 null）；向可达格移动后 `unit.pos` 更新且选中态清空；向不可达格移动被拒绝（无操作，有断言）。跑 `npx --no-install tsx --test src/viewmodels/battleViewModel.test.ts` 全绿。
- **Commit**：`P1-T1: add battle viewmodel with select/move commands`

## P1-T2 · Phase 1 合成测试地图

- **Goal**：提供一个确定性初始 `BattleState` 工厂函数，供本 phase 渲染与后续 phase 复用。
- **Files**：新建 `src/models/fixtures/phase1TestBattle.ts`。
- **Steps**：
  1. 先直接读 `src/models/terrain.ts`、`src/models/units.ts`、`src/models/battleState.ts` 确认导出的类型与 id 命名（不要猜）。
  2. 构造 8 列 × 6 行的 `grid: string[][]`（`grid[y][x]`，行优先），至少混合 4 种地形 id（具体取实际 `terrain.ts` 里的 id 值，不自创新 id），确保至少有一块地形对步兵 `moveCost.foot === Infinity`但对飞兵 `moveCost.fly` 有限（用于后续验证可达域差异）。
  3. 放 2 个玩家方 `UnitInstance`（faction: 'player'，1 步兵 + 1 骑兵，均取 `UNIT_DEFS` 现有 `unitDefId`，`hp`/`hpMax` 取对应 `UNIT_DEFS[i].base.hp`）+ 2 个敌方 `UnitInstance`（faction: 'enemy'，1 步兵 + 1 飞兵），`id` 用不于 `unitDefId` 的实例级唯一字符串（如 `"p1"`/`"e1"`）。
  4. 组装完整 `BattleState`：`gridWidth:8, gridHeight:6, grid, units, phase:'deploy', rngState: seed(42)（从 @services/prng 的 seed 函数算出初始值后写死为常量，本文件不 import services，直接写数字字面量）, turnCount: 0`。
  5. 导出 `createPhase1TestBattle(): BattleState`，命名明确标注为测试用（参见 Rules 第 4 条）。
- **Verification**：新增 `src/models/fixtures/phase1TestBattle.test.ts`，直接写存在性断言（不依赖 M1 的 `dataIntegrity.test.ts`，因为那只是一个无导出的测试文件）：断言返回的 `grid` 尺寸为 8x6、`units.length === 4`；逐个断言每个 `unit.unitDefId` 都能在 `UNIT_DEFS.find(u => u.id === unitDefId)` 中找到；逐格断言 `grid` 中每个地形 id 都能在 `TERRAIN_BY_ID` 中找到。跑 `npx --no-install tsx --test src/models/fixtures/phase1TestBattle.test.ts` 全绿。
- **Commit**：`P1-T2: add phase1 synthetic test battle fixture`

## P1-T3 · entrypoints 真实组装

- **Goal**：`src/entrypoints/main.ts` 从 “创建空 Phaser Game” 升级为 “创建持有真实战斗数据的 Game”。
- **Files**：改 `src/entrypoints/main.ts`，改 `src/ui/scenes/BattleScene.ts`（M0 已建，注意首字母大写，不要新建同名小写文件）。
- **Steps**：
  1. `main.ts` 中调用 `createPhase1TestBattle()` 得到 `BattleState`，`new BattleViewModel(battleState)`。
  2. 将 `BattleScene` 改为接受构造函数注入：`export default class BattleScene extends Phaser.Scene { constructor(private viewModel: BattleViewModel) { super({ key: 'BattleScene' }) } ... }`。`main.ts` 中先 `const battleScene = new BattleScene(viewModel)` 得到**实例**（不是类），再把 `scene: [BootScene, battleScene, UIScene]`（`BootScene`/`UIScene` 仍传类，只有 `BattleScene` 传预实例化好的实例）传给 `new Phaser.Game({...})`。Phaser 支持混合传入类与实例，且不影响 M0 `BootScene` 里用字符串键 `this.scene.start('BattleScene')`/`this.scene.launch('UIScene')` 的现有调度方式（它们按 `key` 匹配，与实例还是类无关）。**不要**用 `init(data)` 作为另一套并存方案——只选构造函数注入这一种，避免歧义。
  3. 删除 M0 在 `BattleScene.create()` 里留下的占位内容（`this.cameras.main.setBackgroundColor('#1d1f2b')` 与 `console.log('[BattleScene] ready')`——M0 里并没有字面“Hello”文本占位，实际内容就是这两行），**在本 task 内直接删除**，不拖到后面。
- **Verification**：`npx tsc --noEmit` 通过；`node scripts/build.mjs`（M0 定义的构建命令）成功。
- **Commit**：`P1-T3: wire real battle state into entrypoint`

## P1-T4 · 地形+网格渲染

- **Goal**：`BattleScene` 能把 `BattleProjection.grid` 画成彩色格子 + 网格线，复用 M0 的整数缩放相机配置，并暴露调试钩子供 P1-T6 smoke 断言。
- **Files**：`src/ui/scenes/BattleScene.ts`，新增 `src/ui/placeholderPalette.ts`（地形 id → 十六进制颜色的占位色表）。
- **Steps**：
  1. `placeholderPalette.ts` 导出 `TERRAIN_COLOR: Record<string, number>`，至少覆盖 P1-T2 用到的 4 种地形 id，未覆盖的 id 统一回退到灰色 `0x999999`（不报错）。
  2. `BattleScene.create()` 中遍历 `projection.grid`，每格用 `this.add.rectangle(gx*32+16, gy*32+16, 32, 32, color)` 画实心色块（**注意**：Phaser Rectangle 默认 origin 为 (0.5,0.5)即以中心为原点，因此坐标要加半格偏移 `+16`，否则会整体偏移半格），再用 `strokeRect(gx*32, gy*32, 32, 32)` 叠一层细线框。
  3. 复用/确认 M0 已有的整数 zoom 适配逻辑仍旧生效（参考 [C/15] 缩放数学：`zoom = floor(min(屏宽/逻辑宽, 屏高/逻辑高))`）——不重写，只确认新的网格内容能在现有相机下完整可见（8×32=256≤88=448、192=6×32≤88=320 逻辑分辨率，确实完全能装下）。
  4. 在 `BattleScene.create()` 末尾暴露一个仅供自动化测试使用的全局调试钩子（写注释标明仅供 smoke 测试）：`;(window as any).__battleDebugHooks = { gridCols: projection.gridWidth, gridRows: projection.gridHeight, unitCount: projection.units.length }`，避免后续 task 去搜索 Canvas 像素来验证渲染（Phaser 渲染到 Canvas/WebGL，无 DOM 节点可供 Playwright 直接查询，因此不要写基于像素读取的断言）。
- **Verification**：人工本地预览确认画面中出现 8×6=48 个格子且至少 2 种不同颜色；`node -e "..."` 或 P1-T6 的 smoke 脚本会正式断言 `window.__battleDebugHooks.gridCols === 8 && gridRows === 6`。
- **Commit**：`P1-T4: render terrain grid in battle scene`

## P1-T5 · 单位渲染 + 选中/移动交互

- **Goal**：能看到单位，点单位选中并高亮可移动格，再点可移动格完成移动。
- **Files**：`src/ui/scenes/BattleScene.ts`。
- **Steps**：
  1. 每个 `projection.units` 画一个带阵营色描边的方块（`faction === 'player'` 蓝色描边 `0x3366ff`，`faction === 'enemy'` 红色描边 `0xff3333`），内部颜色统一白色，中心坐标同样用 `pos.x*32+16, pos.y*32+16`。
  2. 给每个地形格子矩形 `setInteractive()` 并绑 `pointerdown`：若该格坐标在当前 `reachableCells` 内 → `viewModel.dispatch({ type: 'moveTo', pos })`。给每个单位方块另外 `setInteractive()` 并绑 `pointerdown`：若该单位 `faction === 'player'` → `dispatch({ type: 'selectUnit', unitId })`（若点到敌方单位，ViewModel 内部已在 P1-T1 处理为无效操作，无需 UI 层重复判断）。单位方块应叠在地形方块之上且优先接收点击（Phaser 默认按添加顺序値事件，单位要在地形之后添加）。
  3. 每次 `dispatch` 后重新 `getProjection()` 并重绘整个场景（本 phase 不要求性能优化/增量更新，先销毁重建即可：清空之前创建的所有 rectangle game object 再重新画，避免重复叠加导致泄漏）。
  4. `reachableCells` 内的格子上叠加半透明蓝色高亮层（另一个 `rectangle`，`setAlpha(0.4)`）。
  5. 更新 P1-T4 的 `window.__battleDebugHooks`，每次 `getProjection()` 后同步写回 最新 `unitCount`、新增 `selectedUnitId` 与 `reachableCellCount`字段，供 P1-T6 smoke 脚本断言交互确实发生了。
- **Verification**：人工本地预览验证交互：选中步兵后高亮格数量 > 0；点高亮格后单位方块位置确实移动。
- **Commit**：`P1-T5: add unit rendering and click-to-move interaction`

## P1-T6 · smoke 脚本与 AGENTS.md 更新

- **Goal**：让自动化门禁能挡住本 phase 的回归，并记录新模块分层归属。
- **Files**：改 `scripts/smoke.mjs`（M0 交付物，实际路径先 `readFiles` 确认），根 `AGENTS.md`。
- **Steps**：
  1. 在 M0 已有的 `page.waitForFunction(() => window.game instanceof window.Phaser.Game)` 断言**之后**，新增：`const hooks = await page.evaluate(() => (window as any).__battleDebugHooks); assert(hooks && hooks.gridCols === 8 && hooks.gridRows === 6 && hooks.unitCount === 4)`——直接读 P1-T4/P1-T5 暴露的调试钩子，**不要**引入 canvas 像素读取或新的重型依赖。
  2. 根 `AGENTS.md` 新增一节“M2 Phase1 新增模块”，列出：
     - `src/viewmodels/battleViewModel.ts`/`types.ts`（可被 ui 引用，只 `import` models/services，不得 `import` Phaser）。
     - `src/ui/scenes/BattleScene.ts`（注意大小写）、`src/ui/placeholderPalette.ts`（只能 `import` viewmodels，不得直接 `import` models/services——比 M0 原文描述更严格，明确写明这条，避免后续执行者参考 M0 较嬽的描述跳过 viewmodels）。
     - `src/models/fixtures/*`（仅测试用，不进生产数据目录，不被 `src/services/*` 或非测试代码 import）。
     - `window.__battleDebugHooks` 是仅供 `scripts/smoke.mjs` 读取的测试钩子，不是正式公开 API，日后不要被业务代码依赖。
- **Verification**：跑完整 gate（`tsc` → `test` → `build` → `smoke`，具体命令以 M0 `gate.sh` 为准）全绿。
- **Commit**：`P1-T6: extend smoke assertions and document phase1 modules`

## Phase 结束

- 写 `audit-p1.md`：逐条对照 idea.md 里标记为“Phase 1”的验收项，说明是否通过及依据（具体命令输出/截图描述）。
- 等用户审核 `idea.md` + 本 `plan-p1.md` 通过后再开写 `plan-p2.md`（攻击+伤害预览 HUD，需依赖 M1 Phase 2 战斗结算服务先完成）。
