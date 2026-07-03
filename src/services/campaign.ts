import { chapterCatalog, endingCatalog, getChapter } from "../data";
import type { CampaignState, EndingDef, StoryChoice } from "../models/types";

const SAVE_KEY = "rift-expedition.save.v1";
const SAVE_VERSION = 1;

export interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

export function createNewCampaign(mode: CampaignState["mode"] = "classic"): CampaignState {
  return {
    version: SAVE_VERSION,
    currentChapterId: "ch01",
    completedChapterIds: [],
    roster: ["aldric", "valentin", "mirelle", "cecilia", "rowan", "seren"],
    fallen: [],
    bonds: {},
    taint: { aldric: 0, elara: 0 },
    flags: {},
    mode,
    seed: 0x5eedc0de,
    savedAt: Date.now(),
  };
}

export function loadCampaign(storage: StorageLike | undefined): CampaignState {
  if (!storage) {
    return createNewCampaign();
  }
  const raw = storage.getItem(SAVE_KEY);
  if (!raw) {
    return createNewCampaign();
  }
  try {
    return migrateCampaign(JSON.parse(raw) as Partial<CampaignState>);
  } catch {
    return createNewCampaign();
  }
}

export function saveCampaign(storage: StorageLike | undefined, campaign: CampaignState): void {
  if (!storage) {
    return;
  }
  storage.setItem(SAVE_KEY, JSON.stringify({ ...campaign, savedAt: Date.now() }));
}

export function clearCampaign(storage: StorageLike | undefined): void {
  storage?.removeItem(SAVE_KEY);
}

export function completeCurrentChapter(campaign: CampaignState): CampaignState {
  const chapter = getChapter(campaign.currentChapterId);
  const completed = campaign.completedChapterIds.includes(chapter.id)
    ? campaign.completedChapterIds
    : [...campaign.completedChapterIds, chapter.id];
  const nextChapterId = chapter.nextChapterId;
  if (!nextChapterId) {
    const ending = chooseEnding(campaign);
    return { ...campaign, completedChapterIds: completed, endingId: ending.id, savedAt: Date.now() };
  }
  return { ...campaign, completedChapterIds: completed, currentChapterId: nextChapterId, savedAt: Date.now() };
}

export function applyStoryChoice(campaign: CampaignState, choice: StoryChoice, optionIndex: number): CampaignState {
  const option = choice.options[optionIndex];
  if (!option) {
    throw new Error(`Invalid option ${optionIndex} for choice ${choice.id}`);
  }
  return {
    ...campaign,
    flags: { ...campaign.flags, [option.flag]: option.value },
    savedAt: Date.now(),
  };
}

export function chooseEnding(campaign: CampaignState): EndingDef {
  const endingChoice = campaign.flags.endingChoice;
  const totalTaint = Object.values(campaign.taint).reduce((sum, value) => sum + value, 0);
  if (totalTaint >= 6) {
    return endingCatalog.find((ending) => ending.id === "dragonfall") ?? endingCatalog[3]!;
  }
  if (endingChoice === 1) {
    return endingCatalog.find((ending) => ending.id === "sacrifice_aldric") ?? endingCatalog[0]!;
  }
  if (endingChoice === 2) {
    return endingCatalog.find((ending) => ending.id === "sacrifice_elara") ?? endingCatalog[1]!;
  }
  if (endingChoice === 3 && (campaign.bonds["aldric:elara"] ?? 0) >= 180) {
    return endingCatalog.find((ending) => ending.id === "defy_god") ?? endingCatalog[2]!;
  }
  return endingCatalog.find((ending) => ending.id === "sacrifice_aldric") ?? endingCatalog[0]!;
}

export function nextChapterExists(campaign: CampaignState): boolean {
  return chapterCatalog.some((chapter) => chapter.id === campaign.currentChapterId);
}

function migrateCampaign(raw: Partial<CampaignState>): CampaignState {
  const fresh = createNewCampaign();
  const currentChapterId =
    typeof raw.currentChapterId === "string" && chapterCatalog.some((chapter) => chapter.id === raw.currentChapterId)
      ? raw.currentChapterId
      : fresh.currentChapterId;
  return {
    ...fresh,
    ...raw,
    version: SAVE_VERSION,
    currentChapterId,
    completedChapterIds: Array.isArray(raw.completedChapterIds) ? raw.completedChapterIds.filter((id): id is string => typeof id === "string") : [],
    roster: Array.isArray(raw.roster) ? raw.roster.filter((id): id is string => typeof id === "string") : fresh.roster,
    fallen: Array.isArray(raw.fallen) ? raw.fallen.filter((id): id is string => typeof id === "string") : [],
    bonds: isRecord(raw.bonds) ? raw.bonds : {},
    taint: isRecord(raw.taint) ? raw.taint : fresh.taint,
    flags: isRecord(raw.flags) ? raw.flags : {},
    mode: raw.mode === "casual" ? "casual" : "classic",
    seed: typeof raw.seed === "number" ? raw.seed : fresh.seed,
    savedAt: typeof raw.savedAt === "number" ? raw.savedAt : Date.now(),
    ...(typeof raw.endingId === "string" ? { endingId: raw.endingId } : {}),
  };
}

function isRecord(value: unknown): value is Record<string, number | boolean> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
