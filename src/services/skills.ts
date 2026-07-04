import { BOND, GROWTH, getSkill, getUnitDef, getWeapon } from "../data";
import type { BattleState, Cell, SkillDef, UnitInstance } from "../models/types";
import { findUnit, livingUnits, unitAt } from "./chapter";
import { classForUnit } from "./classes";
import { canUnitAttackAtDistance, consumeBloodMemory, hasSkill, primeBloodMemory } from "./skillEffects";
import { addStatus, effectiveStats, hasStatus, tickStatuses } from "./status";
import { distance, inBounds, movementCost, neighbors, terrainAt } from "./movement";
import { gainExperience } from "./progression";
import { createRng, rollPercent } from "./rng";
import { bondKey } from "./supports";

export interface SkillResult {
  ok: boolean;
  message: string;
}

export function activeSkills(unit: UnitInstance): SkillDef[] {
  if (hasStatus(unit, "silence")) {
    return [];
  }
  return unit.skillIds
    .map((id) => getSkill(id))
    .filter((skill) => skill.kind === "active" || skill.kind === "stigma" || (skill.kind === "class" && skill.trigger === "manual"));
}

export function skillRequiresTarget(skillId: string): boolean {
  return !["aegis", "charge", "fortify", "poison_blade", "rally_defense", "rally_speed", "sprint", "stigma_awaken", "stigma_roar", "stigma_seal"].includes(skillId);
}

export function activateSkill(state: BattleState, unitId: string, skillId: string, targetId?: string): SkillResult {
  const unit = findUnit(state, unitId);
  if (!unit.alive || unit.acted) {
    return { ok: false, message: "该单位已经无法行动。" };
  }
  if (!unit.skillIds.includes(skillId)) {
    return { ok: false, message: "该单位不会这个技能。" };
  }
  if (hasStatus(unit, "silence")) {
    return { ok: false, message: "该单位被封技，无法使用主动技能。" };
  }
  if ((unit.skillUses[skillUseKey(state, skillId)] ?? 0) >= useLimit(skillId)) {
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
    spendSkill(state, unit, skillId);
    unit.acted = true;
    return pushResult(state, true, `${unitName(unit)} 展开圣盾，本回合受伤减半。`);
  }
  if (skillId === "sprint") {
    addStatus(unit, { id: "sprint", turns: 1 });
    spendSkill(state, unit, skillId);
    return pushResult(state, true, `${unitName(unit)} 疾走，本回合移动 +3。`);
  }
  if (skillId === "charge") {
    return activateCharge(state, unit);
  }
  if (skillId === "poison_blade") {
    return activatePoisonBlade(state, unit);
  }
  if (skillId === "rally_defense" || skillId === "rally_speed") {
    return activateRally(state, unit, skillId);
  }
  if (skillId === "barrier") {
    return activateBarrier(state, unit, targetId);
  }
  if (skillId === "fortify") {
    return activateFortify(state, unit);
  }
  if (skillId === "mark_target" || skillId === "silence" || skillId === "taunt") {
    return activateDebuff(state, unit, targetId, skillId);
  }
  if (skillId === "freeze_field") {
    return activateFreezeField(state, unit, targetId);
  }
  if (skillId === "swap") {
    return activateSwap(state, unit, targetId);
  }
  if (skillId === "shove" || skillId === "smite") {
    return activatePush(state, unit, targetId, skillId === "smite" ? 2 : 1);
  }
  if (skillId === "rescue_pull") {
    return activateRescuePull(state, unit, targetId);
  }
  if (skillId === "falcon_mercy") {
    return activateFalconMercy(state, unit, targetId);
  }
  if (skillId === "gale_cross") {
    return activateGaleCross(state, unit, targetId);
  }
  if (skillId === "piercing_shot") {
    return activatePiercingShot(state, unit, targetId);
  }
  if (skillId === "meteor") {
    return activateMeteor(state, unit, targetId);
  }
  if (skillId === "resurrection") {
    return activateResurrection(state, unit, targetId);
  }
  if (skillId === "saint_refresh") {
    return activateSaintRefresh(state, unit, targetId);
  }
  if (skillId === "stigma_seal") {
    return activateStigmaSeal(state, unit);
  }
  if (skillId === "stigma_roar") {
    return activateStigmaRoar(state, unit);
  }
  return { ok: false, message: "这个技能尚未接入实装效果。" };
}

