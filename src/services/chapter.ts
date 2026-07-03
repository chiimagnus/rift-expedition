import { getChapter, getUnitDef } from "../data";
import type { BattleState, UnitInstance } from "../models/types";

export function createInitialBattleState(chapterId = "ch01"): BattleState {
  const chapter = getChapter(chapterId);
  const grid = chapter.map.map((row) =>
    [...row].map((symbol) => {
      const terrainId = chapter.terrainLegend[symbol];
      if (!terrainId) {
        throw new Error(`Unknown terrain symbol "${symbol}" in ${chapter.id}`);
      }
      return terrainId;
    }),
  );

  const units: UnitInstance[] = chapter.deployments.map((deployment) => {
    const unitDef = getUnitDef(deployment.unitDefId);
    const weaponId = deployment.weaponId ?? unitDef.weaponIds[0];
    if (!weaponId) {
      throw new Error(`Unit ${unitDef.id} has no weapon`);
    }
    return {
      id: deployment.instanceId,
      defId: unitDef.id,
      team: deployment.team,
      hp: unitDef.baseStats.hp,
      stats: { ...unitDef.baseStats },
      weaponId,
      skillIds: [...unitDef.skillIds],
      pos: { x: deployment.x, y: deployment.y },
      acted: false,
      alive: true,
      level: unitDef.level,
      exp: 0,
    };
  });

  return {
    chapterId: chapter.id,
    turn: 1,
    phase: "player",
    grid,
    units,
    rngState: 0x5eedc0de,
    bonds: {},
    flags: { dragonTaintAldric: 0, dragonTaintElara: 0 },
    log: [...chapter.opening].reverse(),
  };
}

export function cloneBattleState(state: BattleState): BattleState {
  return {
    ...state,
    grid: state.grid.map((row) => [...row]),
    units: state.units.map((unit) => ({ ...unit, stats: { ...unit.stats }, pos: { ...unit.pos } })),
    bonds: { ...state.bonds },
    flags: { ...state.flags },
    log: [...state.log],
  };
}

export function findUnit(state: BattleState, unitId: string): UnitInstance {
  const unit = state.units.find((candidate) => candidate.id === unitId);
  if (!unit) {
    throw new Error(`Unknown unit: ${unitId}`);
  }
  return unit;
}

export function livingUnits(state: BattleState, team?: "ally" | "enemy"): UnitInstance[] {
  return state.units.filter((unit) => unit.alive && (!team || unit.team === team));
}

export function unitAt(state: BattleState, x: number, y: number): UnitInstance | undefined {
  return state.units.find((unit) => unit.alive && unit.pos.x === x && unit.pos.y === y);
}

export function updateOutcome(state: BattleState): void {
  const allies = livingUnits(state, "ally");
  const enemies = livingUnits(state, "enemy");
  if (allies.length === 0) {
    state.phase = "defeat";
    state.log.unshift("我方全灭。宿命暂时吞没了抵抗。");
  } else if (enemies.length === 0) {
    state.phase = "victory";
    state.log.unshift("北境先锋撤退。奥德里克与艾拉菈都记住了彼此的眼神。");
  }
}
