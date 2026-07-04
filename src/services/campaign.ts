import { ECONOMY, chapterCatalog, endingCatalog, getChapter, getUnitDef } from "../data";
import type { BattleState, CampaignState, EndingDef, RosterEntry, Stats, StoryChoice, UnitInstance } from "../models/types";
import { createRosterEntry } from "./chapter";
import { baseClassId, isKnownClassId } from "./classes";
import { normalizeWeaponForge, normalizeWeaponUses } from "./equipment";

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
    roster: ["aldric", "valentin", "mirelle", "cecilia", "rowan", "seren"].map((unitId) => createRosterEntry(unitId)),
    fallen: [],
    gold: ECONOMY.startingGold,
    convoy: { iron_sword: 1, iron_lance: 1, short_bow: 1, fire: 1, heal_staff: 1 },
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

export function ensureChapterRoster(campaign: CampaignState, chapterId = campaign.currentChapterId): CampaignState {
  const chapter = getChapter(chapterId);
  const known = new Set(campaign.roster.map((entry) => entry.unitDefId));
  const recruits = chapter.deployments
    .filter((deployment) => deployment.team === "ally" && !known.has(deployment.unitDefId) && !campaign.fallen.includes(deployment.unitDefId))
    .map((deployment) => createRosterEntry(deployment.unitDefId, deployment.weaponId));
  if (recruits.length === 0) {
    return campaign;
  }
  return { ...campaign, roster: [...campaign.roster.map(cloneRosterEntry), ...recruits], savedAt: Date.now() };
}

export function mergeBattleIntoCampaign(campaign: CampaignState, state: BattleState): CampaignState {
  const roster = campaign.roster.map(cloneRosterEntry);
  const fallen = new Set(campaign.fallen);

  for (const unit of state.units) {
    if (unit.team !== "ally") {
      continue;
    }
    const unitDef = getUnitDef(unit.defId);
    if (campaign.mode === "classic" && !unit.alive && unitDef.defeatBehavior !== "retreat") {
      fallen.add(unit.defId);
      continue;
    }
    upsertRosterEntry(roster, unit);
  }

  return {
    ...campaign,
    roster,
    fallen: [...fallen],
    bonds: { ...campaign.bonds, ...state.bonds },
    taint: {
      ...campaign.taint,
      aldric: Number(state.flags["dragonTaint:aldric"] ?? campaign.taint.aldric ?? 0),
      elara: Number(state.flags["dragonTaint:elara"] ?? campaign.taint.elara ?? 0),
    },
    flags: { ...campaign.flags, ...persistentBattleFlags(state.flags) },
    seed: state.rngState,
    savedAt: Date.now(),
  };
}

