# idea.md — M2 垂直切片（双生圣痕 · 血脉宿命战棋）

> 需求真源。plan-pN.md 只负责实现拆分与执行细节，不重复这里的决策背景。

## 背景 / 触发

- 按 [F/24 路线图]，M2 目标是“打通一章完整体验”，交付物明确列为：地图/单位/HUD/伤害预览/AI/存档/过场/BGM，验收是“单章 30–50 分钟闭环可玩”。本 feature 把这个里程碑拆分为多个 phase，**本次只规划 idea.md（全 feature）+ Phase 1**，后续 phase 待 Phase 1 审计通过后再写。
- 前提：M0（引擎骨架）与 M1（战斗核心 Phase 1：地形/武器/单位数据+PRNG+可达域+运行时战斗状态模型 `BattleState`/`UnitInstance`）已规划（尚未实际编码）。M2 需要 M1 的战斗结算服务（M1 Phase 2，尚未规划）才能做攻击，因此 **本 feature 的 Phase 1 只做移动+渲染，不做攻击**，避免反过来依赖尚不存在的 M1 交付物。
- 依据设计蓝图：[A/01 愿景与核心循环]（MVG 范围）、[A/07 遭遇战与关卡设计]、[B/14 演出与导演]（过场 DSL）、[C/15 美术风格指南]、[C/17 UI·HUD]、[D/18 音乐设计]、[D/19 音效设计]、[F/23 内容规模与清单]、[F/25 决策日志]。

## 发现的设计蓝图不一致之处（写 plan 前先记录，避免执行时困惑）

1. **MVG 范围（A/01）与 M2 交付物（F/24）对“存档”的取舍不一致**：A/01 第八节明确写“延后：...存档养成...”，但 F/24 M2 行明确列出“存档”为交付物。**本 feature 以 F/24（更具体的里程碑定义，作为路线图权威来源）为准**，但只实现最小存档（关卡内快照，用于验证机制），不实现 [E/21] 完整 `SaveGame`（永久死亡名单/多存档槽/版本迁移等属于 M3+ 养成系统就绪后才有意义）。
2. **技能系统范围**：A/01 MVG 提到需要“技能/治疗”，但 M1 idea.md 明确把整个技能系统（[A/05]，~70 条）列为 M2+ 范围。**本 feature 只实现 MVG 要求的最小子集——一个主动技能“治疗”**（回复目标 HP），不引入被动技能/职业专属技/羁绊合击/龙痕觉醒（那些仍然是非目标）。
3. **音频资产缺失**：[D/18]/[D/19] 要求真实作曲/分层混音/事件音效，但 Notion AI 无法创作真实音乐/音效文件（同 [F/25] Q1 美术面临的问题一样）。**本 feature 新增一条镜像 Q1 的实现级决定**（不改 F/25，只在本 feature 内生效）：音频事件触发管线（BGM 分层/SFX 事件表）按 [D/18][D/19] 完整搭好，但数据指向的音频文件先用极简单的 WebAudio 振荡器合成占位音（非循环短音/无作曲性），等真实作曲/音效资产就绪后只换资源文件不改代码（因为本 feature 不碰真实数据，这个决定无需进 F/25，只是实现细节）。
4. **第 1 章内容尚未成型**：[B/11]（剧情主线）、第1章具体地图/敌配置尚未写入任何数据文件。**本 feature 前期 phase 先用合成测试地图验证渲染/交互管线**，待管线跑通后再在后续 phase 用真实第 1 章内容（地图/敌配/开场文本）替换，不影响已验证的代码。
5. **新发现（本次审计）：`BattleState`/`UnitInstance` 未定义的缺口**：本 feature 原本在 Phase 1 直接引用“`BattleState`（来自 M1 models）”，但实际审查 M1 的 idea.md/plan-p1.md 全文后发现 **M1 之前从未定义过这个类型**——M1 Phase 1 只有 3 张静态目录（`TERRAIN_DEFS`/`WEAPON_DEFS`/`UNIT_DEFS`）+ PRNG + 可达域纯函数，没有任何带 HP/位置的运行时实例模型。若把 `BattleState` 放到 M2 自己定义，会让尚未规划的 M1 Phase 2（战斗结算，也需要带 HP 的单位实例来表示战斗双方）反过来依赖 M2 的交付物，破坏 [F/24] 规定的 `M0 → M1 → M2` 单向依赖。**解决方案**：已在本次审计中补写进 M1 plan-p1.md 新增的 P1-T7（`src/models/battleState.ts` 导出 `BattleState`/`UnitInstance`，属 M1 Phase 1 交付物，严禁反向 import services），M2 只消费该类型，不自己定义。同样地，可达域服务 `computeReachable` 的输入网格已改为地形 **id** 二维数组（`string[][]`）而非完整 `TerrainDef[][]`，与 `BattleState.grid` 同形，避免 M2 需要额外做 id→对象的预转换。

## 本 feature 全范围核心需求（跨所有 phase，供后续 phase 规划时引用）

