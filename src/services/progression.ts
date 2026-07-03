import { GROWTH, getUnitDef } from "../data";
import type { BattleState, CombatEvent, Stats, UnitInstance } from "../models/types";
import type { Rng } from "./rng";
import { rollPercent } from "./rng";

const growthStats = ["hp", "str", "mag", "skill", "spd", "luck", "def", "res"] as const;
type GrowthStat = (typeof growthStats)[number];

export function nextExpForLevel(level: number): number {
  return Math.max(1, Math.floor(GROWTH.baseNextExp * level ** GROWTH.nextExpExponent));
}

export function awardCombatExperience(state: BattleState, rng: Rng, events: CombatEvent[]): string[] {
  const awards = new Map<string, number>();
  for (const event of events) {
    if (event.type === "hit") {
      addAward(awards, event.sourceId, GROWTH.hitExp);
    } else if (event.type === "defeat") {
      const source = state.units.find((unit) => unit.id === event.sourceId);
      const target = state.units.find((unit) => unit.id === event.targetId);
      if (source && target) {
        const levelGap = Math.max(1, target.level - source.level);
        addAward(awards, source.id, GROWTH.killBaseExp + levelGap * GROWTH.killLevelBonus);
      }
    }
  }

  const logs: string[] = [];
  for (const [unitId, amount] of awards) {
    const unit = state.units.find((candidate) => candidate.id === unitId);
    if (unit) {
      logs.push(...gainExperience(state, rng, unit, amount));
    }
  }
  return logs;
}

export function gainExperience(state: BattleState, rng: Rng, unit: UnitInstance, amount: number): string[] {
  if (unit.team !== "ally" || !unit.alive || amount <= 0 || unit.level >= GROWTH.levelCap) {
    return [];
  }

  const unitDef = getUnitDef(unit.defId);
  const logs: string[] = [];
  unit.exp += Math.floor(amount);
  while (unit.level < GROWTH.levelCap && unit.exp >= nextExpForLevel(unit.level)) {
    unit.exp -= nextExpForLevel(unit.level);
    unit.level += 1;
    const gains = rollLevelGrowth(unit.stats, unitDef.growths, rng);
    if (gains.includes("hp")) {
      unit.hp += 1;
    }
    logs.push(`${unitDef.name} 升到 Lv.${unit.level}：${formatGains(gains)}。`);
  }
  return logs;
}

function addAward(awards: Map<string, number>, unitId: string, amount: number): void {
  awards.set(unitId, (awards.get(unitId) ?? 0) + amount);
}

function rollLevelGrowth(stats: Stats, growths: Pick<Stats, GrowthStat>, rng: Rng): GrowthStat[] {
  const gains: GrowthStat[] = [];
  for (const stat of growthStats) {
    if (rollPercent(rng, growths[stat], false)) {
      stats[stat] += 1;
      gains.push(stat);
    }
  }
  if (gains.length === 0) {
    const fallback = growthStats.reduce((best, stat) => (growths[stat] > growths[best] ? stat : best), "hp");
    stats[fallback] += 1;
    gains.push(fallback);
  }
  return gains;
}

function formatGains(gains: GrowthStat[]): string {
  const names: Record<GrowthStat, string> = {
    hp: "HP",
    str: "力",
    mag: "魔",
    skill: "技",
    spd: "速",
    luck: "运",
    def: "防",
    res: "魔防",
  };
  return gains.map((gain) => `${names[gain]}+1`).join(" ");
}
