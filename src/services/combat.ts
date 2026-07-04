import {
  COMBAT,
  getTerrain,
  getUnitDef,
  getWeapon,
  isMagicTriangleKind,
  isPhysicalTriangleKind,
  magicTriangle,
  weaponTriangle,
} from "../data";
import type { BattleState, CombatEvent, CombatForecast, CombatResolution, UnitInstance, WeaponDef } from "../models/types";
import { findUnit, unitAt } from "./chapter";
import { classForUnit } from "./classes";
import { remainingWeaponUses, spendWeaponUse, weaponMight } from "./equipment";
import { createRng, rollPercent } from "./rng";
import { distance, movementCost, neighbors } from "./movement";
import { awardCombatExperience } from "./progression";
import {
  armorBreaks,
  avoidBonus,
  canUnitAttackAtDistance,
  critAvoidBonus,
  critMultiplier,
  damageBonus,
  defenseBonus,
  followUpThreshold,
  foresightReady,
  hasSkill,
  hitBonus,
  ignoresTerrainAvoid,
  primeBloodMemory,
  rangeHitPenalty,
} from "./skillEffects";
import { addStatus, effectiveStats, hasStatus } from "./status";

export function attackSpeed(unit: UnitInstance, weapon: WeaponDef): number {
  const stats = effectiveStats(unit);
  return stats.spd - Math.max(0, weapon.weight - stats.con);
}

export function triangleValue(attackerWeapon: WeaponDef, defenderWeapon: WeaponDef): number {
  if (isPhysicalTriangleKind(attackerWeapon.kind) && isPhysicalTriangleKind(defenderWeapon.kind)) {
    return weaponTriangle[attackerWeapon.kind][defenderWeapon.kind];
  }
  if (isMagicTriangleKind(attackerWeapon.kind) && isMagicTriangleKind(defenderWeapon.kind)) {
    return magicTriangle[attackerWeapon.kind][defenderWeapon.kind];
  }
  return 0;
}

export function effectiveMultiplier(weapon: WeaponDef, defender: UnitInstance): number {
  const tags = classForUnit(defender).tags;
  return weapon.effectiveTags?.some((tag) => tags.includes(tag)) ? COMBAT.effMultiplier : 1;
}

export function canAttackAtDistance(weapon: WeaponDef, cells: number): boolean {
  return cells >= weapon.range[0] && cells <= weapon.range[1];
}

export function forecastCombat(state: BattleState, attackerId: string, defenderId: string): CombatForecast {
  const attacker = findUnit(state, attackerId);
  const defender = findUnit(state, defenderId);
  const attackerWeapon = getWeapon(attacker.weaponId);
  const defenderWeapon = getWeapon(defender.weaponId);
  const attackerStats = effectiveStats(attacker);
  const defenderStats = effectiveStats(defender);
  const attackerCanUseWeapon = remainingWeaponUses(attacker) > 0;
  const defenderCanUseWeapon = remainingWeaponUses(defender) > 0;
  const cells = distance(attacker.pos, defender.pos);
  const defenderTerrainId = state.grid[defender.pos.y]?.[defender.pos.x];
  if (!defenderTerrainId) {
    throw new Error(`Defender is outside map: ${defender.id}`);
  }
  const defenderTerrain = getTerrain(defenderTerrainId);
  const triangle = triangleValue(attackerWeapon, defenderWeapon);
  const multiplier = effectiveMultiplier(attackerWeapon, defender);
  const terrainDefense = attackerWeapon.damageKind === "magical" ? 0 : defenderTerrain.defense;
  const rawDefense = attackerWeapon.damageKind === "magical" ? defenderStats.res : defenderStats.def;
  const defense = Math.max(
    0,
    Math.floor((armorBreaks(attacker, attackerWeapon) ? rawDefense * 0.5 : rawDefense) + terrainDefense + defenseBonus(state, defender, defenderTerrain, attackerWeapon.damageKind === "magical")),
  );
  const forgedMight = weaponMight(attacker, attackerWeapon);
  const basePower =
    attackerWeapon.damageKind === "magical"
      ? attackerStats.mag + forgedMight + damageBonus(state, attacker, defender, attackerWeapon)
      : (attackerStats.str + forgedMight + damageBonus(state, attacker, defender, attackerWeapon)) * multiplier;
  const damage = attackerCanUseWeapon
    ? Math.max(COMBAT.minDamage, Math.floor(basePower + triangle * COMBAT.counterMight - defense))
    : 0;
  const terrainAvoid = ignoresTerrainAvoid(attacker, attackerWeapon) ? 0 : defenderTerrain.avoid;
  const hit = attackerCanUseWeapon
    ? foresightReady(attacker, defender)
      ? 0
      : hitFloor(
          attacker,
          attackerWeapon.hit +
            attackerStats.skill * 2 +
            triangle * COMBAT.counterHit +
            hitBonus(state, attacker) -
            rangeHitPenalty(attacker, attackerWeapon, cells) -
            (defenderStats.spd * 2 + defenderStats.luck + terrainAvoid + avoidBonus(state, defender, attackerWeapon)),
        )
    : 0;
  const rawCrit = critMultiplier(state, attacker) === 100 ? 100 : (attackerWeapon.crit + Math.floor(attackerStats.skill * COMBAT.critFromSkill)) * critMultiplier(state, attacker);
  const crit = attackerCanUseWeapon
    ? clampPercent(rawCrit - defenderStats.luck - critAvoidBonus(defender))
    : 0;
  const followUp = attackerCanUseWeapon && attackSpeed(attacker, attackerWeapon) - attackSpeed(defender, defenderWeapon) >= followUpThreshold(attacker, attackerWeapon);
  return {
    attackerId,
    defenderId,
    distance: cells,
    damage,
    hit,
    crit,
    followUp,
    defenderCanCounter: defenderCanUseWeapon && canUnitAttackAtDistance(defender, defenderWeapon, cells) && defenderWeapon.damageKind !== "healing",
    triangle,
    effectiveMultiplier: multiplier,
  };
}

