import { GROWTH, getClass, getSkill, getUnitDef, getWeapon } from "../data";
import type { CampaignState, ClassDef, RosterEntry, Stats, UnitInstance } from "../models/types";

const promotionBonus: Stats = {
  hp: 3,
  str: 1,
  mag: 1,
  skill: 1,
  spd: 1,
  luck: 0,
  def: 1,
  res: 1,
  move: 1,
  con: 1,
};

export function classForUnit(unit: Pick<UnitInstance, "classId">): ClassDef {
  return getClass(unit.classId);
}

export function classForRoster(entry: Pick<RosterEntry, "classId">): ClassDef {
  return getClass(entry.classId);
}

export function canClassUseWeapon(classId: string, weaponId: string): boolean {
  return getClass(classId).weaponKinds.includes(getWeapon(weaponId).kind);
}

export function canRosterUseWeapon(entry: Pick<RosterEntry, "classId">, weaponId: string): boolean {
  return canClassUseWeapon(entry.classId, weaponId);
}

export function promotionTargets(entry: Pick<RosterEntry, "classId" | "level">): string[] {
  if (entry.level < GROWTH.promotionLevel) {
    return [];
  }
  return [...(getClass(entry.classId).promotesTo ?? [])];
}

export function promoteRosterUnit(campaign: CampaignState, unitDefId: string, targetClassId: string): CampaignState {
  const entry = campaign.roster.find((candidate) => candidate.unitDefId === unitDefId);
  if (!entry) {
    throw new Error(`Unknown roster unit: ${unitDefId}`);
  }
  const targets = getClass(entry.classId).promotesTo ?? [];
  if (!targets.includes(targetClassId)) {
    throw new Error("该职业不能转为目标职业。");
  }
  if (entry.level < GROWTH.promotionLevel) {
    throw new Error(`Lv.${GROWTH.promotionLevel} 后才能转职。`);
  }

  const targetClass = getClass(targetClassId);
  const weaponId = canClassUseWeapon(targetClassId, entry.weaponId) ? entry.weaponId : firstUsableWeapon(entry, targetClass);
  if (!weaponId) {
    throw new Error("没有可装备的武器，无法完成转职。");
  }

  return {
    ...campaign,
    roster: campaign.roster.map((candidate) =>
      candidate.unitDefId === entry.unitDefId
        ? {
            ...cloneRosterEntry(candidate),
            classId: targetClass.id,
            stats: promotedStats(candidate.stats),
            weaponId,
            skillIds: mergeSkillIds(candidate.skillIds, targetClass.skillIds ?? []),
          }
        : cloneRosterEntry(candidate),
    ),
    savedAt: Date.now(),
  };
}

export function baseClassId(unitDefId: string): string {
  return getUnitDef(unitDefId).classId;
}

export function isKnownClassId(classId: string): boolean {
  try {
    getClass(classId);
    return true;
  } catch {
    return false;
  }
}

function firstUsableWeapon(entry: RosterEntry, classDef: ClassDef): string | undefined {
  return entry.weaponIds.find((weaponId) => classDef.weaponKinds.includes(getWeapon(weaponId).kind));
}

function promotedStats(stats: Stats): Stats {
  // ponytail: starting promotion bump; replace with per-class tables after A/09 balance sims cover Act 2.
  return {
    hp: Math.min(60, stats.hp + promotionBonus.hp),
    str: Math.min(30, stats.str + promotionBonus.str),
    mag: Math.min(30, stats.mag + promotionBonus.mag),
    skill: Math.min(30, stats.skill + promotionBonus.skill),
    spd: Math.min(30, stats.spd + promotionBonus.spd),
    luck: Math.min(30, stats.luck + promotionBonus.luck),
    def: Math.min(30, stats.def + promotionBonus.def),
    res: Math.min(30, stats.res + promotionBonus.res),
    move: stats.move + promotionBonus.move,
    con: stats.con + promotionBonus.con,
  };
}

function mergeSkillIds(current: string[], added: string[]): string[] {
  for (const skillId of added) {
    getSkill(skillId);
  }
  return [...new Set([...current, ...added])];
}

function cloneRosterEntry(entry: RosterEntry): RosterEntry {
  return {
    ...entry,
    stats: { ...entry.stats },
    weaponIds: [...entry.weaponIds],
    weaponUses: { ...entry.weaponUses },
    weaponForge: { ...entry.weaponForge },
    skillIds: [...entry.skillIds],
  };
}
