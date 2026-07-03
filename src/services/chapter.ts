import { getChapter, getUnitDef } from "../data";
import type { BattleState, CampaignState, RosterEntry, UnitInstance } from "../models/types";

export function createInitialBattleState(chapterId = "ch01", campaign?: CampaignState): BattleState {
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

  const units: UnitInstance[] = chapter.deployments.flatMap((deployment) => {
    const unitDef = getUnitDef(deployment.unitDefId);
    const rosterEntry = deployment.team === "ally" ? campaign?.roster.find((entry) => entry.unitDefId === unitDef.id) : undefined;
    if (deployment.team === "ally" && ((campaign?.mode === "classic" && campaign.fallen.includes(unitDef.id)) || rosterEntry?.deployed === false)) {
      return [];
    }
    const weaponId = deployment.team === "ally" ? rosterEntry?.weaponId ?? deployment.weaponId ?? unitDef.weaponIds[0] : deployment.weaponId ?? unitDef.weaponIds[0];
    if (!weaponId) {
      throw new Error(`Unit ${unitDef.id} has no weapon`);
    }
    return [{
      id: deployment.instanceId,
      defId: unitDef.id,
      team: deployment.team,
      hp: rosterEntry?.stats.hp ?? unitDef.baseStats.hp,
      stats: { ...(rosterEntry?.stats ?? unitDef.baseStats) },
      weaponId,
      skillIds: [...(rosterEntry?.skillIds ?? unitDef.skillIds)],
      statuses: [],
      skillUses: {},
      pos: { x: deployment.x, y: deployment.y },
      acted: false,
      alive: true,
      level: rosterEntry?.level ?? unitDef.level,
      exp: rosterEntry?.exp ?? 0,
    }];
  });

  return {
    chapterId: chapter.id,
    turn: 1,
    phase: campaign ? "deploy" : "player",
    grid,
    units,
    rngState: campaign?.seed ?? 0x5eedc0de,
    bonds: { ...(campaign?.bonds ?? {}) },
    flags: {
      ...(campaign?.flags ?? {}),
      "dragonTaint:aldric": campaign?.taint.aldric ?? 0,
      "dragonTaint:elara": campaign?.taint.elara ?? 0,
    },
    log: [...chapter.opening].reverse(),
  };
}

export function createRosterEntry(unitDefId: string, weaponId?: string): RosterEntry {
  const unitDef = getUnitDef(unitDefId);
  const entryWeaponId = weaponId ?? unitDef.weaponIds[0];
  if (!entryWeaponId) {
    throw new Error(`Unit ${unitDef.id} has no weapon`);
  }
  return {
    unitDefId: unitDef.id,
    level: unitDef.level,
    exp: 0,
    stats: { ...unitDef.baseStats },
    weaponId: entryWeaponId,
    weaponIds: [...new Set(unitDef.weaponIds)],
    skillIds: [...unitDef.skillIds],
    deployed: true,
  };
}

export function cloneBattleState(state: BattleState): BattleState {
  return {
    ...state,
    grid: state.grid.map((row) => [...row]),
    units: state.units.map((unit) => ({
      ...unit,
      stats: { ...unit.stats },
      statuses: unit.statuses.map((status) => ({ ...status })),
      skillUses: { ...unit.skillUses },
      pos: { ...unit.pos },
    })),
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
