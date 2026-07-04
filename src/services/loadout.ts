import { ECONOMY, getWeapon } from "../data";
import type { CampaignState, RosterEntry } from "../models/types";
import { baseClassId, canClassUseWeapon, canRosterUseWeapon } from "./classes";
import { forgeWeaponCost, normalizeWeaponForge, normalizeWeaponUses, repairWeaponCost } from "./equipment";

export function setRosterDeployment(campaign: CampaignState, unitDefId: string, deployed: boolean, requiredUnitIds?: readonly string[]): CampaignState {
  const entry = findRosterEntry(campaign, unitDefId);
  if (!deployed && deployedRoster(campaign, requiredUnitIds).filter((candidate) => candidate.unitDefId !== unitDefId).length === 0) {
    throw new Error("至少需要一名单位出战。");
  }
  return {
    ...campaign,
    roster: campaign.roster.map((candidate) =>
      candidate.unitDefId === entry.unitDefId ? { ...cloneRosterEntry(candidate), deployed } : cloneRosterEntry(candidate),
    ),
    savedAt: Date.now(),
  };
}

export function cycleRosterWeapon(campaign: CampaignState, unitDefId: string, step = 1): CampaignState {
  const entry = findRosterEntry(campaign, unitDefId);
  if (entry.weaponIds.length <= 1) {
    return campaign;
  }
  const currentIndex = Math.max(0, entry.weaponIds.indexOf(entry.weaponId));
  const nextIndex = (currentIndex + step + entry.weaponIds.length) % entry.weaponIds.length;
  return setRosterWeapon(campaign, unitDefId, entry.weaponIds[nextIndex]!);
}

export function buyWeapon(campaign: CampaignState, weaponId: string, count = 1): CampaignState {
  const weapon = getWeapon(weaponId);
  const totalCost = weapon.cost * count;
  if (count <= 0) {
    throw new Error("购买数量必须大于 0。");
  }
  if (campaign.gold < totalCost) {
    throw new Error("金币不足。");
  }
  const owned = campaign.convoy[weaponId] ?? 0;
  if (owned + count > ECONOMY.convoyCapacityPerWeapon) {
    throw new Error("仓库已满。");
  }
  return {
    ...campaign,
    gold: campaign.gold - totalCost,
    convoy: { ...campaign.convoy, [weaponId]: owned + count },
    savedAt: Date.now(),
  };
}

export function assignConvoyWeapon(campaign: CampaignState, unitDefId: string, weaponId: string): CampaignState {
  const entry = findRosterEntry(campaign, unitDefId);
  if ((campaign.convoy[weaponId] ?? 0) <= 0) {
    throw new Error("仓库没有这件武器。");
  }
  if (!canRosterUseWeapon(entry, weaponId)) {
    throw new Error("该单位无法装备这类武器。");
  }
  if (entry.weaponIds.includes(weaponId)) {
    return setRosterWeapon(campaign, unitDefId, weaponId);
  }
  if (entry.weaponIds.length >= ECONOMY.rosterWeaponCapacity) {
    throw new Error("武器栏已满。");
  }
  return {
    ...campaign,
    convoy: { ...campaign.convoy, [weaponId]: (campaign.convoy[weaponId] ?? 0) - 1 },
    roster: campaign.roster.map((candidate) =>
      candidate.unitDefId === entry.unitDefId
        ? {
            ...cloneRosterEntry(candidate),
            weaponId,
            weaponIds: [...candidate.weaponIds, weaponId],
            weaponUses: { ...candidate.weaponUses, [weaponId]: getWeapon(weaponId).durability },
            weaponForge: { ...candidate.weaponForge, [weaponId]: 0 },
          }
        : cloneRosterEntry(candidate),
    ),
    savedAt: Date.now(),
  };
}

