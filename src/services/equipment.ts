import { ECONOMY, getWeapon } from "../data";
import type { RosterEntry, UnitInstance, WeaponDef } from "../models/types";

export function normalizeWeaponUses(weaponIds: readonly string[], uses?: Record<string, number>): Record<string, number> {
  const normalized: Record<string, number> = {};
  for (const weaponId of new Set(weaponIds)) {
    const weapon = getWeapon(weaponId);
    normalized[weaponId] = clampInteger(uses?.[weaponId] ?? weapon.durability, 0, weapon.durability);
  }
  return normalized;
}

export function normalizeWeaponForge(weaponIds: readonly string[], forge?: Record<string, number>): Record<string, number> {
  const normalized: Record<string, number> = {};
  for (const weaponId of new Set(weaponIds)) {
    normalized[weaponId] = clampInteger(forge?.[weaponId] ?? 0, 0, ECONOMY.forgeMaxLevel);
  }
  return normalized;
}

export function remainingWeaponUses(unit: Pick<UnitInstance, "weaponId" | "weaponUses">, weaponId = unit.weaponId): number {
  const weapon = getWeapon(weaponId);
  return clampInteger(unit.weaponUses[weaponId] ?? weapon.durability, 0, weapon.durability);
}

export function spendWeaponUse(unit: UnitInstance, weaponId = unit.weaponId): number {
  const remaining = remainingWeaponUses(unit, weaponId);
  const next = Math.max(0, remaining - 1);
  unit.weaponUses = { ...unit.weaponUses, [weaponId]: next };
  return next;
}

export function weaponForgeLevel(unit: Pick<UnitInstance, "weaponId" | "weaponForge">, weaponId = unit.weaponId): number {
  return clampInteger(unit.weaponForge[weaponId] ?? 0, 0, ECONOMY.forgeMaxLevel);
}

export function weaponMight(unit: Pick<UnitInstance, "weaponId" | "weaponForge">, weapon: WeaponDef): number {
  return weapon.might + weaponForgeLevel(unit, weapon.id) * ECONOMY.forgeMightPerLevel;
}

export function repairWeaponCost(entry: RosterEntry, weaponId = entry.weaponId): number {
  const weapon = getWeapon(weaponId);
  const missing = weapon.durability - clampInteger(entry.weaponUses[weaponId] ?? weapon.durability, 0, weapon.durability);
  if (missing <= 0) {
    return 0;
  }
  return Math.ceil((weapon.cost * ECONOMY.repairCostRatio * missing) / weapon.durability);
}

export function forgeWeaponCost(entry: RosterEntry, weaponId = entry.weaponId): number {
  const weapon = getWeapon(weaponId);
  const level = clampInteger(entry.weaponForge[weaponId] ?? 0, 0, ECONOMY.forgeMaxLevel);
  if (level >= ECONOMY.forgeMaxLevel) {
    return 0;
  }
  return weapon.cost * (level + 1);
}

function clampInteger(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) {
    return max;
  }
  return Math.max(min, Math.min(max, Math.floor(value)));
}
