import { getClass, getTerrain, getUnitDef } from "../data";
import type { BattleState, Cell, UnitInstance } from "../models/types";
import { unitAt } from "./chapter";
import { effectiveStats } from "./status";

export function cellKey(cell: Cell): string {
  return `${cell.x},${cell.y}`;
}

export function distance(a: Cell, b: Cell): number {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
}

export function inBounds(state: BattleState, cell: Cell): boolean {
  return cell.y >= 0 && cell.y < state.grid.length && cell.x >= 0 && cell.x < (state.grid[0]?.length ?? 0);
}

export function terrainAt(state: BattleState, cell: Cell) {
  const terrainId = state.grid[cell.y]?.[cell.x];
  if (!terrainId) {
    throw new Error(`Out of bounds terrain lookup at ${cell.x},${cell.y}`);
  }
  return getTerrain(terrainId);
}

export function movementCost(state: BattleState, unit: UnitInstance, cell: Cell): number | null {
  if (!inBounds(state, cell)) {
    return null;
  }
  const unitDef = getUnitDef(unit.defId);
  const classDef = getClass(unitDef.classId);
  const terrain = terrainAt(state, cell);
  return terrain.moveCost[classDef.moveKind];
}

export function reachableCells(state: BattleState, unit: UnitInstance): Map<string, { cell: Cell; cost: number }> {
  const start = unit.pos;
  const best = new Map<string, { cell: Cell; cost: number }>();
  const frontier: Array<{ cell: Cell; cost: number }> = [{ cell: start, cost: 0 }];
  best.set(cellKey(start), { cell: start, cost: 0 });

  while (frontier.length > 0) {
    frontier.sort((a, b) => a.cost - b.cost);
    const current = frontier.shift();
    if (!current) {
      break;
    }

    for (const next of neighbors(current.cell)) {
      const cost = movementCost(state, unit, next);
      if (cost == null) {
        continue;
      }
      const occupant = unitAt(state, next.x, next.y);
      if (occupant && occupant.id !== unit.id) {
        continue;
      }
      const nextCost = current.cost + cost;
      if (nextCost > effectiveStats(unit).move) {
        continue;
      }
      const key = cellKey(next);
      const known = best.get(key);
      if (!known || nextCost < known.cost) {
        best.set(key, { cell: next, cost: nextCost });
        frontier.push({ cell: next, cost: nextCost });
      }
    }
  }

  return best;
}

export function canOccupy(state: BattleState, unit: UnitInstance, cell: Cell): boolean {
  const reachable = reachableCells(state, unit);
  const occupant = unitAt(state, cell.x, cell.y);
  return reachable.has(cellKey(cell)) && (!occupant || occupant.id === unit.id);
}

export function moveUnit(state: BattleState, unit: UnitInstance, cell: Cell): boolean {
  if (!canOccupy(state, unit, cell)) {
    return false;
  }
  unit.pos = { ...cell };
  return true;
}

export function neighbors(cell: Cell): Cell[] {
  return [
    { x: cell.x + 1, y: cell.y },
    { x: cell.x - 1, y: cell.y },
    { x: cell.x, y: cell.y + 1 },
    { x: cell.x, y: cell.y - 1 },
  ];
}
