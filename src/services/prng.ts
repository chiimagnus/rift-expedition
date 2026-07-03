// M1 P1-T1: 可注入种子的确定性 PRNG（mulberry32）。
// 纯函数式：state 为可序列化的 number（对应 E/21 BattleState.rngState），
// next(state) => [value, newState]。战斗结算与平衡 CLI 全程通过本服务取随机数，
// 禁止在其它任何地方直接调用 Math.random（见根 AGENTS.md / A03 可调参表说明）。

export type PrngState = number

/** 归一化任意 number 为无符号 32 位种子。 */
export function seed(n: number): PrngState {
	return n >>> 0
}

/**
 * mulberry32：给定 state，返回 [0,1) 的随机值与新的 state。
 * 相同 state 必产生相同 [value, newState]，保证战斗可复现。
 */
export function next(state: PrngState): [number, PrngState] {
	let t = (state + 0x6d2b79f5) >>> 0
	t = Math.imul(t ^ (t >>> 15), t | 1)
	t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
	const value = ((t ^ (t >>> 14)) >>> 0) / 4294967296
	return [value, t >>> 0]
}
