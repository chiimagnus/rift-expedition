import { getChapter, getTerrain } from "../data";
import type { BattleState, Cell, ChapterVisitReward, UnitInstance } from "../models/types";
import { findUnit } from "./chapter";

export interface VisitResult {
  ok: boolean;
  message: string;
}

export function visitAt(state: BattleState, cell: Cell): ChapterVisitReward | undefined {
  return (getChapter(state.chapterId).visits ?? []).find((visit) => visit.x === cell.x && visit.y === cell.y);
}

export function canVisit(state: BattleState, unit: UnitInstance): boolean {
  return state.phase === "player" && unit.team === "ally" && unit.alive && !unit.acted && visitForUnit(state, unit) != null;
}

export function visitChapterSite(state: BattleState, unitId: string): VisitResult {
  const unit = findUnit(state, unitId);
  const visit = visitForUnit(state, unit);
  if (!visit || unit.team !== "ally" || unit.acted || !unit.alive || state.phase !== "player") {
    return { ok: false, message: "当前位置没有可访问目标。" };
  }
  applyVisitReward(state, visit);
  unit.acted = true;
  state.flags[visitFlag(state, visit)] = true;
  state.log.unshift(visit.message);
  return { ok: true, message: visit.message };
}

export function visitSummary(state: BattleState, cell: Cell): string | undefined {
  const visit = visitAt(state, cell);
  if (!visit) {
    return undefined;
  }
  return isVisited(state, visit) ? `${visit.label}（已访问）` : `访问：${visit.label}`;
}

function visitForUnit(state: BattleState, unit: UnitInstance): ChapterVisitReward | undefined {
  const visit = visitAt(state, unit.pos);
  if (!visit || isVisited(state, visit) || !isVisitTerrain(state, unit.pos)) {
    return undefined;
  }
  return visit;
}

function applyVisitReward(state: BattleState, visit: ChapterVisitReward): void {
  if (visit.gold) {
    state.flags["battleReward:gold"] = Number(state.flags["battleReward:gold"] ?? 0) + visit.gold;
  }
  if (visit.weaponId) {
    const key = `battleReward:item:${visit.weaponId}`;
    state.flags[key] = Number(state.flags[key] ?? 0) + (visit.weaponCount ?? 1);
  }
  if (visit.flag) {
    state.flags[visit.flag] = visit.value ?? true;
  }
}

function isVisitTerrain(state: BattleState, cell: Cell): boolean {
  const terrainId = state.grid[cell.y]?.[cell.x];
  return terrainId ? getTerrain(terrainId).effects.includes("visit") : false;
}

function isVisited(state: BattleState, visit: ChapterVisitReward): boolean {
  return state.flags[visitFlag(state, visit)] === true;
}

function visitFlag(state: BattleState, visit: ChapterVisitReward): string {
  return `chapterVisit:${state.chapterId}:${visit.id}`;
}
