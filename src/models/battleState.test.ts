import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import type { BattleState } from '@models/battleState'

test('M1: battleState.ts 源码不引用 services 层（字符串扫描）', () => {
	const src = readFileSync(
		fileURLToPath(new URL('./battleState.ts', import.meta.url)),
		'utf8',
	)
	assert.ok(!src.includes("from '@services"), '不得出现 from \'@services')
	assert.ok(!src.includes("from '../services"), '不得出现 from \'../services')
})

test('M1: 可构造符合类型的最小 BattleState 字面量', () => {
	const state: BattleState = {
		gridWidth: 2,
		gridHeight: 1,
		grid: [['plain', 'forest']],
		units: [
			{
				id: 'u1',
				unitDefId: 'infantry',
				weaponId: 'ironSword',
				faction: 'player',
				pos: { x: 0, y: 0 },
				hp: 22,
				hpMax: 22,
			},
		],
		phase: 'player',
		rngState: 42,
		turnCount: 1,
	}
	assert.equal(state.units.length, 1)
	assert.equal(state.grid[0][1], 'forest')
	assert.equal(state.phase, 'player')
})
