import { getChapter, getTerrain } from "../data";
import type { BattleState, Cell, ChapterEvent, UnitInstance } from "../models/types";
import { classForUnit } from "./classes";
import { instantiateDeployment } from "./deployments";
import { hasSkill } from "./skillEffects";

export function processChapterEvents(state: BattleState, phase: ChapterEvent["phase"]): UnitInstance[] {
  const chapter = getChapter(state.chapterId);
  const spawned: UnitInstance[] = [];
  for (const event of chapter.events ?? []) {
    warnUpcomingEvent(state, event);
    if (event.phase !== phase || state.turn < event.turn || isResolved(state, event)) {
      continue;
    }
    spawned.push(...spawnReinforcements(state, event));
    state.flags[eventFlag(state, event, "resolved")] = true;
  }
  return spawned;
}

export function hasPendingHostileReinforcements(state: BattleState): boolean {
  return (getChapter(state.chapterId).events ?? []).some(
    (event) => !isResolved(state, event) && event.deployments.some((deployment) => deployment.team === "enemy"),
  );
}

function warnUpcomingEvent(state: BattleState, event: ChapterEvent): void {
  if (!event.telegraph || state.turn !== event.turn - 1 || isWarned(state, event)) {
    return;
  }
  state.flags[eventFlag(state, event, "warned")] = true;
  state.log.unshift(event.telegraph);
}

function spawnReinforcements(state: BattleState, event: ChapterEvent): UnitInstance[] {
  const spawned: UnitInstance[] = [];
  for (const deployment of event.deployments) {
    if (state.units.some((unit) => unit.id === deployment.instanceId)) {
      continue;
    }
    const unit = instantiateDeployment(deployment);
    if (!unit) {
      continue;
    }
    const spawn = spawnCellFor(state, unit, { x: deployment.x, y: deployment.y });
    if (!spawn) {
      continue;
    }
    unit.pos = spawn;
    if (event.ambush && unit.team === "enemy" && hasWatchfulAlly(state)) {
      unit.acted = true;
    }
    state.units.push(unit);
    spawned.push(unit);
  }
  if (event.message && spawned.length > 0) {
    state.log.unshift(event.message);
  }
  if (event.ambush && spawned.some((unit) => unit.team === "enemy" && unit.acted)) {
    state.log.unshift("警戒识破伏击，增援无法立即先手。");
  }
  return spawned;
}

function spawnCellFor(state: BattleState, unit: UnitInstance, origin: Cell): Cell | undefined {
  const occupied = new Set(state.units.filter((candidate) => candidate.alive).map((candidate) => cellKey(candidate.pos)));
  const candidates: Cell[] = [];
  for (let y = 0; y < state.grid.length; y += 1) {
    for (let x = 0; x < (state.grid[0]?.length ?? 0); x += 1) {
      candidates.push({ x, y });
    }
  }
  return candidates
    .filter((cell) => inBounds(state, cell) && !occupied.has(cellKey(cell)) && canStandOn(state, unit, cell))
    .sort((a, b) => distance(a, origin) - distance(b, origin) || a.y - b.y || a.x - b.x)[0];
}

function canStandOn(state: BattleState, unit: UnitInstance, cell: Cell): boolean {
  const terrainId = state.grid[cell.y]?.[cell.x];
  return terrainId ? getTerrain(terrainId).moveCost[classForUnit(unit).moveKind] != null : false;
}

function inBounds(state: BattleState, cell: Cell): boolean {
  return cell.y >= 0 && cell.y < state.grid.length && cell.x >= 0 && cell.x < (state.grid[0]?.length ?? 0);
}

function cellKey(cell: Cell): string {
  return `${cell.x},${cell.y}`;
}

function distance(a: Cell, b: Cell): number {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
}

function hasWatchfulAlly(state: BattleState): boolean {
  return state.units.some((unit) => unit.alive && unit.team === "ally" && hasSkill(unit, "watchful"));
}

function isWarned(state: BattleState, event: ChapterEvent): boolean {
  return state.flags[eventFlag(state, event, "warned")] === true;
}

function isResolved(state: BattleState, event: ChapterEvent): boolean {
  return state.flags[eventFlag(state, event, "resolved")] === true;
}

function eventFlag(state: BattleState, event: ChapterEvent, suffix: "warned" | "resolved"): string {
  return `chapterEvent:${state.chapterId}:${event.id}:${suffix}`;
}