export function repairRosterWeapon(campaign: CampaignState, unitDefId: string, weaponId?: string): CampaignState {
  const entry = findRosterEntry(campaign, unitDefId);
  const targetWeaponId = weaponId ?? entry.weaponId;
  if (!entry.weaponIds.includes(targetWeaponId)) {
    throw new Error("该单位未携带这件武器。");
  }
  const cost = repairWeaponCost(entry, targetWeaponId);
  if (cost <= 0) {
    return campaign;
  }
  if (campaign.gold < cost) {
    throw new Error("金币不足。");
  }
  const weapon = getWeapon(targetWeaponId);
  return {
    ...campaign,
    gold: campaign.gold - cost,
    roster: campaign.roster.map((candidate) =>
      candidate.unitDefId === entry.unitDefId
        ? { ...cloneRosterEntry(candidate), weaponUses: { ...candidate.weaponUses, [targetWeaponId]: weapon.durability } }
        : cloneRosterEntry(candidate),
    ),
    savedAt: Date.now(),
  };
}

export function forgeRosterWeapon(campaign: CampaignState, unitDefId: string, weaponId?: string): CampaignState {
  const entry = findRosterEntry(campaign, unitDefId);
  const targetWeaponId = weaponId ?? entry.weaponId;
  if (!entry.weaponIds.includes(targetWeaponId)) {
    throw new Error("该单位未携带这件武器。");
  }
  const cost = forgeWeaponCost(entry, targetWeaponId);
  if (cost <= 0) {
    throw new Error("锻造已满。");
  }
  if (campaign.gold < cost) {
    throw new Error("金币不足。");
  }
  return {
    ...campaign,
    gold: campaign.gold - cost,
    roster: campaign.roster.map((candidate) =>
      candidate.unitDefId === entry.unitDefId
        ? { ...cloneRosterEntry(candidate), weaponForge: { ...candidate.weaponForge, [targetWeaponId]: (candidate.weaponForge[targetWeaponId] ?? 0) + 1 } }
        : cloneRosterEntry(candidate),
    ),
    savedAt: Date.now(),
  };
}

export function canUseWeapon(unitDefId: string, weaponId: string): boolean {
  return canClassUseWeapon(baseClassId(unitDefId), weaponId);
}

function setRosterWeapon(campaign: CampaignState, unitDefId: string, weaponId: string): CampaignState {
  const entry = findRosterEntry(campaign, unitDefId);
  if (!entry.weaponIds.includes(weaponId)) {
    throw new Error("该单位未携带这件武器。");
  }
  if (!canRosterUseWeapon(entry, weaponId)) {
    throw new Error("该单位无法装备这类武器。");
  }
  return {
    ...campaign,
    roster: campaign.roster.map((candidate) =>
      candidate.unitDefId === entry.unitDefId ? { ...cloneRosterEntry(candidate), weaponId } : cloneRosterEntry(candidate),
    ),
    savedAt: Date.now(),
  };
}

function deployedRoster(campaign: CampaignState, unitIds?: readonly string[]): RosterEntry[] {
  const required = unitIds ? new Set(unitIds) : undefined;
  return campaign.roster.filter((entry) => entry.deployed && !campaign.fallen.includes(entry.unitDefId) && (!required || required.has(entry.unitDefId)));
}

function findRosterEntry(campaign: CampaignState, unitDefId: string): RosterEntry {
  const entry = campaign.roster.find((candidate) => candidate.unitDefId === unitDefId);
  if (!entry) {
    throw new Error(`Unknown roster unit: ${unitDefId}`);
  }
  return entry;
}

function cloneRosterEntry(entry: RosterEntry): RosterEntry {
  return {
    ...entry,
    stats: { ...entry.stats },
    weaponIds: [...entry.weaponIds],
    // ponytail: keyed by weapon id until the convoy becomes true item instances.
    weaponUses: normalizeWeaponUses(entry.weaponIds, entry.weaponUses),
    weaponForge: normalizeWeaponForge(entry.weaponIds, entry.weaponForge),
    skillIds: [...entry.skillIds],
  };
}
