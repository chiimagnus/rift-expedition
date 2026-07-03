import test from 'node:test'
import assert from 'node:assert/strict'
import { TERRAIN_DEFS, TERRAIN_BY_ID, type TerrainDef } from '@models/terrain'

test('M1: 地形完整收录 18 种', () => {
	assert.equal(TERRAIN_DEFS.length, 18)
	assert.equal(Object.keys(TERRAIN_BY_ID).length, 18)
})

// 代表性地形逐条数值断言（与 A/06 表格逐字核对）
const EXPECT: Record<string, Pick<TerrainDef, 'moveCost' | 'def' | 'avo'>> = {
	plain: { moveCost: { foot: 1, horse: 1, fly: 1 }, def: 0, avo: 0 },
	forest: { moveCost: { foot: 2, horse: 3, fly: 1 }, def: 1, avo: 20 },
	river: { moveCost: { foot: Infinity, horse: Infinity, fly: 1 }, def: 0, avo: 0 },
	cliff: { moveCost: { foot: Infinity, horse: Infinity, fly: 1 }, def: 0, avo: 0 },
	swamp: { moveCost: { foot: 2, horse: 3, fly: 1 }, def: 0, avo: 10 },
}

for (const [id, exp] of Object.entries(EXPECT)) {
	test(`M1: 地形数值正确 — ${id}`, () => {
		const t = TERRAIN_BY_ID[id]
		assert.ok(t, `缺少地形 ${id}`)
		assert.deepEqual(t.moveCost, exp.moveCost)
		assert.equal(t.def, exp.def)
		assert.equal(t.avo, exp.avo)
	})
}

test('M1: 毒沼与火山岩为 periodicDamage，其余非 periodicDamage', () => {
	assert.equal(TERRAIN_BY_ID['swamp'].effect, 'periodicDamage')
	assert.equal(TERRAIN_BY_ID['lava'].effect, 'periodicDamage')
	const periodic = TERRAIN_DEFS.filter((t) => t.effect === 'periodicDamage').map((t) => t.id)
	assert.deepEqual(periodic.sort(), ['lava', 'swamp'])
})

test('M1: 全部 18 种字段完整且 moveCost 均 >=1 或 Infinity', () => {
	for (const t of TERRAIN_DEFS) {
		assert.ok(typeof t.id === 'string' && t.id.length > 0)
		assert.ok(typeof t.name === 'string' && t.name.length > 0)
		assert.ok(Number.isFinite(t.def), `${t.id}.def 非有限数`)
		assert.ok(Number.isFinite(t.avo), `${t.id}.avo 非有限数`)
		for (const k of ['foot', 'horse', 'fly'] as const) {
			const c = t.moveCost[k]
			assert.ok(c === Infinity || (Number.isFinite(c) && c >= 1), `${t.id}.moveCost.${k}=${c} 非法`)
		}
	}
})
