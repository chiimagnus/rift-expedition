import test from 'node:test'
import assert from 'node:assert/strict'
import { computeReachable } from '@services/reachable'

// 5x5 测试网格（行优先 grid[y][x]），含 3 种地形：
// - 中间一列 x=2 全部密林 thicket（步 3 / 骑 ∞ / 飞 1）——形成全高度墙
// - (1,3) 为河流 river（步 ∞ / 骑 ∞ / 飞 1）——对步/骑不可通行
// - 其余为平原 plain
const T = 'thicket'
const P = 'plain'
const R = 'river'
const grid: string[][] = [
	[P, P, T, P, P], // y=0
	[P, P, T, P, P], // y=1
	[P, P, T, P, P], // y=2
	[P, R, T, P, P], // y=3
	[P, P, T, P, P], // y=4
]
const start = { x: 0, y: 2 }

test('M1: 飞兵可直接穿越密林列到达右侧', () => {
	const r = computeReachable(grid, start, 'fly', 5)
	assert.ok(r.has('2,2'), '飞兵应能踩密林')
	assert.ok(r.has('4,2'), '飞兵应能穿越密林列到达 (4,2)')
})

test('M1: 骑兵不能进入密林，且被密林墙阻隔在左半区', () => {
	const r = computeReachable(grid, start, 'horse', 10)
	assert.ok(!r.has('2,2'), '骑兵不可进入密林')
	for (const k of r) {
		const x = Number(k.split(',')[0])
		assert.ok(x <= 1, `骑兵不应穿过密林墙到达 x>1，但到达了 ${k}`)
	}
})

test('M1: 步兵可跨密林但受移动力限制（power=5）', () => {
	const r = computeReachable(grid, start, 'foot', 5)
	assert.ok(r.has('2,2'), '步兵可踩密林（代价 4<=5）')
	assert.ok(r.has('3,2'), '步兵可跨过密林到 (3,2)（代价 5）')
	assert.ok(!r.has('4,2'), '(4,2) 代价 6>5，不可达')
})

test('M1: 步/骑均不可进入河流，飞兵可以', () => {
	assert.ok(!computeReachable(grid, start, 'foot', 10).has('1,3'), '步兵不可入河流')
	assert.ok(!computeReachable(grid, start, 'horse', 10).has('1,3'), '骑兵不可入河流')
	assert.ok(computeReachable(grid, start, 'fly', 10).has('1,3'), '飞兵可越河流')
})

test('M1: 同移动力下步兵可达格多于骑兵（因骑兵被密林墙封）', () => {
	const foot = computeReachable(grid, start, 'foot', 10)
	const horse = computeReachable(grid, start, 'horse', 10)
	assert.ok(foot.size > horse.size, `foot=${foot.size} horse=${horse.size}`)
})

test('M1: 起点总在可达集内', () => {
	assert.ok(computeReachable(grid, start, 'foot', 0).has('0,2'))
})
