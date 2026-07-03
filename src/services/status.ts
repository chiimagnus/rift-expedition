import type { Stats, StatusEffect, UnitInstance } from "../models/types";

export function hasStatus(unit: UnitInstance, id: StatusEffect["id"]): boolean {
  return unit.statuses.some((status) => status.id === id && status.turns > 0);
}

export function addStatus(unit: UnitInstance, effect: StatusEffect): void {
  const current = unit.statuses.find((status) => status.id === effect.id);
  if (current) {
    current.turns = Math.max(current.turns, effect.turns);
    return;
  }
  unit.statuses.push({ ...effect });
}

export function tickStatuses(unit: UnitInstance): void {
  unit.statuses = unit.statuses
    .map((status) => ({ ...status, turns: status.turns - 1 }))
    .filter((status) => status.turns > 0);
}

export function effectiveStats(unit: UnitInstance): Stats {
  const stats = { ...unit.stats };
  if (hasStatus(unit, "stigma_awaken")) {
    stats.str += 5;
    stats.mag += 5;
    stats.skill += 5;
    stats.spd += 5;
    stats.def += 5;
    stats.res += 5;
  }
  if (hasStatus(unit, "sprint")) {
    stats.move += 3;
  }
  return stats;
}
