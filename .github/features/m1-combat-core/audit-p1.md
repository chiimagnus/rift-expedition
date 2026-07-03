# audit-p1.md — M1 战斗核心 · Phase 1 审计闭环

> 审计人：小辣椒。skill：`plan-task-auditor`（先记录发现 → 后修复 → 再验证）。
> 范围：`m1-combat-core` / `todo.toml` 的 P1-T1..P1-T8 + 清理提交，逐 commit、逐数值对照 `.github/docs/` 设计蓝图原文（A/03·A/04·A/06）。
> 结论：**Gate = Go**（详见 §6 验证）。

## 1. 审计看板（任务→文件→提交）

| task | 描述 | 文件 | commit | 单测 | 计划一致性 |
| --- | --- | --- | --- | --- | --- |
| 基线 | M0 引擎骨架基线 | 全仓 | `f1874df` | — | ✅ |
| P1-T1 | 可注入种子 PRNG | `src/services/prng.ts(.test)` | `8c8f8a8` | 3 | ✅ |
| P1-T2 | 18 种地形数据 | `src/models/terrain.ts(.test)` | `7753a2c` | 8 | ✅ |
| P1-T3 | 武器/魔法相克 + COMBAT | `src/models/weapons.ts(.test)` | `4794fb1` | 6 | ✅ |
| P1-T4 | 步/骑/飞单位数据 | `src/models/units.ts(.test)` | `d457932` | 4 | ✅ |
| P1-T5 | Dijkstra 可达域 | `src/services/reachable.ts(.test)` | `9602507` | 6 | ✅ |
| P1-T6 | 跨模块完整性单测 | `src/models/dataIntegrity.test.ts` | `d7d8869` | 3 | ✅ |
| P1-T7 | BattleState 纯类型 | `src/models/battleState.ts(.test)` | `93fec6d` | 2 | ✅ |
| P1-T8 | AGENTS.md 记录新模块 | `AGENTS.md` | `12dbd2e` | —（文档）| ✅ |
| 清理 | 移除 M0 临时探针 | `pathAliasProbe.*` 删除 | `8474892` | — | ✅ |

提交卫生：`git show --stat` 确认每 task 仅改本 task 文件、一 task 一原子提交；`git ls-files | grep features/` = 空（规划文件未入库，符合硬性规则）；`.git` 完整。

## 2. 数值逐条核对（对照 .github/docs 原文，非抽样）

### 2.1 地形 A/06 — 18 种全部逐字核对 ✅
平原1/1/1 0/0·道路1/1/1 0/0·森林2/3/1 +1/+20·密林3/∞/1 +2/+30·山地3/∞/1 +2/+30·山峰4/∞/1 +3/+40·要塞2/2/1 +2/+20·村庄1/1/1 +1/+10·河流∞/∞/1 0/0·浅滩3/4/1 0/−10·桥1/1/1 0/0·沙地2/3/1 0/0·毒沼2/3/1 0/+10·火山岩2/∞/1 0/0·废墟2/2/1 +1/+15·龙痕祭坛1/1/1 +1/+10·王座1/1/1 +3/+30·断崖∞/∞/1（原表 def/avo 为「—」，代码记 0，已在 effectNote 标注）。
效果字段：仅毒沼/火山岩 `effect:'periodicDamage'`（对应「每回合扣血 / 随机喷发」）；山峰视野/要塞王座回血/废墟遮挡/龙痕增益/断崖坠落等仅 `effectNote` 文字，未写空转占位函数（符合 idea.md 核心需求 1）。

