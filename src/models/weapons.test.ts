import test from 'node:test'
import assert from 'node:assert/strict'
import {
	WEAPON_TRIANGLE,
	MAGIC_TRIANGLE,
	COMBAT,
	WEAPON_DEFS,
	WEAPON_BY_ID,
	type WeaponType,
	type MagicType,
} from '@models/weapons'

// 通用行和断言：对每个类型，把它对其他所有类型的优势值求和（缺失键视为 0），应为 0。
function assertRowSumsZero<T extends string>(
	triangle: Record<T, Partial<Record<T, number>>>,
) {
	const types = Object.keys(triangle) as T[]
	for (const attacker of types) {
		let sum = 0
		for (const defender of types) {
			sum += triangle[attacker][defender] ?? 0
		}
		assert.equal(sum, 0, `${attacker} 行和不为 0`)
	}
}

test('M1: 武器三角矩阵每行和为 0', () => {
	assertRowSumsZero<WeaponType>(WEAPON_TRIANGLE)
})

test('M1: 魔法三系矩阵每行和为 0', () => {
	assertRowSumsZero<MagicType>(MAGIC_TRIANGLE)
})

test('M1: 武器三角方向性与 A/03 一致（剑克斧/斧克枪/枪克剑）', () => {
	assert.equal(WEAPON_TRIANGLE.sword.axe, 1)
	assert.equal(WEAPON_TRIANGLE.axe.lance, 1)
	assert.equal(WEAPON_TRIANGLE.lance.sword, 1)
	assert.equal(WEAPON_TRIANGLE.sword.lance, -1)
	assert.deepEqual(WEAPON_TRIANGLE.bow, {})
})

test('M1: 魔法三系方向性与 A/03 一致（炎克冰/冰克雷/雷克炎）', () => {
	assert.equal(MAGIC_TRIANGLE.fire.ice, 1)
	assert.equal(MAGIC_TRIANGLE.ice.thunder, 1)
	assert.equal(MAGIC_TRIANGLE.thunder.fire, 1)
})

test('M1: COMBAT 关键常量与 A/03/E22 一致', () => {
	assert.equal(COMBAT.minDamage, 1)
	assert.equal(COMBAT.counterHit, 15)
	assert.equal(COMBAT.counterMight, 1)
	assert.equal(COMBAT.doublingThreshold, 4)
	assert.equal(COMBAT.critFromSkill, 0.5)
	assert.equal(COMBAT.doubleRNG, true)
	assert.equal(COMBAT.effMultiplier, 3)
})

test('M1: 弓为 1-2 射程且带对空特攻，近战武器为 1-1', () => {
	const bow = WEAPON_BY_ID['strongBow']
	assert.equal(bow.minRange, 1)
	assert.equal(bow.maxRange, 2)
	assert.equal(bow.antiAirBonus, true)
	for (const id of ['ironSword', 'ironAxe', 'ironLance']) {
		assert.equal(WEAPON_BY_ID[id].minRange, 1)
		assert.equal(WEAPON_BY_ID[id].maxRange, 1)
	}
	assert.equal(WEAPON_DEFS.length, 4)
})
