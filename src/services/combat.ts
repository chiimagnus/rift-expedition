import {
  COMBAT,
  getClass,
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
import { createRng, rollPercent } from "./rng";
import { distance } from "./movement";
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
  const tags = getClass(getUnitDef(defender.defId).classId).tags;
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
  const cells = distance(attacker.pos, defender.pos);
  const defenderTerrainId = state.grid[defender.pos.y]?.[defender.pos.x];
  if (!defenderTerrainId) {
    throw new Error(`Defender is outside map: ${defender.id}`);
  }
  const defenderTerrain = getTerrain(defenderTerrainId);
  const triangle = triangleValue(attackerWeapon, defenderWeapon);
  const multiplier = effectiveMultiplier(attackerWeapon, defender);
  const defense = attackerWeapon.damageKind === "magical" ? defenderStats.res : defenderStats.def + defenderTerrain.defense;
  const basePower =
    attackerWeapon.damageKind === "magical"
      ? attackerStats.mag + attackerWeapon.might
      : (attackerStats.str + attackerWeapon.might) * multiplier;
  const damage = Math.max(COMBAT.minDamage, Math.floor(basePower + triangle * COMBAT.counterMight - defense));
  const hit = clampPercent(
      attackerWeapon.hit +
      attackerStats.skill * 2 +
      triangle * COMBAT.counterHit -
      (defenderStats.spd * 2 + defenderStats.luck + defenderTerrain.avoid),
  );
  const crit = clampPercent(attackerWeapon.crit + Math.floor(attackerStats.skill * COMBAT.critFromSkill) - defenderStats.luck);
  const followUp = attackSpeed(attacker, attackerWeapon) - attackSpeed(defender, defenderWeapon) >= COMBAT.doublingThreshold;
  return {
    attackerId,
    defenderId,
    distance: cells,
    damage,
    hit,
    crit,
    followUp,
    defenderCanCounter: canAttackAtDistance(defenderWeapon, cells) && defenderWeapon.damageKind !== "healing",
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

  state.rngState = rng.state;
  state.log.unshift(...eventsToLog(state, events));
  return { forecast, events };
}

function strike(state: BattleState, rng: ReturnType<typeof createRng>, events: CombatEvent[], source: UnitInstance, target: UnitInstance): void {
  const forecast = forecastCombat(state, source.id, target.id);
  const hit = rollPercent(rng, forecast.hit, COMBAT.doubleRNG);
  if (!hit) {
    events.push({ type: "miss", sourceId: source.id, targetId: target.id });
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
}

function eventsToLog(state: BattleState, events: CombatEvent[]): string[] {
  return events.map((event) => {
    const sourceName = unitName(state, event.sourceId);
    const targetName = unitName(state, event.targetId);
    if (event.type === "miss") {
      return `${sourceName} 的攻击落空。`;
    }
    if (event.type === "defeat") {
      return event.retreat ? `${targetName} 撤退。` : `${targetName} 倒下。`;
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
