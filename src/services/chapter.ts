import { getChapter, getUnitDef } from "../data";
import type { BattleState, CampaignState, ChapterDefeatCondition, ChapterVictoryCondition, RosterEntry, UnitInstance } from "../models/types";
import { normalizeWeaponForge, normalizeWeaponUses } from "./equipment";

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
    const weaponIds = deployment.team === "ally" ? rosterEntry?.weaponIds ?? [weaponId] : [weaponId];
    const carriedWeaponIds = weaponIds.includes(weaponId) ? weaponIds : [...weaponIds, weaponId];
    return [{
      id: deployment.instanceId,
      defId: unitDef.id,
      team: deployment.team,
      classId: deployment.team === "ally" ? rosterEntry?.classId ?? unitDef.classId : unitDef.classId,
      hp: rosterEntry?.stats.hp ?? unitDef.baseStats.hp,
      stats: { ...(rosterEntry?.stats ?? unitDef.baseStats) },
      weaponId,
      weaponUses: normalizeWeaponUses(carriedWeaponIds, rosterEntry?.weaponUses),
      weaponForge: normalizeWeaponForge(carriedWeaponIds, rosterEntry?.weaponForge),
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
  const weaponIds = [...new Set([...unitDef.weaponIds, entryWeaponId])];
  return {
    unitDefId: unitDef.id,
    classId: unitDef.classId,
    level: unitDef.level,
    exp: 0,
    stats: { ...unitDef.baseStats },
    weaponId: entryWeaponId,
    weaponIds,
    weaponUses: normalizeWeaponUses(weaponIds),
    weaponForge: normalizeWeaponForge(weaponIds),
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
      weaponUses: { ...unit.weaponUses },
      weaponForge: { ...unit.weaponForge },
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
  if (state.phase === "victory" || state.phase === "defeat") {
    return;
  }
  const chapter = getChapter(state.chapterId);
  const allies = livingUnits(state, "ally");
  if (allies.length === 0) {
    state.phase = "defeat";
    state.log.unshift("我方全灭。宿命暂时吞没了抵抗。");
    return;
  }
  const failedCondition = chapter.defeatConditions?.find((condition) => isDefeatConditionMet(state, condition));
  if (failedCondition) {
    state.phase = "defeat";
    state.log.unshift(defeatConditionText(state, failedCondition));
    return;
  }

  if (isVictoryConditionMet(state, chapter.victoryCondition ?? { type: "rout" })) {
    state.phase = "victory";
    state.log.unshift(victoryConditionText(chapter.victoryCondition ?? { type: "rout" }));
  }
}

function isVictoryConditionMet(state: BattleState, condition: ChapterVictoryCondition): boolean {
  if (condition.type === "rout") {
    return livingUnits(state, "enemy").length === 0;
  }
  if (condition.type === "defeatBoss") {
    return condition.targetInstanceIds.every((unitId) => {
      const target = state.units.find((unit) => unit.id === unitId);
      return target ? !target.alive : false;
    });
  }
  if (condition.type === "survive") {
    return state.turn > condition.turns;
  }
  if (condition.type === "seize") {
    return livingUnits(state, "ally").some((unit) => isAllowedUnit(unit, condition.unitDefIds) && unit.pos.x === condition.x && unit.pos.y === condition.y);
  }
  if (condition.type === "escape") {
    return condition.unitDefIds.every((unitDefId) => livingUnits(state, "ally").some((unit) => unit.defId === unitDefId && unit.pos.x === condition.x && unit.pos.y === condition.y));
  }
  if (condition.type === "all") {
    return condition.conditions.every((nested) => isVictoryConditionMet(state, nested));
  }
  return condition.conditions.some((nested) => isVictoryConditionMet(state, nested));
}

function isDefeatConditionMet(state: BattleState, condition: ChapterDefeatCondition): boolean {
  if (condition.type === "protectUnit") {
    return protectedUnits(state, condition).some((unit) => !unit?.alive);
  }
  return false;
}

function protectedUnits(state: BattleState, condition: Extract<ChapterDefeatCondition, { type: "protectUnit" }>): Array<UnitInstance | undefined> {
  const byInstance = condition.instanceIds?.map((id) => state.units.find((unit) => unit.id === id)) ?? [];
  const byDef = condition.unitDefIds?.map((id) => state.units.find((unit) => unit.defId === id && unit.team === "ally")) ?? [];
  return [...byInstance, ...byDef];
}

function isAllowedUnit(unit: UnitInstance, unitDefIds: string[] | undefined): boolean {
  return !unitDefIds || unitDefIds.includes(unit.defId);
}

function victoryConditionText(condition: ChapterVictoryCondition): string {
  if (condition.type === "rout") {
    return "敌军崩溃，目标达成。";
  }
  if (condition.type === "defeatBoss") {
    return "关键目标撤退，目标达成。";
  }
  if (condition.type === "survive") {
    return `坚守 ${condition.turns} 回合，目标达成。`;
  }
  if (condition.type === "seize") {
    return "目标地点已占领。";
  }
  if (condition.type === "escape") {
    return "指定单位抵达撤离点。";
  }
  return "复合目标达成。";
}

function defeatConditionText(state: BattleState, condition: ChapterDefeatCondition): string {
  if (condition.type === "protectUnit") {
    const name = protectedUnits(state, condition).find((unit) => !unit?.alive);
    return `${name ? getUnitDef(name.defId).name : "保护目标"} 倒下，目标失败。`;
  }
  return "目标失败。";
}