### 2.2 相克 A/03 ✅
武器：剑{斧+1,枪−1} 斧{枪+1,剑−1} 枪{剑+1,斧−1} 弓{}；魔法：炎{冰+1,雷−1} 冰{雷+1,炎−1} 雷{炎+1,冰−1}——方向与每行和=0 均与 A/03 §一一致。
COMBAT = { minDamage:1, counterHit:15, counterMight:1, doublingThreshold:4, critFromSkill:0.5, doubleRNG:true, effMultiplier:3 }——逐字同 A/03 §七。
武器实例：ironSword 威5命90（A/03 示例①锚定）、strongBow 威9+对空（示例③锚定）；ironAxe/ironLance/strongBow.hit 为设计推定值（见 F3）。

### 2.3 单位 A/04 ✅
三兵种 base 均落在 A/04 §二区间（HP16–28/力4–12/魔0–12/技4–12/速4–13/幸0–10/防2–12/魔防0–8/移4–8）；growth 逐字同 A/04 §三：步兵剑士70/45/5/55/55/40/30/20、骑兵枪骑75/50/5/45/45/35/35/15、飞兵天马60/40/10/55/60/45/20/30。飞兵带 `tags:['flying']`。

## 3. 分层与禁区核查（grep 自动验证）✅
- models 无反向 import services（唯一命中为 battleState.test.ts 的字符串扫描断言，属预期）。
- services 无 phaser / DOM 引用。
- 全仓无 `Math.random` 实际调用（prng.ts 仅注释提及）。
- 无本阶段禁止内容：技能/转职/存档(localStorage)/Minimax·行为树 AI/createBattleState·advancePhase 行为函数。
- models 仅常量导出（唯一「行为」是 `Object.fromEntries(...map)` 构造 *_BY_ID），无副作用。
- 地形/武器/单位三数据模块互不 import。
- 逻辑复核：`computeReachable` Dijkstra 四方向、线性取最小、stale-check 正确；起点恒 d=0 入集；`moveCost=∞` 不进入不穿越；push 前判 `nd<=movePower`——无可达性漏算/多算 bug。测试网格断言（步 power5 达(3,2)不达(4,2)；骑被密林墙封 x≤1；飞穿墙）与手算一致。

## 4. 发现项（Findings）

### F1 — Phaser 走 CDN + smoke route 回填（双模式向后兼容代码）
- 级别：**Medium**（与用户新决策冲突：后续 Phaser 一律用 `vendor/phaser.min.js`，不走 CDN）。
- 路径：`index.html`（CDN `<script>`）、`scripts/smoke.mjs`（`page.route('**/cdn.jsdelivr.net/**')` 拦截回填）、`.gitignore`（`vendor/` 被忽略，生产无法用到）、`AGENTS.md` §「生产走 CDN / 测试本地」、`README.md`、`src/types/phaser-global.d.ts` 注释。
- 影响：production 依赖外网 CDN；vendor 被 gitignore 导致「vendor-only」无法在克隆/部署环境成立；smoke 的 route 拦截是仅为「生产 CDN」而存在的兼容层，属应删除的旧代码。
- 建议修复：index.html 直接 `<script src="./vendor/phaser.min.js">`；删除 smoke.mjs 的 CDN route 拦截与 PHASER_VENDOR 兼容注释（改由静态服务器直接托管 vendor 文件）；`.gitignore` 取消忽略 vendor 并将 `vendor/phaser.min.js`(4.2.0) 入库；同步更新 AGENTS.md/README.md/phaser-global.d.ts 注释为 vendor-only。
- 最小验证：`bash scripts/gate.sh` 的 smoke 步骤在无 CDN 拦截下仍 `SMOKE_OK`；`grep -rn cdn.jsdelivr` 全仓为空；`git ls-files | grep vendor/phaser.min.js` 命中。
- 状态：**Open → 待 §5 修复**。