export function refreshRound(state: BattleState): void {
  for (const unit of livingUnits(state)) {
    applyStatusEffects(state, unit);
    tickStatuses(unit);
    applyTerrainEffects(state, unit);
    if (unit.team === "ally") {
      accrueAdjacentBonds(state, unit);
    }
  }
  for (const unit of state.units) {
    unit.moved = false;
    unit.cantoMoveLeft = 0;
  }
}

function applyStatusEffects(state: BattleState, unit: UnitInstance): void {
  if (hasStatus(unit, "poison")) {
    const damage = Math.max(1, Math.floor(unit.stats.hp * 0.1));
    unit.hp = Math.max(0, unit.hp - damage);
    state.log.unshift(`${unitName(unit)} 毒发 ${damage} 点。`);
    if (unit.hp === 0) {
      unit.alive = false;
      unit.acted = true;
      primeBloodMemory(state, unit);
      state.log.unshift(`${unitName(unit)} 毒发倒下。`);
    }
  }
}

function applyTerrainEffects(state: BattleState, unit: UnitInstance): void {
  const terrain = terrainAt(state, unit.pos);
  if (terrain.effects.includes("regen10") || terrain.effects.includes("bossRegen")) {
    const amount = Math.max(1, Math.floor(unit.stats.hp * 0.1));
    const before = unit.hp;
    unit.hp = Math.min(unit.stats.hp, unit.hp + amount);
    if (unit.hp > before) {
      state.log.unshift(`${unitName(unit)} 借助${terrain.name}恢复 ${unit.hp - before} 点。`);
    }
  }
  if (terrain.effects.includes("poison")) {
    const damage = Math.max(1, Math.floor(unit.stats.hp * 0.1));
    unit.hp = Math.max(0, unit.hp - damage);
    state.log.unshift(`${unitName(unit)} 被${terrain.name}侵蚀 ${damage} 点。`);
    if (unit.hp === 0) {
      unit.alive = false;
      unit.acted = true;
      primeBloodMemory(state, unit);
      state.log.unshift(`${unitName(unit)} 倒在${terrain.name}中。`);
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
  const amount = healingAmount(state, unit, Math.max(1, weapon.might + unit.stats.mag));
  const before = target.hp;
  target.hp = Math.min(target.stats.hp, target.hp + amount);
  spendSkill(state, unit, "healing_wave");
  unit.acted = true;
  addBond(state, unit.defId, target.defId, 5);
  const rng = createRng(state.rngState);
  const expLogs = gainExperience(state, rng, unit, GROWTH.supportExp);
  state.rngState = rng.state;
  state.log.unshift(...expLogs);
  return pushResult(state, true, `${unitName(unit)} 治疗 ${unitName(target)} ${target.hp - before} 点。`);
}

function activateStigma(state: BattleState, unit: UnitInstance): SkillResult {
  const classDef = classForUnit(unit);
  if (!classDef.tags.includes("dragon")) {
    return { ok: false, message: "只有龙裔能觉醒龙痕。" };
  }
  if (hasStatus(unit, "stigma_awaken")) {
    return { ok: false, message: "龙痕已经觉醒。" };
  }
  const empowered = consumeBloodMemory(unit);
  addStatus(unit, { id: "stigma_awaken", turns: empowered ? 4 : 3 });
  spendSkill(state, unit, "stigma_awaken");
  unit.acted = true;
  const taintKey = `dragonTaint:${unit.defId}`;
  const taintGain = stigmaTaintGain(state, unit, 1);
  const nextTaint = Number(state.flags[taintKey] ?? 0) + taintGain;
  state.flags[taintKey] = nextTaint;
  return pushResult(state, true, `${unitName(unit)} 解放龙痕，${empowered ? "血忆延长觉醒，" : ""}龙化值 ${taintGain > 0 ? `+${taintGain}` : "未增加"}。`);
}

function activateCharge(state: BattleState, unit: UnitInstance): SkillResult {
  if (!classForUnit(unit).tags.includes("cavalry")) {
    return { ok: false, message: "只有骑兵能发动冲锋。" };
  }
  // ponytail: current battle flow has no move-then-attack action; use half move as the momentum seed until Canto/move-attack lands.
  const bonus = Math.max(1, Math.floor(effectiveStats(unit).move / 2));
  addStatus(unit, { id: "charge", turns: 1, value: bonus });
  spendSkill(state, unit, "charge");
  return pushResult(state, true, `${unitName(unit)} 架枪冲锋，下次攻击威力 +${bonus}。`);
}

function activatePoisonBlade(state: BattleState, unit: UnitInstance): SkillResult {
  if (!classForUnit(unit).tags.includes("scout")) {
    return { ok: false, message: "只有斥候系能淬毒。" };
  }
  addStatus(unit, { id: "poison_blade", turns: 1 });
  spendSkill(state, unit, "poison_blade");
  return pushResult(state, true, `${unitName(unit)} 为武器淬毒，下次命中施加中毒。`);
}

function activateRally(state: BattleState, unit: UnitInstance, skillId: "rally_defense" | "rally_speed"): SkillResult {
  const targets = adjacentUnits(state, unit).filter((target) => target.team === unit.team);
  if (targets.length === 0) {
    return { ok: false, message: "周围没有可号令的友军。" };
  }
  const statusId = skillId === "rally_defense" ? "rally_defense" : "rally_speed";
  for (const target of targets) {
    addStatus(target, { id: statusId, turns: 2 });
  }
  spendSkill(state, unit, skillId);
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 发出号令，强化 ${targets.length} 名友军。`);
}

function activateBarrier(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target) {
    return { ok: false, message: "请选择屏障目标。" };
  }
  if (target.team !== unit.team || !target.alive || distance(unit.pos, target.pos) > 2) {
    return { ok: false, message: "屏障只能赋予近处友军。" };
  }
  addStatus(target, { id: "barrier", turns: 2 });
  spendSkill(state, unit, "barrier");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 为 ${unitName(target)} 展开魔防屏障。`);
}

function activateFortify(state: BattleState, unit: UnitInstance): SkillResult {
  const targets = adjacentUnits(state, unit).filter((target) => target.team === unit.team && target.hp < target.stats.hp);
  if (targets.length === 0) {
    return { ok: false, message: "周围没有受伤友军。" };
  }
  const amount = healingAmount(state, unit, Math.max(1, Math.floor(effectiveStats(unit).mag / 2) + 8));
  for (const target of targets) {
    target.hp = Math.min(target.stats.hp, target.hp + amount);
    addBond(state, unit.defId, target.defId, 3);
  }
  spendSkill(state, unit, "fortify");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 施放群体治疗，恢复 ${targets.length} 名友军。`);
}

function activateDebuff(state: BattleState, unit: UnitInstance, targetId: string | undefined, skillId: "mark_target" | "silence" | "taunt"): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team === unit.team || !target.alive) {
    return { ok: false, message: "请选择敌方目标。" };
  }
  const maxRange = skillId === "taunt" ? 1 : 3;
  if (distance(unit.pos, target.pos) > maxRange) {
    return { ok: false, message: "技能距离不足。" };
  }
  if (skillId === "mark_target") {
    addStatus(target, { id: "marked", turns: 2 });
  } else if (skillId === "silence") {
    addStatus(target, { id: "silence", turns: 1 });
  } else {
    addStatus(target, { id: "taunted", turns: 1, sourceId: unit.id });
  }
  spendSkill(state, unit, skillId);
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 对 ${unitName(target)} 发动${getSkill(skillId).name}。`);
}

