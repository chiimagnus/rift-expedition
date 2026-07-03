import test from 'node:test'
import assert from 'node:assert/strict'
import { UNIT_DEFS, UNIT_BY_ID, type Stats } from '@models/units'

const STAT_KEYS: (keyof Stats)[] = ['hp', 'str', 'mag', 'skl', 'spd', 'lck', 'def', 'res', 'mov']

test('M1: 只有 3 个基础兵种', () => {
	assert.equal(UNIT_DEFS.length, 3)
})

test('M1: moveType 与 id 命名对应（infantry→foot / cavalry→horse / flier→fly）', () => {
	assert.equal(UNIT_BY_ID['infantry'].moveType, 'foot')
	assert.equal(UNIT_BY_ID['cavalry'].moveType, 'horse')
	assert.equal(UNIT_BY_ID['flier'].moveType, 'fly')
})

test('M1: 飞兵包含 flying tag', () => {
	assert.ok(UNIT_BY_ID['flier'].tags.includes('flying'))
})

test('M1: 所有 base/growth 字段均为有限数字', () => {
	for (const u of UNIT_DEFS) {
		for (const k of STAT_KEYS) {
			assert.ok(Number.isFinite(u.base[k]), `${u.id}.base.${k} 非有限数`)
			assert.ok(Number.isFinite(u.growth[k]), `${u.id}.growth.${k} 非有限数`)
		}
	}
})
