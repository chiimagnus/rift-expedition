import test from 'node:test'
import assert from 'node:assert/strict'
import { seed, next } from '@services/prng'

test('M1: PRNG 确定性——相同种子产生相同序列', () => {
	const a = seed(12345)
	const b = seed(12345)
	const [v1, a1] = next(a)
	const [w1, b1] = next(b)
	assert.equal(v1, w1)
	const [v2] = next(a1)
	const [w2] = next(b1)
	assert.equal(v2, w2)
})

test('M1: PRNG 连续两次调用产生不同值', () => {
	const s = seed(999)
	const [v1, s1] = next(s)
	const [v2] = next(s1)
	assert.notEqual(v1, v2)
})

test('M1: PRNG 值域在 [0,1) 且 10000 次均值接近 0.5', () => {
	let s = seed(42)
	let sum = 0
	const N = 10000
	for (let i = 0; i < N; i++) {
		const [v, ns] = next(s)
		assert.ok(v >= 0 && v < 1, `value out of range: ${v}`)
		sum += v
		s = ns
	}
	const mean = sum / N
	assert.ok(mean > 0.45 && mean < 0.55, `mean=${mean}`)
})