1. `src/entrypoints/main.ts` 真实组装：初始化 `BattleState`（类型来自 `src/models/battleState.ts`，M1 Phase 1 P1-T7 交付）、创建 `BattleViewModel`，注入给 `BattleScene`/`UIScene`，取代 M0 的空场景占位。
2. `BattleScene`（ui 层）渲染网格/地形/单位（占位色块美术，同 [F/25] Q1），只读 `BattleViewModel` 暴露的投影状态，不直接读 models/services（分层约束，[E/20]）。
3. 输入统一成 [E/20] 定义的 `Command`（`selectUnit`/`moveTo`/`attack`/`useSkill`/`endTurn`），Phaser pointer 事件翻译为 Command 上抛给 ViewModel。
4. `UIScene`（独立叠加场景）渲染 HUD：回合指示、单位信息面板、行动菜单、**伤害预览卡**（[C/17] 明确标注“P1 命门”）、地形信息、战报飘字——本 feature 只做功能最小集，不做精细视觉打磨。
5. 回合/阶段状态机完整化：`BattleState.phase` 支持 `'deploy'|'player'|'enemy'|'resolve'`（这 4 个值已在 M1 P1-T7 一次性定义完整，M1 Phase 1/2 自身只使用其中部分值，本 feature 负责实际驱动 `'deploy'` 阶段的使用）。
6. AI：按 [E/20] 分级，第 1 章敌人主要是“杂兵”，但 [A/01] MVG 明确要求“寻路+minimax AI”，因此实现一个深度可配（默认 1～2）的 Minimax，不做行为树/多阶段 Boss（那是 M3+ 精英/Boss 需要时才加）。
7. 最小技能：`useSkill` Command 支持一个 `heal` 技能（回复目标 HP，有射程/法力消耗概念可略）。
8. 最小存档：`localStorage` 保存/读取当前 `BattleState` 快照（包含 `rngState` 保证可复现，[E/21]），不做多槽位/永久死亡名单/版本迁移。
9. 过场：实现 [B/14] `CutsceneCmd` 子集（`bg`/`enter`/`line`/`shake`/`zoom`/`tint`/`sfx`/`bgm`/`wait`，不实现 `choice` ——分支选项属于多结局 M5+），写一段开场+结算过场验证 CutscenePlayer。
10. 音频：按本文件前文“发现的不一致之处 3”的决定，接入 WebAudio，事件触发管线完整，资源先用合成占位音。

## 非目标（整个 feature 都不做，不只是 Phase 1）

- 不实现完整第 1～24 章内容、不实现 35 角色/70 技能/转职树/羁绊支援会话。
- 不实现真实像素美术/动画差分/真实作曲——均用占位资源，后期按 [F/25] Q1 策略替换。
- 不做多结局/分支剧情/永久死亡机制——属于 M3+。
- 不做移动端/触屏适配（[F/25] Q4 桌面端优先）。

## 验收标准（全 feature。本轮只规划 Phase 1，其余条目待后续 phase 完成后才能打勾）

- [ ]（Phase 1）合成测试地图能在 `BattleScene` 中正确渲染（地形色块+单位块+网格线），可用鼠标选中单位并看到可移动高亮格，点击高亮格能真实移动单位。
- [ ]（后续 phase）伤害预览卡能正确显示伤害/命中/暴击/相克/反击。
- [ ]（后续 phase）Minimax AI 能在敌方回合自主移动+攻击。
- [ ]（后续 phase）`heal` 技能可用且数值正确。
- [ ]（后续 phase）关卡内快照可保存/读取，读档后 `rngState` 一致导致后续随机序列相同。
- [ ]（后续 phase）开场/结算过场可播放（bg/enter/line/wait 至少）。
- [ ]（后续 phase）单章可完整玩一遍（部署→战斗→胜利→结算过场），耗时在 30–50 分钟区间内（人工计时，非自动化断言）。

## 移交备注

1. 严格分 phase 推进，不要在 Phase 1 顺手写攻击/AI/存档/过场代码。
2. `src/ui/*` 只能 `import` `src/viewmodels/*`，不得直接 `import` `src/models/*` 或 `src/services/*`（即使看起来更方便）。**注意**：这比 M0 AGENTS.md 对 ui 层的描述（只说“禁止直接改 models”，没明确禁止读）更严格。本 feature 采用 [C/17] 明确说的更严格规则（ui 只能经由 viewmodels 访问下层，不得跳过 viewmodels 直达 services/models），并在 Phase 1 的 AGENTS.md 更新中明确写出这个比 M0 更严格的版本，避免后续执行者按 M0 较嬽的描述跳过 viewmodels 直接读 services/models。
3. 不要 `git add`/`git commit` `.github/features/**` 下的规划文件。
4. 每个 task 先验证再提交，commit subject 以稳定 task id 开头。
5. 本 feature 依赖 M1 的交付物：Phase 1 只依赖 M1 Phase 1（地形/单位数据+可达域+`BattleState`/`UnitInstance` 模型，后者已在本次审计中被补入 M1 plan-p1.md P1-T7），后续 phase（攻击/伤害预览）必须等 M1 Phase 2（战斗结算）完成并审计通过后才能开写。
6. 完成本 feature 全部 phase 后，进入对应 audit 闭环，确认通过后才能开始规划 M3（`m3-act1`）。