export function chooseEnding(campaign: CampaignState): EndingDef {
  const endingChoice = campaign.flags.endingChoice;
  const totalTaint = Object.values(campaign.taint).reduce((sum, value) => sum + value, 0);
  if (totalTaint >= 6) {
    return endingCatalog.find((ending) => ending.id === "dragonfall") ?? endingCatalog[3]!;
  }
  if (endingChoice === 1 && !campaign.fallen.includes("aldric")) {
    return endingCatalog.find((ending) => ending.id === "sacrifice_aldric") ?? endingCatalog[0]!;
  }
  if (endingChoice === 2 && !campaign.fallen.includes("elara")) {
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
    roster: migrateRoster(raw.roster, fresh.roster),
    fallen: Array.isArray(raw.fallen) ? raw.fallen.filter((id): id is string => typeof id === "string") : [],
    gold: typeof raw.gold === "number" ? raw.gold : fresh.gold,
    convoy: isNumberRecord(raw.convoy) ? raw.convoy : fresh.convoy,
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

function migrateRoster(raw: unknown, fallback: RosterEntry[]): RosterEntry[] {
  if (!Array.isArray(raw)) {
    return fallback.map(cloneRosterEntry);
  }
  const roster: RosterEntry[] = [];
  for (const item of raw) {
    const entry = migrateRosterEntry(item);
    if (entry) {
      roster.push(entry);
    }
  }
  return roster.length > 0 ? roster : fallback.map(cloneRosterEntry);
}

function migrateRosterEntry(raw: unknown): RosterEntry | undefined {
  if (typeof raw === "string") {
    return safeRosterEntry(raw);
  }
  if (!isObject(raw) || typeof raw.unitDefId !== "string") {
    return undefined;
  }
  const base = safeRosterEntry(raw.unitDefId);
  if (!base) {
    return undefined;
  }
  const weaponIds = Array.isArray(raw.weaponIds) ? raw.weaponIds.filter((id): id is string => typeof id === "string") : base.weaponIds;
  const carriedWeaponIds = typeof raw.weaponId === "string" && !weaponIds.includes(raw.weaponId) ? [...weaponIds, raw.weaponId] : weaponIds;
  return {
    unitDefId: base.unitDefId,
    classId: typeof raw.classId === "string" && isKnownClassId(raw.classId) ? raw.classId : base.classId,
    level: typeof raw.level === "number" ? raw.level : base.level,
    exp: typeof raw.exp === "number" ? raw.exp : base.exp,
    stats: isStats(raw.stats) ? raw.stats : base.stats,
    weaponId: typeof raw.weaponId === "string" ? raw.weaponId : base.weaponId,
    weaponIds: carriedWeaponIds,
    weaponUses: normalizeWeaponUses(carriedWeaponIds, isNumberRecord(raw.weaponUses) ? raw.weaponUses : base.weaponUses),
    weaponForge: normalizeWeaponForge(carriedWeaponIds, isNumberRecord(raw.weaponForge) ? raw.weaponForge : base.weaponForge),
    skillIds: Array.isArray(raw.skillIds) ? raw.skillIds.filter((id): id is string => typeof id === "string") : base.skillIds,
    deployed: typeof raw.deployed === "boolean" ? raw.deployed : base.deployed,
  };
}

function safeRosterEntry(unitDefId: string): RosterEntry | undefined {
  try {
    return createRosterEntry(unitDefId);
  } catch {
    return undefined;
  }
}

function upsertRosterEntry(roster: RosterEntry[], unit: UnitInstance): void {
  const previous = roster.find((entry) => entry.unitDefId === unit.defId);
  const previousWeaponIds = previous?.weaponIds ?? Object.keys(unit.weaponUses);
  const weaponIds = previousWeaponIds.includes(unit.weaponId) ? previousWeaponIds : [...previousWeaponIds, unit.weaponId];
  const next = {
    unitDefId: unit.defId,
    classId: isKnownClassId(unit.classId) ? unit.classId : previous?.classId ?? baseClassId(unit.defId),
    level: unit.level,
    exp: unit.exp,
    stats: { ...unit.stats },
    weaponId: unit.weaponId,
    weaponIds: [...weaponIds],
    weaponUses: normalizeWeaponUses(weaponIds, unit.weaponUses),
    weaponForge: normalizeWeaponForge(weaponIds, unit.weaponForge),
    skillIds: [...unit.skillIds],
    deployed: previous?.deployed ?? true,
  };
  const index = roster.findIndex((entry) => entry.unitDefId === unit.defId);
  if (index === -1) {
    roster.push(next);
  } else {
    roster[index] = next;
  }
}

function persistentBattleFlags(flags: BattleState["flags"]): BattleState["flags"] {
  return Object.fromEntries(Object.entries(flags).filter(([key]) => !key.startsWith("chapterEvent:")));
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

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isStats(value: unknown): value is Stats {
  if (!isObject(value)) {
    return false;
  }
  return ["hp", "str", "mag", "skill", "spd", "luck", "def", "res", "move", "con"].every((key) => typeof value[key] === "number");
}

function isNumberRecord(value: unknown): value is Record<string, number> {
  if (!isObject(value)) {
    return false;
  }
  return Object.values(value).every((count) => typeof count === "number");
}
