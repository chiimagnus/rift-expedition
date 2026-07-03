// M1 P1-T5: 可达域计算服务（Dijkstra，四方向）。
// 依据 idea.md 核心需求 9 的修正：grid 为地形 id 的二维数组 string[][]（与 BattleState.grid 同型，行优先 grid[y][x]），
// 而非完整 TerrainDef[][]；本服务内部自行用 TERRAIN_BY_ID[id] 查具体移动代价。
// service 可 import models（反之禁止）；本阶段只算可达格集合，不做路径重建（属 M2）。

import { TERRAIN_BY_ID } from '@models/terrain'
import type { MoveType } from '@models/units'

export interface Point {
	x: number
	y: number
}

export function posKey(x: number, y: number): string {
	return `${x},${y}`
}

/**
 * 从 start 出发，按地形 moveCost[moveType] 加权的 Dijkstra，
 * 返回累加代价 <= movePower 的可达格集合（"x,y" 键）。
 * moveCost===Infinity 的格不可进入也不可穿越。起点代价为 0，总在集合内。
 */
export function computeReachable(
	grid: string[][],
	start: Point,
	moveType: MoveType,
	movePower: number,
): Set<string> {
	const height = grid.length
	const width = height > 0 ? grid[0].length : 0
	const reachable = new Set<string>()
	const inBounds = (x: number, y: number) => x >= 0 && y >= 0 && x < width && y < height
	if (!inBounds(start.x, start.y)) return reachable

	// 进入目标格的代价（非起点自身）。
	const enterCost = (x: number, y: number): number => {
		const t = TERRAIN_BY_ID[grid[y][x]]
		if (!t) return Infinity
		return t.moveCost[moveType]
	}

	const dist = new Map<string, number>()
	dist.set(posKey(start.x, start.y), 0)
	const frontier: Array<{ x: number; y: number; d: number }> = [
		{ x: start.x, y: start.y, d: 0 },
	]
	const dirs = [
		[1, 0],
		[-1, 0],
		[0, 1],
		[0, -1],
	]

	while (frontier.length > 0) {
		// 取当前最小代价节点（网格小，线性扫描即可）。
		let mi = 0
		for (let i = 1; i < frontier.length; i++) {
			if (frontier[i].d < frontier[mi].d) mi = i
		}
		const cur = frontier.splice(mi, 1)[0]
		const ck = posKey(cur.x, cur.y)
		if (cur.d > (dist.get(ck) ?? Infinity)) continue
		reachable.add(ck)

		for (const [dx, dy] of dirs) {
			const nx = cur.x + dx
			const ny = cur.y + dy
			if (!inBounds(nx, ny)) continue
			const c = enterCost(nx, ny)
			if (!Number.isFinite(c)) continue // 不可通行/不可穿越
			const nd = cur.d + c
			if (nd > movePower) continue
			const nk = posKey(nx, ny)
			if (nd < (dist.get(nk) ?? Infinity)) {
				dist.set(nk, nd)
				frontier.push({ x: nx, y: ny, d: nd })
			}
		}
	}
	return reachable
}