function activateFreezeField(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team === unit.team || !target.alive || distance(unit.pos, target.pos) > 3) {
    return { ok: false, message: "请选择 3 格内敌方目标。" };
  }
  const targets = livingUnits(state, target.team).filter((enemy) => distance(enemy.pos, target.pos) <= 1);
  for (const enemy of targets) {
    addStatus(enemy, { id: "frozen", turns: 2 });
  }
  spendSkill(state, unit, "freeze_field");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 冻结区域，减速 ${targets.length} 名敌人。`);
}

function activateSwap(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team !== unit.team || !target.alive || distance(unit.pos, target.pos) !== 1) {
    return { ok: false, message: "只能与相邻友军换位。" };
  }
  const unitPos = unit.pos;
  unit.pos = target.pos;
  target.pos = unitPos;
  spendSkill(state, unit, "swap");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 与 ${unitName(target)} 换位。`);
}

function activatePush(state: BattleState, unit: UnitInstance, targetId: string | undefined, steps: number): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || !target.alive || distance(unit.pos, target.pos) !== 1) {
    return { ok: false, message: "只能推动相邻单位。" };
  }
  const dx = Math.sign(target.pos.x - unit.pos.x);
  const dy = Math.sign(target.pos.y - unit.pos.y);
  if (!moveForced(state, target, { x: dx, y: dy }, steps)) {
    return { ok: false, message: "推动路径被阻挡。" };
  }
  spendSkill(state, unit, steps === 2 ? "smite" : "shove");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 推开 ${unitName(target)}。`);
}

function activateRescuePull(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team !== unit.team || !target.alive || target.id === unit.id || distance(unit.pos, target.pos) > 2) {
    return { ok: false, message: "请选择 2 格内友军。" };
  }
  const destination = neighbors(unit.pos)
    .filter((cell) => canEnterForced(state, target, cell))
    .sort((a, b) => distance(a, target.pos) - distance(b, target.pos))[0];
  if (!destination) {
    return { ok: false, message: "身边没有可拉入的空格。" };
  }
  target.pos = destination;
  spendSkill(state, unit, "rescue_pull");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 将 ${unitName(target)} 拉回身边。`);
}

