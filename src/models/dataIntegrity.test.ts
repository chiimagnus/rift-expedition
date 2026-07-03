// M1 P1-T6: 跨模块数据引用完整性单测。
// 不新增任何运行时校验代码（idea.md 核心需求 8：TS 联合类型已提供编译期安全），
// 只补充编译期无法捕捉的跨模块一致性，作为三个数据模块写好后的一次交叉安全网。
import test from 'node:test'
import assert from 'node:assert/strict'
import { UNIT_DEFS } from '@models/units'
import { WEAPON_DEFS, WEAPON_TRIANGLE } from '@models/weapons'
import { TERRAIN_DEFS } from '@models/terrain'

test('M1: units 内部一致——含 flying tag 的单位 moveType 必为 fly', () => {
	for (const u of UNIT_DEFS) {
		if (u.tags.includes('flying')) {
			assert.equal(u.moveType, 'fly', `${u.id} 带 flying 但 moveType=${u.moveType}`)
		}
	}
})

test('M1: 每件武器的 type 都在 WEAPON_TRIANGLE 的 key 集合中（含 bow）', () => {
	const keys = new Set(Object.keys(WEAPON_TRIANGLE))
	for (const w of WEAPON_DEFS) {
		assert.ok(keys.has(w.type), `武器 ${w.id} 的 type=${w.type} 不在相克矩阵 key 中`)
	}
})

test('M1: 地形所有 moveCost 都是 >=1 或 Infinity（无 0/负数）', () => {
	for (const t of TERRAIN_DEFS) {
		for (const k of ['foot', 'horse', 'fly'] as const) {
			const c = t.moveCost[k]
			assert.ok(
				c === Infinity || (Number.isFinite(c) && c >= 1),
				`${t.id}.moveCost.${k}=${c} 非法（应 >=1 或 Infinity）`,
			)
		}
	}
})
