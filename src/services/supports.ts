import { BOND, supportPairCatalog } from "../data";
import type { CampaignState, SupportPairDef, SupportRank } from "../models/types";

const rankOrder: SupportRank[] = ["C", "B", "A", "S"];

export interface AvailableSupportConversation {
  pair: SupportPairDef;
  rank: SupportRank;
  viewed: boolean;
  key: string;
}

export function bondKey(left: string, right: string): string {
  return [left, right].sort().join(":");
}

export function supportConversationKey(pairId: string, rank: SupportRank): string {
  return `support:${pairId}:${rank}`;
}

export function bondRank(value: number, ranks: SupportRank[] = rankOrder): SupportRank | undefined {
  let unlocked: SupportRank | undefined;
  for (const rank of rankOrder) {
    if (ranks.includes(rank) && value >= BOND[rank]) {
      unlocked = rank;
    }
  }
  return unlocked;
}

export function availableSupportConversations(campaign: CampaignState): AvailableSupportConversation[] {
  const roster = new Set(campaign.roster.map((entry) => entry.unitDefId));
  const fallen = new Set(campaign.fallen);
  const available: AvailableSupportConversation[] = [];

  for (const pair of supportPairCatalog) {
    if (!pair.units.every((unitId) => roster.has(unitId) && !fallen.has(unitId))) {
      continue;
    }
    const value = campaign.bonds[bondKey(pair.units[0], pair.units[1])] ?? 0;
    for (const rank of pair.ranks) {
      if (value < BOND[rank]) {
        continue;
      }
      const key = supportConversationKey(pair.id, rank);
      available.push({ pair, rank, viewed: campaign.flags[key] === true, key });
    }
  }

  return available.sort((left, right) => {
    if (left.viewed !== right.viewed) {
      return left.viewed ? 1 : -1;
    }
    return supportLabel(left).localeCompare(supportLabel(right), "zh-Hans-CN");
  });
}

export function firstUnviewedSupportConversation(campaign: CampaignState): AvailableSupportConversation | undefined {
  return availableSupportConversations(campaign).find((conversation) => !conversation.viewed);
}

export function supportLabel(conversation: AvailableSupportConversation): string {
  return `${conversation.pair.id} ${conversation.rank}`;
}

export function viewSupportConversation(campaign: CampaignState, pairId: string, rank: SupportRank): CampaignState {
  const pair = supportPairCatalog.find((candidate) => candidate.id === pairId);
  if (!pair || !pair.ranks.includes(rank) || !pair.conversations.some((conversation) => conversation.rank === rank)) {
    throw new Error(`Unknown support conversation: ${pairId}:${rank}`);
  }
  if ((campaign.bonds[bondKey(pair.units[0], pair.units[1])] ?? 0) < BOND[rank]) {
    throw new Error(`Support conversation is locked: ${pairId}:${rank}`);
  }

  const shouldUnlockSkill = rankOrder.indexOf(rank) >= rankOrder.indexOf(pair.unlockRank);
  return {
    ...campaign,
    roster: campaign.roster.map((entry) => {
      if (!shouldUnlockSkill || !pair.units.includes(entry.unitDefId) || entry.skillIds.includes(pair.unlockSkillId)) {
        return cloneRosterEntry(entry);
      }
      return { ...cloneRosterEntry(entry), skillIds: [...entry.skillIds, pair.unlockSkillId] };
    }),
    flags: { ...campaign.flags, [supportConversationKey(pair.id, rank)]: true },
    savedAt: Date.now(),
  };
}

function cloneRosterEntry(entry: CampaignState["roster"][number]): CampaignState["roster"][number] {
  return {
    ...entry,
    stats: { ...entry.stats },
    weaponIds: [...entry.weaponIds],
    weaponUses: { ...entry.weaponUses },
    weaponForge: { ...entry.weaponForge },
    skillIds: [...entry.skillIds],
  };
}
