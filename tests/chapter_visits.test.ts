import assert from "node:assert/strict";
import test from "node:test";
import { createNewCampaign, mergeBattleIntoCampaign } from "../src/services/campaign";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { visitChapterSite } from "../src/services/chapterVisits";
import { BattleViewModel } from "../src/viewmodels/BattleViewModel";

test("village visits spend the unit action and stage campaign rewards", () => {
  const state = createInitialBattleState("ch02");
  const aldric = findUnit(state, "aldric");
  aldric.pos = { x: 2, y: 2 };
  const vm = new BattleViewModel(state);
  vm.selectedUnitId = "aldric";

  assert.equal(vm.canVisitSelected(), true);
  vm.visitSelected();

  assert.equal(aldric.acted, true);
  assert.equal(state.flags.savedRefugeeCellar, true);
  assert.equal(state.flags["battleReward:gold"], 300);
  assert.equal(vm.canVisitSelected(), false);
  assert.equal(visitChapterSite(state, "aldric").ok, false);
});

test("visit rewards merge into campaign economy without runtime flags", () => {
  const campaign = createNewCampaign();
  const state = createInitialBattleState("ch01", campaign);
  state.phase = "player";
  const aldric = findUnit(state, "aldric");
  aldric.pos = { x: 3, y: 4 };
  const beforeStaffs = campaign.convoy.heal_staff ?? 0;

  const result = visitChapterSite(state, "aldric");
  const merged = mergeBattleIntoCampaign(campaign, state);

  assert.equal(result.ok, true);
  assert.equal(merged.convoy.heal_staff, beforeStaffs + 1);
  assert.equal(merged.flags.visitedBorderHamlet, true);
  assert.equal(merged.flags["battleReward:item:heal_staff"], undefined);
  assert.equal(merged.flags["chapterVisit:ch01:border_hamlet"], undefined);
});
