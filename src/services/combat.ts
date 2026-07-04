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
import { findUnit } from "./chapter";
import { classForUnit } from "./classes";
import { remainingWeaponUses, spendWeaponUse, weaponMight } from "./equipment";
import { createRng, rollPercent } from "./rng";
import { distance } from "./movement";
import { awardCombatExperience } from "./progression";
import { effectiveStats, hasStatus } from "./status";

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
  const defense = attackerWeapon.damageKind === "magical" ? defenderStats.res : defenderStats.def + defenderTerrain.defense;
  const forgedMight = weaponMight(attacker, attackerWeapon);
  const basePower =
    attackerWeapon.damageKind === "magical"
      ? attackerStats.mag + forgedMight
      : (attackerStats.str + forgedMight) * multiplier;
  const damage = attackerCanUseWeapon
    ? Math.max(COMBAT.minDamage, Math.floor(basePower + triangle * COMBAT.counterMight - defense))
    : 0;
  const hit = attackerCanUseWeapon
    ? clampPercent(
        attackerWeapon.hit +
          attackerStats.skill * 2 +
          triangle * COMBAT.counterHit -
          (defenderStats.spd * 2 + defenderStats.luck + defenderTerrain.avoid),
      )
    : 0;
  const crit = attackerCanUseWeapon
    ? clampPercent(attackerWeapon.crit + Math.floor(attackerStats.skill * COMBAT.critFromSkill) - defenderStats.luck)
    : 0;
  const followUp = attackerCanUseWeapon && attackSpeed(attacker, attackerWeapon) - attackSpeed(defender, defenderWeapon) >= COMBAT.doublingThreshold;
  return {
    attackerId,
    defenderId,
    distance: cells,
    damage,
    hit,
    crit,
    followUp,
    defenderCanCounter: defenderCanUseWeapon && canAttackAtDistance(defenderWeapon, cells) && defenderWeapon.damageKind !== "healing",
    triangle,
    effectiveMultiplier: multiplier,
  };
}

export function resolveCombat(state: BattleState, attackerId: string, defenderId: string): CombatResolution {
  const forecast = forecastCombat(state, attackerId, defenderId);
  const attacker = findUnit(state, attackerId);
  const defender = findUnit(state, defenderId);
  const attackerWeapon = getWeapon(attacker.weaponId);
  const defenderWeapon = getWeapon(defender.weaponId);
  if (!canAttackAtDistance(attackerWeapon, forecast.distance) || attackerWeapon.damageKind === "healing") {
    throw new Error(`${attacker.id} cannot attack ${defender.id}`);
  }
  if (remainingWeaponUses(attacker) <= 0) {
    throw new Error(`${attacker.id} 的 ${attackerWeapon.name} 耐久耗尽。`);
  }

  const rng = createRng(state.rngState);
  const events: CombatEvent[] = [];
  strike(state, rng, events, attacker, defender);
  if (defender.alive && attacker.alive && forecast.defenderCanCounter) {
    strike(state, rng, events, defender, attacker);
  }
  if (defender.alive && attacker.alive && forecast.followUp) {
    strike(state, rng, events, attacker, defender);
  }
  if (defender.alive && attacker.alive && attackSpeed(defender, defenderWeapon) - attackSpeed(attacker, attackerWeapon) >= COMBAT.doublingThreshold) {
    strike(state, rng, events, defender, attacker);
  }

  const expLogs = awardCombatExperience(state, rng, events);
  state.rngState = rng.state;
  state.log.unshift(...eventsToLog(state, events), ...expLogs);
  return { forecast, events };
}

function strike(state: BattleState, rng: ReturnType<typeof createRng>, events: CombatEvent[], source: UnitInstance, target: UnitInstance): void {
  const sourceWeapon = getWeapon(source.weaponId);
  if (remainingWeaponUses(source) <= 0) {
    return;
  }
  const forecast = forecastCombat(state, source.id, target.id);
  const remainingUses = spendWeaponUse(source);
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
  target.hp = Math.max(0, target.hp - damage);
  events.push({ type: "hit", sourceId: source.id, targetId: target.id, damage, critical, remainingHp: target.hp });
  if (target.hp === 0) {
    const targetDef = getUnitDef(target.defId);
    target.alive = false;
    target.acted = true;
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

function clampPercent(value: number): number {
  return Math.max(0, Math.min(100, Math.floor(value)));
}