function activateFalconMercy(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  if (classForUnit(unit).id !== "falcon_knight") {
    return { ok: false, message: "只有隼骑能发动救护。" };
  }
  const target = targetedUnit(state, targetId);
  if (!target || target.team !== unit.team || !target.alive || target.id === unit.id || distance(unit.pos, target.pos) !== 1) {
    return { ok: false, message: "只能救护相邻友军。" };
  }
  const destination = neighbors(unit.pos)
    .filter((cell) => canEnterForced(state, target, cell))
    .sort((a, b) => compareCarryDestinations(state, target, a, b))[0];
  if (!destination) {
    return { ok: false, message: "身边没有可放下的空格。" };
  }
  target.pos = destination;
  spendSkill(state, unit, "falcon_mercy");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 带离 ${unitName(target)}。`);
}

function activateGaleCross(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  const weapon = getWeapon(unit.weaponId);
  if (!target || target.team === unit.team || !target.alive || !canUnitAttackAtDistance(unit, weapon, distance(unit.pos, target.pos))) {
    return { ok: false, message: "请选择射程内敌人。" };
  }
  const targets = livingUnits(state, target.team).filter((enemy) => distance(enemy.pos, target.pos) <= 1);
  const damage = targets.reduce((sum, enemy) => sum + dealSkillDamage(state, unit, enemy, weapon.damageKind === "magical"), 0);
  spendSkill(state, unit, "gale_cross");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 施展疾风连斩，造成合计 ${damage} 点。`);
}

function activatePiercingShot(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team === unit.team || !target.alive || getWeapon(unit.weaponId).kind !== "bow" || !sameLine(unit.pos, target.pos) || distance(unit.pos, target.pos) > 4) {
    return { ok: false, message: "贯通射击需要 4 格内直线敌人。" };
  }
  const targets = livingUnits(state, target.team).filter((enemy) => sameRay(unit.pos, target.pos, enemy.pos) && distance(unit.pos, enemy.pos) <= distance(unit.pos, target.pos));
  const damage = targets.reduce((sum, enemy) => sum + dealSkillDamage(state, unit, enemy, false), 0);
  spendSkill(state, unit, "piercing_shot");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 贯通射击命中 ${targets.length} 名敌人，合计 ${damage} 点。`);
}

function activateMeteor(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team === unit.team || !target.alive || distance(unit.pos, target.pos) > 4) {
    return { ok: false, message: "请选择 4 格内敌人。" };
  }
  const damage = dealSkillDamage(state, unit, target, true, 8);
  spendSkill(state, unit, "meteor");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 召下陨星，造成 ${damage} 点。`);
}

