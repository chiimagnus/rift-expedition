import type { BattleState, TerrainDef, UnitInstance, WeaponDef } from "../models/types";
import { classForUnit } from "./classes";

export function hasSkill(unit: Pick<UnitInstance, "skillIds">, skillId: string): boolean {
  return unit.skillIds.includes(skillId);
}

export function attackRange(unit: Pick<UnitInstance, "skillIds">, weapon: WeaponDef): [number, number] {
  const bonus = hasSkill(unit, "cloud_piercer") && weapon.kind === "bow" ? 1 : 0;
  return [weapon.range[0], weapon.range[1] + bonus];
}

export function canUnitAttackAtDistance(unit: Pick<UnitInstance, "skillIds">, weapon: WeaponDef, cells: number): boolean {
  const range = attackRange(unit, weapon);
  return cells >= range[0] && cells <= range[1];
}

export function ignoresTerrainAvoid(attacker: Pick<UnitInstance, "skillIds">, weapon: WeaponDef): boolean {
  return hasSkill(attacker, "cloud_piercer") && weapon.kind === "bow";
}

export function armorBreaks(attacker: Pick<UnitInstance, "skillIds">, weapon: WeaponDef): boolean {
  return hasSkill(attacker, "armor_break") && weapon.kind === "axe";
}

export function damageBonus(state: BattleState, attacker: UnitInstance, defender: UnitInstance, weapon: WeaponDef): number {
  let bonus = 0;
  const defenderTags = classForUnit(defender).tags;
  if (hasSkill(attacker, "vengeance")) {
    bonus += Math.floor((attacker.stats.hp - attacker.hp) / 2);
  }
  if (hasSkill(attacker, "linebreaker") && defenderTags.includes("armored")) {
    bonus += 3;
  }
  if (hasSkill(attacker, "mage_slayer") && defenderTags.includes("mage")) {
    bonus += 3;
  }
  if (hasSkill(attacker, "dive") && classForUnit(attacker).tags.includes("flying") && terrainHeight(state, attacker) > terrainHeight(state, defender)) {
    bonus += 3;
  }
  if (hasSkill(attacker, "dragon_slayer") && weapon.effectiveTags?.includes("dragon") && defenderTags.includes("dragon")) {
    bonus += weapon.might * 2;
  }
  bonus += statusValue(attacker, "charge");
  return bonus;
}

export function defenseBonus(state: BattleState, defender: UnitInstance, terrain: TerrainDef, magical: boolean): number {
  let bonus = 0;
  if ((terrain.id === "forest" || terrain.id === "deep_forest") && hasSkill(defender, "forest_guard")) {
    bonus += 2;
  }
  if (defender.hp <= Math.floor(defender.stats.hp * 0.3) && hasSkill(defender, "last_stand")) {
    bonus += 3;
  }
  if (adjacentAllies(state, defender).some((ally) => hasSkill(ally, "shield_wall") && classForUnit(ally).tags.includes("armored"))) {
    bonus += magical ? 0 : 2;
  }
  return bonus;
}

export function hitBonus(state: BattleState, attacker: UnitInstance): number {
  let bonus = 0;
  if (adjacentAllies(state, attacker).some((ally) => hasSkill(ally, "battle_prayer"))) {
    bonus += 5;
  }
  if (hasSkill(attacker, "oath_resonance") && adjacentAllies(state, attacker).length > 0) {
    bonus += 15;
  }
  return bonus;
}

export function avoidBonus(state: BattleState, defender: UnitInstance): number {
  let bonus = hasSkill(defender, "oath_resonance") && adjacentAllies(state, defender).length > 0 ? 15 : 0;
  if (defender.statuses.some((status) => status.id === "marked" && status.turns > 0)) {
    bonus -= 15;
  }
  return bonus;
}

export function critMultiplier(state: BattleState, attacker: UnitInstance): number {
  if (hasSkill(attacker, "twin_pincer") && adjacentAllies(state, attacker).length > 0) {
    return 100;
  }
  return hasSkill(attacker, "iaijutsu") ? 2 : 1;
}

export function critAvoidBonus(defender: UnitInstance): number {
  return hasSkill(defender, "calm") ? 100 : hasSkill(defender, "lucky_star") ? defender.stats.luck : 0;
}

export function followUpThreshold(attacker: UnitInstance, weapon: WeaponDef): number {
  return hasSkill(attacker, "quickdraw") && weapon.kind === "bow" ? 3 : 4;
}

export function foresightReady(attacker: UnitInstance, defender: UnitInstance): boolean {
  return hasSkill(defender, "foresight") && (defender.skillUses.foresight ?? 0) === 0 && defender.stats.spd - attacker.stats.spd >= 5;
}

export function ignoresTerrainSlow(unit: UnitInstance, terrain: TerrainDef): boolean {
  if (!hasSkill(unit, "pathfinder") || !classForUnit(unit).tags.includes("infantry")) {
    return false;
  }
  return terrain.id === "forest" || terrain.id === "deep_forest" || terrain.id === "mountain" || terrain.id === "peak";
}

function adjacentAllies(state: BattleState, unit: UnitInstance): UnitInstance[] {
  return state.units.filter(
    (candidate) =>
      candidate.alive &&
      candidate.team === unit.team &&
      candidate.id !== unit.id &&
      Math.abs(candidate.pos.x - unit.pos.x) + Math.abs(candidate.pos.y - unit.pos.y) <= 1,
  );
}

function terrainHeight(state: BattleState, unit: UnitInstance): number {
  const terrainId = state.grid[unit.pos.y]?.[unit.pos.x];
  if (terrainId === "peak") {
    return 3;
  }
  if (terrainId === "mountain" || terrainId === "cliff") {
    return 2;
  }
  return terrainId === "forest" || terrainId === "deep_forest" ? 1 : 0;
}

function statusValue(unit: UnitInstance, id: UnitInstance["statuses"][number]["id"]): number {
  return unit.statuses.find((status) => status.id === id && status.turns > 0)?.value ?? 0;
}
