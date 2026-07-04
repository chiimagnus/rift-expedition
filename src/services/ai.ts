import { getWeapon } from "../data";
import type { AiAction, BattleState, Cell, UnitInstance } from "../models/types";
import { findUnit, livingUnits, unitAt, updateOutcome } from "./chapter";
import { processChapterEvents } from "./chapterEvents";
import { forecastCombat, resolveCombat } from "./combat";
import { remainingWeaponUses } from "./equipment";
import { cellKey, distance, moveUnit, reachableCells } from "./movement";
import { refreshRound } from "./skills";
import { canUnitAttackAtDistance } from "./skillEffects";

export function chooseEnemyAction(state: BattleState, enemy: UnitInstance): AiAction {
  const tauntSourceId = enemy.statuses.find((status) => status.id === "taunted" && status.turns > 0)?.sourceId;
  const tauntTarget = tauntSourceId ? state.units.find((unit) => unit.id === tauntSourceId && unit.alive) : undefined;
  if (tauntTarget) {
    const forced = bestAttackAction(state, enemy, [tauntTarget]);
    if (forced) {
      return forced.action;
    }
  }
  const best = bestAttackAction(state, enemy, livingUnits(state, "ally"));
  if (best) {
    return best.action;
  }

  const closest = livingUnits(state, "ally").sort((a, b) => distance(enemy.pos, a.pos) - distance(enemy.pos, b.pos))[0];
  if (!closest) {
    return { unitId: enemy.id, moveTo: enemy.pos };
  }

  // ponytail: one-ply pursuit for M0; replace with depth 2-3 minimax when more enemy archetypes land.
  const moveTo =
    [...reachableCells(state, enemy).values()]
      .filter(({ cell }) => !unitAt(state, cell.x, cell.y) || cellKey(cell) === cellKey(enemy.pos))
      .sort((a, b) => distance(a.cell, closest.pos) - distance(b.cell, closest.pos))[0]?.cell ?? enemy.pos;
  return { unitId: enemy.id, moveTo };
}

function bestAttackAction(state: BattleState, enemy: UnitInstance, targets: UnitInstance[]): { action: AiAction; score: number } | undefined {
  const reachable = reachableCells(state, enemy);
  let best: { action: AiAction; score: number } | undefined;

  for (const { cell } of reachable.values()) {
    for (const target of targets) {
      const cells = distance(cell, target.pos);
      const weapon = getWeapon(enemy.weaponId);
      if (remainingWeaponUses(enemy) <= 0 || !canUnitAttackAtDistance(enemy, weapon, cells) || weapon.damageKind === "healing") {
        continue;
      }
      const original = enemy.pos;
      enemy.pos = cell;
      const forecast = forecastCombat(state, enemy.id, target.id);
      enemy.pos = original;
      const killBonus = forecast.damage >= target.hp ? 100 : 0;
      const score = killBonus + forecast.damage * 4 + forecast.hit + forecast.effectiveMultiplier * 10 - target.hp;
      if (!best || score > best.score) {
        best = { action: { unitId: enemy.id, moveTo: cell, attackTargetId: target.id }, score };
      }
    }
  }
  return best;
}

export function runEnemyTurn(state: BattleState): void {
  state.phase = "enemy";
  processChapterEvents(state, "enemyStart");
  for (const enemy of livingUnits(state, "enemy")) {
    if (isTerminalPhase(state.phase)) {
      break;
    }
    if (enemy.acted) {
      continue;
    }
    const action = chooseEnemyAction(state, enemy);
    executeAiAction(state, action);
    enemy.acted = true;
    updateOutcome(state);
  }

  if (!isTerminalPhase(state.phase)) {
    state.turn += 1;
    for (const unit of state.units) {
      unit.acted = false;
    }
    refreshRound(state);
    state.phase = "player";
    state.log.unshift(`第 ${state.turn} 回合。`);
    processChapterEvents(state, "playerStart");
    updateOutcome(state);
  }
}

function isTerminalPhase(phase: string): boolean {
  return phase === "victory" || phase === "defeat";
}

function executeAiAction(state: BattleState, action: AiAction): void {
  const unit = findUnit(state, action.unitId);
  moveUnit(state, unit, action.moveTo);
  if (action.attackTargetId) {
    const target = findUnit(state, action.attackTargetId);
    if (target.alive) {
      resolveCombat(state, unit.id, target.id);
    }
  }
}

export function attackableEnemiesFrom(state: BattleState, unit: UnitInstance, cell: Cell): UnitInstance[] {
  const weapon = getWeapon(unit.weaponId);
  if (remainingWeaponUses(unit) <= 0) {
    return [];
  }
  return livingUnits(state, unit.team === "ally" ? "enemy" : "ally").filter((target) => canUnitAttackAtDistance(unit, weapon, distance(cell, target.pos)));
}