### F2 — 缺少魔法武器实例（MAGIC_DEFS）
- 级别：**Low / Info（Phase 2 前瞻）**。
- 现状：`WEAPON_DEFS` 仅物理四件（剑/斧/枪/弓）；`MAGIC_TRIANGLE` 矩阵已就位但无「火焰/冰/雷」法术实例。
- 影响：A/03 示例②（法师火焰威7命95 → 魔伤20）在 Phase 2 复现时需要一个魔法法术数据（fire, might7, hit95）。
- 判定：Phase 1 的 plan-p1/idea 核心需求 3 只要求两张矩阵 + COMBAT + 一把弓，**未要求**魔法法术实例；故非 Phase 1 缺陷。
- 状态：**Deferred → 记入 plan-p2 输入**，Phase 2 结算服务落地时补 fire 法术实例并复现示例②。

### F3 — 斧/枪/强弓命中等数值为设计推定
- 级别：**Low（��文档化）**。
- 现状：A/03 仅锚定 ironSword(威5命90) 与 strongBow(威9)；ironAxe(8/75)/ironLance(7/80)/strongBow.hit(85) 无蓝图表格来源，按武器三角典型定价。
- 判定：已在 `weapons.ts` 注释显式声明「待 A/09 平衡模拟回调」；不影响 Phase 1 验收（矩阵行和=0、COMBAT 常量）。
- 状态：**Accepted**（Phase 3 平衡 CLI 校准）。

### F4 — `battleState.ts` 注释含「向后兼容扩展」字样
- 级别：**Info**。
- 判定：该处是描述 M3 将以「新增字段」方式扩展 BattleState 的**前向设计注记**，不是可删除的旧代码/兼容层；符合 idea.md 核心需求 9 的 YAGNI 决策。保留。
- 状态：**No action**。

## 5. 修复（仅 F1；先记录后修复）
见 §6 验证与提交记录。

## 6. 修复执行、验证与 Gate 结论

### F1 → Resolved（commit `425e104`）
vendor-only 迁移，一个原子提交完成：
- `index.html`：`<script src="./vendor/phaser.min.js">`（删除 CDN `<script>`）。
- `scripts/smoke.mjs`：删除 `page.route('**/cdn.jsdelivr.net/**')` 拦截回填与 `PHASER_VENDOR` 常量；静态服务器直接托管 `vendor/`。
- `.gitignore`：取消 `vendor/` 忽略；`vendor/phaser.min.js`（实测 `VERSION:"4.2.0"`，1684957 bytes）已入库为生产依赖。
- `AGENTS.md` / `README.md` / `src/types/phaser-global.d.ts`：注释/文档同步为 vendor-only。

### 验证证据
- `grep -rniE 'cdn|jsdelivr|PHASER_VENDOR|route\('` 全仓（除 node_modules）仅剩 smoke.mjs 里一行「不走 CDN」说明性注释，无任何 CDN 代码/拦截。
- `bash scripts/gate.sh` → `GATE_EXIT=0` / `GATE_OK`：typecheck → test **32 pass / 0 fail** → build (`dist/main.js 1.2kb`) → smoke **SMOKE_OK**（无 CDN 拦截，纯本地 vendor 加载 Phaser 成功启动 `window.game instanceof Phaser.Game`）。日志：`/tmp/gate-p1-vendor.log`。
- `git ls-files | grep vendor/phaser.min.js` 命中；`git ls-files | grep features/` 为空（规划文件仍未入库）。

### 提交链（M1 P1 + 审计修复）
`f1874df`（基线）→ `8c8f8a8` → `7753a2c` → `4794fb1` → `d457932` → `9602507` → `d7d8869` → `93fec6d` → `12dbd2e` → `8474892`（清理）→ `425e104`（F1 vendor-only 修复）。

### Gate 结论：**Go**
Phase 1 全 8 task 实现完整且与 plan-p1/idea 一致；数值逐条对照蓝图无误；分层/禁区无违规；无行为性 bug；F1（CDN 向后兼容代码）已删除并改为 vendor-only 且门禁全绿。可进入 Phase 2（plan-p2：战斗结算服务）规划（并将 F2 作为输入：补 fire 法术实例以复现 A/03 示例②）。
