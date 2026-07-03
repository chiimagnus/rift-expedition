// M1 P1-T3: 武器/魔法相克矩阵与 COMBAT 可调参表（纯数据，无行为）。
// 矩阵方向与数值来自设计蓝图 A/03：剑克斧 / 斧克枪 / 枪克剑（循环），
// +1 克制 / -1 被克 / 0 互不影响；每行之和必为 0（无支配策略）。
// COMBAT 集中所有系数（A/03 第七节可调参表，单一事实源）。

export type WeaponType = 'sword' | 'axe' | 'lance' | 'bow'
export type MagicType = 'fire' | 'ice' | 'thunder'

export interface WeaponDef {
	id: string
	type: WeaponType
	might: number
	hit: number
	crit: number
	minRange: number // 弓=1..2，其余近战=1..1
	maxRange: number
	antiAirBonus?: boolean // 对空特攻标记，供 P1-T4 单位 'flying' tag 在 Phase 2 匹配
}

// A/03 武器三角回报矩阵（行=攻方，列=守方）。缺失键视为 0。
export const WEAPON_TRIANGLE: Record<WeaponType, Partial<Record<WeaponType, number>>> = {
	sword: { axe: 1, lance: -1 },
	axe: { lance: 1, sword: -1 },
	lance: { sword: 1, axe: -1 },
	bow: {},
}

// A/03 魔法三系回报矩阵（炎克冰 / 冰克雷 / 雷克炎）。
export const MAGIC_TRIANGLE: Record<MagicType, Partial<Record<MagicType, number>>> = {
	fire: { ice: 1, thunder: -1 },
	ice: { thunder: 1, fire: -1 },
	thunder: { fire: 1, ice: -1 },
}

// A/03 第七节可调参表（单一事实源）。
export const COMBAT = {
	minDamage: 1,
	counterHit: 15,
	counterMight: 1,
	doublingThreshold: 4,
	critFromSkill: 0.5,
	doubleRNG: true,
	effMultiplier: 3,
} as const

// 武器实例：剑/斧/枪/弓各一件。
// 受 A/03 数值演算示例锚定的数值：铁剑 威5 命90 暴0（示例①）、强弓 威9 对空（示例③）。
// 斧/枪 A/03 未给出具体数值表，此处按武器三角典型取舍定价（斧：高威力低命中；枪：均衡），
// 待 A/09 平衡模拟（Phase 3）回调；不影响本阶段矩阵行和=0 与 COMBAT 常量验收。
export const WEAPON_DEFS: WeaponDef[] = [
	{ id: 'ironSword', type: 'sword', might: 5, hit: 90, crit: 0, minRange: 1, maxRange: 1 },
	{ id: 'ironAxe', type: 'axe', might: 8, hit: 75, crit: 0, minRange: 1, maxRange: 1 },
	{ id: 'ironLance', type: 'lance', might: 7, hit: 80, crit: 0, minRange: 1, maxRange: 1 },
	{ id: 'strongBow', type: 'bow', might: 9, hit: 85, crit: 0, minRange: 1, maxRange: 2, antiAirBonus: true },
]

export const WEAPON_BY_ID: Record<string, WeaponDef> = Object.fromEntries(
	WEAPON_DEFS.map((w) => [w.id, w]),
)
