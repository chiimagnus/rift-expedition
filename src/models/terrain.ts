// M1 P1-T2: 地形数据模块（纯数据常量，无行为副作用）。
// 数值逐条拄自设计蓝图 A/06 地形系统表格（共 18 种）。
// moveCost 为 Infinity 表示该兵种不可通行/不可穿越。
// 本阶段只有「每回合扣血」（毒沼/火山岩）落地为可调用的 effect；
// 其余特殊效果（视野/回血/龙裔增益/坠落即死等）依赖尚不存在的系统，
// 仅作为 effectNote 文字记录，不写会被调用却什么都不做的占位函数（见 idea.md 核心需求 1）。

export type MoveCost = number // Infinity 表示不可通行

export interface TerrainDef {
	id: string
	name: string
	moveCost: { foot: MoveCost; horse: MoveCost; fly: MoveCost }
	def: number
	avo: number
	effect?: 'periodicDamage' | 'none'
	effectNote?: string // 仅文字记录，本阶段不执行
}

export const TERRAIN_DEFS: TerrainDef[] = [
	{ id: 'plain', name: '平原', moveCost: { foot: 1, horse: 1, fly: 1 }, def: 0, avo: 0, effect: 'none' },
	{ id: 'road', name: '道路', moveCost: { foot: 1, horse: 1, fly: 1 }, def: 0, avo: 0, effect: 'none', effectNote: '移动 ×0.75' },
	{ id: 'forest', name: '森林', moveCost: { foot: 2, horse: 3, fly: 1 }, def: 1, avo: 20, effect: 'none', effectNote: '骑兵掉速' },
	{ id: 'thicket', name: '密林', moveCost: { foot: 3, horse: Infinity, fly: 1 }, def: 2, avo: 30, effect: 'none', effectNote: '骑兵不可入' },
	{ id: 'mountain', name: '山地', moveCost: { foot: 3, horse: Infinity, fly: 1 }, def: 2, avo: 30, effect: 'none', effectNote: '骑兵不可入' },
	{ id: 'peak', name: '山峰', moveCost: { foot: 4, horse: Infinity, fly: 1 }, def: 3, avo: 40, effect: 'none', effectNote: '仅步/飞，射程视野+' },
	{ id: 'fort', name: '要塞', moveCost: { foot: 2, horse: 2, fly: 1 }, def: 2, avo: 20, effect: 'none', effectNote: '每回合回血 10%（回合开始结算，本阶段不实现）' },
	{ id: 'village', name: '村庄', moveCost: { foot: 1, horse: 1, fly: 1 }, def: 1, avo: 10, effect: 'none', effectNote: '可访问：剧情/道具' },
	{ id: 'river', name: '河流', moveCost: { foot: Infinity, horse: Infinity, fly: 1 }, def: 0, avo: 0, effect: 'none', effectNote: '仅飞兵可越' },
	{ id: 'shallows', name: '浅滩', moveCost: { foot: 3, horse: 4, fly: 1 }, def: 0, avo: -10, effect: 'none', effectNote: '可涉水但迟缓' },
	{ id: 'bridge', name: '桥', moveCost: { foot: 1, horse: 1, fly: 1 }, def: 0, avo: 0, effect: 'none', effectNote: '兵家必争卡口' },
	{ id: 'sand', name: '沙地', moveCost: { foot: 2, horse: 3, fly: 1 }, def: 0, avo: 0, effect: 'none', effectNote: '骑兵掉速' },
	{ id: 'swamp', name: '毒沼', moveCost: { foot: 2, horse: 3, fly: 1 }, def: 0, avo: 10, effect: 'periodicDamage', effectNote: '每回合扣血' },
	{ id: 'lava', name: '火山岩', moveCost: { foot: 2, horse: Infinity, fly: 1 }, def: 0, avo: 0, effect: 'periodicDamage', effectNote: '随机喷发区域伤害' },
	{ id: 'ruins', name: '废墟', moveCost: { foot: 2, horse: 2, fly: 1 }, def: 1, avo: 15, effect: 'none', effectNote: '视野遮挡' },
	{ id: 'dragonAltar', name: '龙痕祭坛', moveCost: { foot: 1, horse: 1, fly: 1 }, def: 1, avo: 10, effect: 'none', effectNote: '龙裔增益、剧情锚点' },
	{ id: 'throne', name: '王座', moveCost: { foot: 1, horse: 1, fly: 1 }, def: 3, avo: 30, effect: 'none', effectNote: 'Boss 回血、通关点' },
	{ id: 'cliff', name: '断崖', moveCost: { foot: Infinity, horse: Infinity, fly: 1 }, def: 0, avo: 0, effect: 'none', effectNote: '仅飞兵；坠落即死机制本阶段不实现（def/avo 表格为—，此处记 0）' },
]

export const TERRAIN_BY_ID: Record<string, TerrainDef> = Object.fromEntries(
	TERRAIN_DEFS.map((t) => [t.id, t]),
)