export function resolveCombat(state: BattleState, attackerId: string, defenderId: string): CombatResolution {
  const attacker = findUnit(state, attackerId);
  const intendedDefender = findUnit(state, defenderId);
  const attackerWeapon = getWeapon(attacker.weaponId);
  if (!canUnitAttackAtDistance(attacker, attackerWeapon, distance(attacker.pos, intendedDefender.pos)) || attackerWeapon.damageKind === "healing") {
    throw new Error(`${attacker.id} cannot attack ${intendedDefender.id}`);
  }
  if (remainingWeaponUses(attacker) <= 0) {
    throw new Error(`${attacker.id} 的 ${attackerWeapon.name} 耐久耗尽。`);
  }

  const defender = sisterGuardTarget(state, attacker, intendedDefender) ?? intendedDefender;
  if (defender.id !== intendedDefender.id) {
    defender.skillUses.sister_guard = (defender.skillUses.sister_guard ?? 0) + 1;
  }
  const forecast = forecastCombat(state, attackerId, defender.id);
  const defenderWeapon = getWeapon(defender.weaponId);

  const rng = createRng(state.rngState);
  const events: CombatEvent[] = [];
  const reactionLogs = defender.id === intendedDefender.id ? [] : [`${unitName(state, defender.id)} 护住 ${unitName(state, intendedDefender.id)}。`];
  strike(state, rng, events, attacker, defender);
  if (defender.alive && attacker.alive && hasSkill(attacker, "adept") && rollPercent(rng, effectiveStats(attacker).skill, false)) {
    strike(state, rng, events, attacker, defender);
  }
  if (defender.alive && attacker.alive) {
    const counterUnit = forecast.defenderCanCounter ? defender : guardLungeCounter(state, defender, attacker);
    if (counterUnit) {
      if (counterUnit.id !== defender.id) {
        counterUnit.skillUses.guard_lunge = (counterUnit.skillUses.guard_lunge ?? 0) + 1;
        reactionLogs.push(`${unitName(state, counterUnit.id)} 援护 ${unitName(state, defender.id)} 反击。`);
      }
      strike(state, rng, events, counterUnit, attacker);
    }
  }
  if (defender.alive && attacker.alive && forecast.followUp) {
    strike(state, rng, events, attacker, defender);
  }
  if (defender.alive && attacker.alive && attackSpeed(defender, defenderWeapon) - attackSpeed(attacker, attackerWeapon) >= followUpThreshold(defender, defenderWeapon)) {
    strike(state, rng, events, defender, attacker);
  }

  const movementLogs = rangerSkirmishStepBack(state, attacker, defender);
  const expLogs = awardCombatExperience(state, rng, events);
  state.rngState = rng.state;
  state.log.unshift(...reactionLogs, ...eventsToLog(state, events), ...movementLogs, ...expLogs);
  return { forecast, events };
}

