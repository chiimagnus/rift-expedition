// M1 P1-T4: 单位数据模块（纯数据，无行为）。
// 只建 MVG 范围内的 3 个基础兵种（步/骑/飞）。
// base 属性取自 A/04「属性范围」区间中的代表值（体现兵种定位，不自发明数值）；
// growth 成长率逐条拄自 A/04「成长率」表（%），本阶段只声明、不参与任何计算（非目标）。

export type MoveType = 'foot' | 'horse' | 'fly'

export interface Stats {
	hp: number
	str: number
	mag: number
	skl: number
	spd: number
	lck: number
	def: number
	res: number
	mov: number
}

// 成长率（百分比），与 Stats 同键；本阶段不参与运算，仅声明。
export interface GrowthRates extends Record<keyof Stats, number> {}

export interface UnitDef {
	id: string
	name: string
	moveType: MoveType
	base: Stats
	growth: GrowthRates
	tags: string[] // 特攻标签匹配用，如 'flying'
}

export const UNIT_DEFS: UnitDef[] = [
	{
		id: 'infantry',
		name: '步兵',
		moveType: 'foot',
		// A/04 区间代表值：均衡全能、地形适应强，无突出爆发
		base: { hp: 22, str: 9, mag: 2, skl: 10, spd: 10, lck: 6, def: 7, res: 4, mov: 5 },
		// A/04 成长率：步兵剑士
		growth: { hp: 70, str: 45, mag: 5, skl: 55, spd: 55, lck: 40, def: 30, res: 20, mov: 0 },
		tags: [],
	},
	{
		id: 'cavalry',
		name: '骑兵',
		moveType: 'horse',
		// A/04 区间代表值：高机动、冲锋、转线快（换取林山禁行代价）
		base: { hp: 24, str: 10, mag: 2, skl: 8, spd: 8, lck: 5, def: 8, res: 3, mov: 7 },
		// A/04 成长率：骑兵枪骑
		growth: { hp: 75, str: 50, mag: 5, skl: 45, spd: 45, lck: 35, def: 35, res: 15, mov: 0 },
		tags: ['mounted'],
	},
	{
		id: 'flier',
		name: '飞兵',
		moveType: 'fly',
		// A/04 区间代表值：机动最高、无视地形、高速；低防、对空/弓特攻致命
		base: { hp: 20, str: 8, mag: 3, skl: 10, spd: 12, lck: 7, def: 5, res: 6, mov: 8 },
		// A/04 成长率：飞兵天马
		growth: { hp: 60, str: 40, mag: 10, skl: 55, spd: 60, lck: 45, def: 20, res: 30, mov: 0 },
		tags: ['flying'],
	},
]

export const UNIT_BY_ID: Record<string, UnitDef> = Object.fromEntries(
	UNIT_DEFS.map((u) => [u.id, u]),
)