function activateResurrection(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team !== unit.team || target.alive || distance(unit.pos, target.pos) > 1 || unitAt(state, target.pos.x, target.pos.y)) {
    return { ok: false, message: "只能复活相邻倒下友军。" };
  }
  target.alive = true;
  target.acted = true;
  target.hp = Math.max(1, Math.floor(target.stats.hp / 2));
  target.statuses = [];
  spendSkill(state, unit, "resurrection");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 复活 ${unitName(target)}。`);
}

function activateSaintRefresh(state: BattleState, unit: UnitInstance, targetId: string | undefined): SkillResult {
  const target = targetedUnit(state, targetId);
  if (!target || target.team !== unit.team || !target.alive || target.id === unit.id || distance(unit.pos, target.pos) > 1 || !target.acted) {
    return { ok: false, message: "只能鼓舞相邻且已行动友军。" };
  }
  target.acted = false;
  spendSkill(state, unit, "saint_refresh");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 鼓舞 ${unitName(target)} 再次行动。`);
}

function activateStigmaSeal(state: BattleState, unit: UnitInstance): SkillResult {
  const key = `dragonTaint:${unit.defId}`;
  const taint = Number(state.flags[key] ?? 0);
  if (taint <= 0 || unit.hp <= 5) {
    return { ok: false, message: "龙化值或生命不足，无法封印。" };
  }
  unit.hp -= 5;
  state.flags[key] = taint - 1;
  spendSkill(state, unit, "stigma_seal");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 以生命封印龙痕，龙化值 -1。`);
}

function activateStigmaRoar(state: BattleState, unit: UnitInstance): SkillResult {
  if (!classForUnit(unit).tags.includes("dragon")) {
    return { ok: false, message: "只有龙裔能发动龙吼。" };
  }
  const targets = livingUnits(state, unit.team === "ally" ? "enemy" : "ally").filter((enemy) => distance(unit.pos, enemy.pos) <= 2);
  if (targets.length === 0) {
    return { ok: false, message: "周围没有可震慑目标。" };
  }
  const empowered = consumeBloodMemory(unit);
  for (const target of targets) {
    addStatus(target, { id: "frozen", turns: empowered ? 2 : 1 });
    const dx = Math.sign(target.pos.x - unit.pos.x);
    const dy = Math.sign(target.pos.y - unit.pos.y);
    moveForced(state, target, { x: dx, y: dy }, 1);
  }
  const key = `dragonTaint:${unit.defId}`;
  const taintGain = stigmaTaintGain(state, unit, 1);
  state.flags[key] = Number(state.flags[key] ?? 0) + taintGain;
  spendSkill(state, unit, "stigma_roar");
  unit.acted = true;
  return pushResult(state, true, `${unitName(unit)} 发出龙吼，震慑 ${targets.length} 名敌人，龙化值 ${taintGain > 0 ? `+${taintGain}` : "未增加"}。`);
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

function adjacentUnits(state: BattleState, unit: UnitInstance): UnitInstance[] {
  return livingUnits(state).filter((target) => target.id !== unit.id && distance(unit.pos, target.pos) <= 1);
}

function healingAmount(state: BattleState, unit: UnitInstance, baseAmount: number): number {
  if (!hasSkill(unit, "holy_focus")) {
    return baseAmount;
  }
  const rng = createRng(state.rngState);
  const focused = rollPercent(rng, effectiveStats(unit).skill, false);
  state.rngState = rng.state;
  return focused ? baseAmount + Math.max(1, Math.floor(baseAmount / 2)) : baseAmount;
}

function stigmaTaintGain(state: BattleState, unit: UnitInstance, baseGain: number): number {
  if (baseGain <= 0 || !hasSkill(unit, "forbidden_vow")) {
    return baseGain;
  }
  return adjacentUnits(state, unit).some((target) => target.team === unit.team) ? baseGain - 1 : baseGain;
}

function targetedUnit(state: BattleState, targetId: string | undefined): UnitInstance | undefined {
  return targetId ? findUnit(state, targetId) : undefined;
}

function moveForced(state: BattleState, target: UnitInstance, delta: Cell, steps: number): boolean {
  if (hasSkill(target, "bulwark")) {
    return false;
  }
  const start = { ...target.pos };
  for (let step = 0; step < steps; step += 1) {
    const next = { x: target.pos.x + delta.x, y: target.pos.y + delta.y };
    if (!canEnterForced(state, target, next)) {
      target.pos = start;
      return false;
    }
    target.pos = next;
  }
  return true;
}

function canEnterForced(state: BattleState, target: UnitInstance, cell: Cell): boolean {
  return inBounds(state, cell) && !unitAt(state, cell.x, cell.y) && movementCost(state, target, cell) != null;
}

function compareCarryDestinations(state: BattleState, target: UnitInstance, a: Cell, b: Cell): number {
  const safetyA = nearestEnemyDistance(state, target, a);
  const safetyB = nearestEnemyDistance(state, target, b);
  if (safetyA !== safetyB) {
    return safetyB - safetyA;
  }
  const carryA = distance(a, target.pos);
  const carryB = distance(b, target.pos);
  if (carryA !== carryB) {
    return carryB - carryA;
  }
  return a.x - b.x || a.y - b.y;
}

function nearestEnemyDistance(state: BattleState, target: UnitInstance, cell: Cell): number {
  const enemies = livingUnits(state, target.team === "ally" ? "enemy" : "ally");
  if (enemies.length === 0) {
    return Number.POSITIVE_INFINITY;
  }
  return Math.min(...enemies.map((enemy) => distance(cell, enemy.pos)));
}

function dealSkillDamage(state: BattleState, source: UnitInstance, target: UnitInstance, magical: boolean, bonus = 0): number {
  const sourceStats = effectiveStats(source);
  const targetStats = effectiveStats(target);
  const weapon = getWeapon(source.weaponId);
  const attack = (magical ? sourceStats.mag : sourceStats.str) + (weapon.damageKind === "healing" ? 0 : weapon.might) + bonus;
  const defense = magical ? targetStats.res : targetStats.def;
  const damage = Math.max(1, attack - defense);
  target.hp = Math.max(0, target.hp - damage);
  if (target.hp === 0) {
    target.alive = false;
    target.acted = true;
  }
  return damage;
}

function sameLine(left: Cell, right: Cell): boolean {
  return left.x === right.x || left.y === right.y;
}

function sameRay(origin: Cell, target: Cell, candidate: Cell): boolean {
  if (origin.x === target.x) {
    return candidate.x === origin.x && Math.sign(candidate.y - origin.y) === Math.sign(target.y - origin.y);
  }
  if (origin.y === target.y) {
    return candidate.y === origin.y && Math.sign(candidate.x - origin.x) === Math.sign(target.x - origin.x);
  }
  return false;
}

function spendSkill(state: BattleState, unit: UnitInstance, skillId: string): void {
  const key = skillUseKey(state, skillId);
  unit.skillUses[key] = (unit.skillUses[key] ?? 0) + 1;
}

function useLimit(skillId: string): number {
  if (skillId === "healing_wave") {
    return 99;
  }
  if (skillId === "swap" || skillId === "shove" || skillId === "mark_target") {
    return 99;
  }
  if (skillId === "aegis" || skillId === "barrier" || skillId === "rally_defense" || skillId === "rally_speed") {
    return 2;
  }
  return 1;
}

function skillUseKey(state: BattleState, skillId: string): string {
  return skillId === "charge" ? `${skillId}:turn:${state.turn}` : skillId;
}

function pushResult(state: BattleState, ok: boolean, message: string): SkillResult {
  state.log.unshift(message);
  return { ok, message };
}

function unitName(unit: UnitInstance): string {
  return getUnitDef(unit.defId).name;
}