function strike(state: BattleState, rng: ReturnType<typeof createRng>, events: CombatEvent[], source: UnitInstance, target: UnitInstance): void {
  const sourceWeapon = getWeapon(source.weaponId);
  if (remainingWeaponUses(source) <= 0) {
    return;
  }
  const forecast = forecastCombat(state, source.id, target.id);
  const remainingUses = spendWeaponUse(source);
  if (foresightReady(source, target)) {
    target.skillUses.foresight = (target.skillUses.foresight ?? 0) + 1;
    events.push({ type: "miss", sourceId: source.id, targetId: target.id });
    if (remainingUses === 0) {
      events.push({ type: "weaponBreak", sourceId: source.id, weaponId: sourceWeapon.id });
    }
    return;
  }
  const hit = rollPercent(rng, forecast.hit, COMBAT.doubleRNG);
  if (!hit) {
    events.push({ type: "miss", sourceId: source.id, targetId: target.id });
    if (remainingUses === 0) {
      events.push({ type: "weaponBreak", sourceId: source.id, weaponId: sourceWeapon.id });
    }
    return;
  }

  const critical = rollPercent(rng, forecast.crit, false);
  const rawDamage = critical ? forecast.damage * 3 : forecast.damage;
  const damage = hasStatus(target, "aegis") ? Math.max(COMBAT.minDamage, Math.floor(rawDamage / 2)) : rawDamage;
  const targetDef = getUnitDef(target.defId);
  const mercy = hasSkill(source, "mercy") && targetDef.defeatBehavior === "retreat" && target.hp <= damage;
  const dealt = mercy ? Math.max(0, target.hp - 1) : damage;
  target.hp = mercy ? 1 : Math.max(0, target.hp - damage);
  events.push({ type: "hit", sourceId: source.id, targetId: target.id, damage: dealt, critical, remainingHp: target.hp });
  if (hasStatus(source, "poison_blade")) {
    addStatus(target, { id: "poison", turns: 3 });
  }
  if (!mercy && target.hp === 0) {
    target.alive = false;
    target.acted = true;
    primeBloodMemory(state, target);
    events.push({ type: "defeat", sourceId: source.id, targetId: target.id, retreat: targetDef.defeatBehavior === "retreat" });
  }
  if (remainingUses === 0) {
    events.push({ type: "weaponBreak", sourceId: source.id, weaponId: sourceWeapon.id });
  }
}

function eventsToLog(state: BattleState, events: CombatEvent[]): string[] {
  return events.map((event) => {
    const sourceName = unitName(state, event.sourceId);
    if (event.type === "miss") {
      const targetName = unitName(state, event.targetId);
      return `${sourceName} 的攻击落空。`;
    }
    if (event.type === "defeat") {
      const targetName = unitName(state, event.targetId);
      return event.retreat ? `${targetName} 撤退。` : `${targetName} 倒下。`;
    }
    if (event.type === "weaponBreak") {
      return `${sourceName} 的${getWeapon(event.weaponId).name}损坏。`;
    }
    return `${sourceName} 造成 ${event.damage} 点伤害${event.critical ? "！" : "。"}`;
  });
}

function unitName(state: BattleState, instanceId: string): string {
  const unit = state.units.find((candidate) => candidate.id === instanceId);
  return unit ? getUnitDef(unit.defId).name : instanceId;
}

function sisterGuardTarget(state: BattleState, attacker: UnitInstance, defender: UnitInstance): UnitInstance | undefined {
  const weapon = getWeapon(attacker.weaponId);
  return state.units.find(
    (candidate) =>
      candidate.alive &&
      candidate.team === defender.team &&
      candidate.id !== defender.id &&
      hasSkill(candidate, "sister_guard") &&
      (candidate.skillUses.sister_guard ?? 0) === 0 &&
      distance(candidate.pos, defender.pos) <= 1 &&
      canUnitAttackAtDistance(attacker, weapon, distance(attacker.pos, candidate.pos)),
  );
}

function guardLungeCounter(state: BattleState, defender: UnitInstance, attacker: UnitInstance): UnitInstance | undefined {
  return state.units.find((candidate) => {
    if (
      !candidate.alive ||
      candidate.team !== defender.team ||
      candidate.id === defender.id ||
      !hasSkill(candidate, "guard_lunge") ||
      (candidate.skillUses.guard_lunge ?? 0) > 0 ||
      distance(candidate.pos, defender.pos) > 1
    ) {
      return false;
    }
    const weapon = getWeapon(candidate.weaponId);
    return remainingWeaponUses(candidate) > 0 && weapon.damageKind !== "healing" && canUnitAttackAtDistance(candidate, weapon, distance(candidate.pos, attacker.pos));
  });
}

function rangerSkirmishStepBack(state: BattleState, attacker: UnitInstance, defender: UnitInstance): string[] {
  if (!attacker.alive || !hasSkill(attacker, "ranger_skirmish")) {
    return [];
  }
  const currentDistance = distance(attacker.pos, defender.pos);
  const destination = neighbors(attacker.pos)
    .filter(
      (cell) =>
        distance(cell, defender.pos) > currentDistance &&
        !unitAt(state, cell.x, cell.y) &&
        movementCost(state, attacker, cell) != null,
    )
    .sort((left, right) => distance(right, defender.pos) - distance(left, defender.pos))[0];
  if (!destination) {
    return [];
  }
  attacker.pos = destination;
  attacker.moved = true;
  return [`${unitName(state, attacker.id)} 游击后撤。`];
}

function clampPercent(value: number): number {
  return Math.max(0, Math.min(100, Math.floor(value)));
}

function hitFloor(attacker: UnitInstance, value: number): number {
  const hit = clampPercent(value);
  return hasSkill(attacker, "steady_hand") ? Math.max(60, hit) : hit;
}
