import { BOND, GROWTH, getClass, getSkill, getUnitDef, getWeapon } from "../data";
import type { BattleState, SkillDef, UnitInstance } from "../models/types";
import { findUnit, livingUnits } from "./chapter";
import { distance } from "./movement";
import { gainExperience } from "./progression";
import { createRng } from "./rng";
import { addStatus, hasStatus, tickStatuses } from "./status";
import { bondKey } from "./supports";

export interface SkillResult {
  ok: boolean;
  message: string;
}

export function activeSkills(unit: UnitInstance): SkillDef[] {
  return unit.skillIds.map((id) => getSkill(id)).filter((skill) => skill.kind === "active" || skill.kind === "stigma");
}

export function activateSkill(state: BattleState, unitId: string, skillId: string, targetId?: string): SkillResult {
  const unit = findUnit(state, unitId);
  if (!unit.alive || unit.acted) {
    return { ok: false, message: "该单位已经无法行动。" };
  }
  if (!unit.skillIds.includes(skillId)) {
    return { ok: false, message: "该单位不会这个技能。" };
  }
  if ((unit.skillUses[skillId] ?? 0) >= useLimit(skillId)) {
    return { ok: false, message: "本战次数已用完。" };
  }

  if (skillId === "healing_wave") {
    return activateHealingWave(state, unit, targetId);
  }
  if (skillId === "stigma_awaken") {
    return activateStigma(state, unit);
  }
  if (skillId === "aegis") {
    addStatus(unit, { id: "aegis", turns: 1 });
    spendSkill(unit, skillId);
    unit.acted = true;
    return pushResult(state, true, `${unitName(unit)} 展开圣盾，本回合受伤减半。`);
  }
  if (skillId === "sprint") {
    addStatus(unit, { id: "sprint", turns: 1 });
    spendSkill(unit, skillId);
    return pushResult(state, true, `${unitName(unit)} 疾走，本回合移动 +3。`);
  }
  return { ok: false, message: "这个技能尚未接入实装效果。" };
}

export function refreshRound(state: BattleState): void {
  for (const unit of livingUnits(state)) {
    tickStatuses(unit);
    if (unit.team === "ally") {
      accrueAdjacentBonds(state, unit);
    }
  }
}

function activateHealingWave(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  if (!targetId) {
    return { ok: false, message: "请选择治疗目标。" };
  }
  const target = findUnit(state, targetId);
  if (target.team !== unit.team || !target.alive) {
    return { ok: false, message: "只能治疗存活友军。" };
  }
  if (distance(unit.pos, target.pos) > 1) {
    return { ok: false, message: "治疗距离不足。" };
  }
  const weapon = getWeapon(unit.weaponId);
  const amount = Math.max(1, weapon.might + unit.stats.mag);
  const before = target.hp;
  target.hp = Math.min(target.stats.hp, target.hp + amount);
  spendSkill(unit, "healing_wave");
  unit.acted = true;
  addBond(state, unit.defId, target.defId, 5);
  const rng = createRng(state.rngState);
  const expLogs = gainExperience(state, rng, unit, GROWTH.supportExp);
  state.rngState = rng.state;
  state.log.unshift(...expLogs);
  return pushResult(state, true, `${unitName(unit)} 治疗 ${unitName(target)} ${target.hp - before} 点。`);
}

function activateStigma(state: BattleState, unit: UnitInstance): SkillResult {
  const classDef = getClass(getUnitDef(unit.defId).classId);
  if (!classDef.tags.includes("dragon")) {
    return { ok: false, message: "只有龙裔能觉醒龙痕。" };
  }
  if (hasStatus(unit, "stigma_awaken")) {
    return { ok: false, message: "龙痕已经觉醒。" };
  }
  addStatus(unit, { id: "stigma_awaken", turns: 3 });
  spendSkill(unit, "stigma_awaken");
  unit.acted = true;
  const taintKey = `dragonTaint:${unit.defId}`;
  const nextTaint = Number(state.flags[taintKey] ?? 0) + 1;
  state.flags[taintKey] = nextTaint;
  return pushResult(state, true, `${unitName(unit)} 解放龙痕，三回合内全属性提升，龙化值 +1。`);
}

function accrueAdjacentBonds(state: BattleState, unit: UnitInstance): void {
  for (const other of livingUnits(state, "ally")) {
    if (unit.id >= other.id || distance(unit.pos, other.pos) > 1) {
      continue;
    }
    addBond(state, unit.defId, other.defId, 3);
  }
}

function addBond(state: BattleState, left: string, right: string, amount: number): void {
  if (left === right) {
    return;
  }
  const key = bondKey(left, right);
  state.bonds[key] = Math.min(BOND.S, (state.bonds[key] ?? 0) + amount);
}

function spendSkill(unit: UnitInstance, skillId: string): void {
  unit.skillUses[skillId] = (unit.skillUses[skillId] ?? 0) + 1;
}

function useLimit(skillId: string): number {
  if (skillId === "healing_wave") {
    return 99;
  }
  if (skillId === "aegis") {
    return 2;
  }
  return 1;
}

function pushResult(state: BattleState, ok: boolean, message: string): SkillResult {
  state.log.unshift(message);
  return { ok, message };
}

function unitName(unit: UnitInstance): string {
  return getUnitDef(unit.defId).name;
}
