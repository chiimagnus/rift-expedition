import { COMBAT } from "../data";
import type { BattleState, TerrainDef, UnitInstance, WeaponDef, WeaponKind } from "../models/types";
import { classForUnit } from "./classes";

const DREAD_AURA_RANGE = 2;

export function hasSkill(unit: Pick<UnitInstance, "skillIds">, skillId: string): boolean {
  return unit.skillIds.includes(skillId);
}

export function attackRange(unit: Pick<UnitInstance, "skillIds">, weapon: WeaponDef): [number, number] {
  const bonus =
    (hasSkill(unit, "cloud_piercer") && weapon.kind === "bow" ? 1 : 0) +
    (hasSkill(unit, "ballista_lockon") && (weapon.kind === "bow" || weapon.kind === "thunder") ? 2 : 0);
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
  if (hasSkill(attacker, "archmage_focus") && isElementalMagic(weapon.kind)) {
    bonus += 3;
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
  if (!defender.moved && hasSkill(defender, "hold_fast")) {
    const baseDefense = magical ? defender.stats.res : defender.stats.def;
    bonus += Math.max(1, Math.floor(baseDefense * 0.3));
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
  if (hasSkill(attacker, "feint_snare") && adjacentAllies(state, attacker).length > 0) {
    bonus += 10;
  }
  if (nearbyEnemies(state, attacker, DREAD_AURA_RANGE).some((enemy) => hasSkill(enemy, "black_knight_dread"))) {
    bonus -= 10;
  }
  return bonus;
}

export function avoidBonus(state: BattleState, defender: UnitInstance, attackerWeapon?: WeaponDef): number {
  let bonus = hasSkill(defender, "oath_resonance") && adjacentAllies(state, defender).length > 0 ? 15 : 0;
  if (attackerWeapon?.kind === "bow" && hasSkill(defender, "anti_arrow_stance")) {
    bonus += 20;
  }
  if (defender.statuses.some((status) => status.id === "marked" && status.turns > 0)) {
    bonus -= 15;
  }
  return bonus;
}

export function rangeHitPenalty(attacker: UnitInstance, weapon: WeaponDef, cells: number): number {
  if (cells <= weapon.range[1] || hasSkill(attacker, "ballista_lockon")) {
    return 0;
  }
  return COMBAT.longRangeHitPenalty;
}

export function primeBloodMemory(state: BattleState, fallen: UnitInstance): UnitInstance[] {
  const witnesses = state.units.filter(
    (unit) =>
      unit.alive &&
      unit.team === fallen.team &&
      unit.id !== fallen.id &&
      hasSkill(unit, "blood_memory") &&
      classForUnit(unit).tags.includes("dragon"),
  );
  for (const witness of witnesses) {
    witness.skillUses.blood_memory = 1;
  }
  return witnesses;
}

export function consumeBloodMemory(unit: UnitInstance): boolean {
  if ((unit.skillUses.blood_memory ?? 0) <= 0) {
    return false;
  }
  unit.skillUses.blood_memory = (unit.skillUses.blood_memory ?? 0) - 1;
  return true;
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
  if (hasSkill(unit, "pathfinder") && classForUnit(unit).tags.includes("infantry")) {
    return terrain.id === "forest" || terrain.id === "deep_forest" || terrain.id === "mountain" || terrain.id === "peak";
  }
  return hasSkill(unit, "snowstep") && (terrain.id === "mountain" || terrain.id === "peak");
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

function nearbyEnemies(state: BattleState, unit: UnitInstance, range: number): UnitInstance[] {
  return state.units.filter(
    (candidate) =>
      candidate.alive &&
      candidate.team !== unit.team &&
      Math.abs(candidate.pos.x - unit.pos.x) + Math.abs(candidate.pos.y - unit.pos.y) <= range,
  );
}

function isElementalMagic(kind: WeaponKind): boolean {
  return kind === "fire" || kind === "ice" || kind === "thunder";
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
