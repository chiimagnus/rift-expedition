// M1 P1-T7: 运行时战斗状态模型（纯类型定义，无函数/无行为）。
// 供 M2 垂直切片消费；本阶段只含 M1/M2 用得到的最小字段集。
// E/21 额外列出的 bonds/dragonTaint/flags 属羁絆/龙痕觉醒/剧情分支机制（A/05 / B/11 / B/13），
// 要到 M3 才投入使用，本阶段刻意不提前加（YAGNI），待 M3 以“新增字段”方式向后兼容扩展。
//
// 重要：本文件严禁 import 任何 src/services/* 内容（哪怕 type-only import）——
// rngState 直接用 number，不引用 @services/prng 的 PrngState 类型别名（避免 models→services 反向依赖）。

export type Faction = 'player' | 'enemy'
export type BattlePhase = 'deploy' | 'player' | 'enemy' | 'resolve'

export interface UnitInstance {
	id: string
	unitDefId: string
	weaponId?: string
	faction: Faction
	pos: { x: number; y: number }
	hp: number
	hpMax: number
}

export interface BattleState {
	gridWidth: number
	gridHeight: number
	grid: string[][] // grid[y][x] = 地形 id（字符串），行优先
	units: UnitInstance[]
	phase: BattlePhase
	rngState: number // 与 E/20 PRNG 服务的 state 同型，但本文件不 import services
	turnCount: number
}
