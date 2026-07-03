import assert from "node:assert/strict";
import test from "node:test";
import { getChapter } from "../src/data";
import {
  applyStoryChoice,
  chooseEnding,
  completeCurrentChapter,
  createNewCampaign,
  ensureChapterRoster,
  loadCampaign,
  mergeBattleIntoCampaign,
  saveCampaign,
  type StorageLike,
} from "../src/services/campaign";
import { createInitialBattleState, findUnit } from "../src/services/chapter";

class MemoryStorage implements StorageLike {
  private readonly values = new Map<string, string>();

  getItem(key: string): string | null {
    return this.values.get(key) ?? null;
  }

  setItem(key: string, value: string): void {
    this.values.set(key, value);
  }

  removeItem(key: string): void {
    this.values.delete(key);
  }
}

test("campaign completion advances through chapters", () => {
  let campaign = createNewCampaign();
  assert.equal(campaign.currentChapterId, "ch01");
  campaign = completeCurrentChapter(campaign);
  assert.equal(campaign.currentChapterId, "ch02");
  assert.deepEqual(campaign.completedChapterIds, ["ch01"]);
});

test("story choices write reactive flags", () => {
  const campaign = createNewCampaign();
  const choice = getChapter("ch13").choice!;
  const updated = applyStoryChoice(campaign, choice, 2);
  assert.equal(updated.flags.allegiance, 3);
});

test("save and load round-trip current campaign state", () => {
  const storage = new MemoryStorage();
  const campaign = { ...createNewCampaign("casual"), currentChapterId: "ch09", flags: { allegiance: 2 } };
  saveCampaign(storage, campaign);
  const loaded = loadCampaign(storage);
  assert.equal(loaded.mode, "casual");
  assert.equal(loaded.currentChapterId, "ch09");
  assert.equal(loaded.flags.allegiance, 2);
  assert.equal(loaded.roster[0]!.unitDefId, "aldric");
  assert.equal(loaded.gold, campaign.gold);
  assert.ok(loaded.convoy.iron_sword);
});

test("chapter roster recruits controllable perspective allies before deployment", () => {
  const campaign = createNewCampaign();
  const updated = ensureChapterRoster(campaign, "ch04");

  assert.ok(updated.roster.some((entry) => entry.unitDefId === "elara"));
  assert.ok(updated.roster.some((entry) => entry.unitDefId === "sigrun"));
});

test("campaign merge persists roster growth and classic fallen units", () => {
  const campaign = createNewCampaign("classic");
  const state = createInitialBattleState("ch01", campaign);
  const rowan = findUnit(state, "rowan");
  const aldric = findUnit(state, "aldric");
  rowan.alive = false;
  rowan.hp = 0;
  aldric.level = 2;
  aldric.exp = 7;
  aldric.stats.str += 1;
  aldric.weaponUses[aldric.weaponId] = aldric.weaponUses[aldric.weaponId]! - 2;
  aldric.weaponForge[aldric.weaponId] = 1;

  const merged = mergeBattleIntoCampaign(campaign, state);
  const nextState = createInitialBattleState("ch02", merged);
  const mergedAldric = merged.roster.find((entry) => entry.unitDefId === "aldric")!;

  assert.ok(merged.fallen.includes("rowan"));
  assert.equal(mergedAldric.level, 2);
  assert.equal(mergedAldric.stats.str, aldric.stats.str);
  assert.equal(mergedAldric.weaponUses[aldric.weaponId], aldric.weaponUses[aldric.weaponId]);
  assert.equal(mergedAldric.weaponForge[aldric.weaponId], 1);
  assert.equal(nextState.units.some((unit) => unit.defId === "rowan" && unit.team === "ally"), false);
});

test("ending selection follows B/11 ending tree", () => {
  assert.equal(chooseEnding({ ...createNewCampaign(), flags: { endingChoice: 1 } }).id, "sacrifice_aldric");
  assert.equal(chooseEnding({ ...createNewCampaign(), flags: { endingChoice: 2 } }).id, "sacrifice_elara");
  assert.equal(chooseEnding({ ...createNewCampaign(), flags: { endingChoice: 3 }, bonds: { "aldric:elara": 180 } }).id, "defy_god");
  assert.equal(chooseEnding({ ...createNewCampaign(), taint: { aldric: 3, elara: 3 } }).id, "dragonfall");
});
