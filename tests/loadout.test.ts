import assert from "node:assert/strict";
import test from "node:test";
import { getWeapon } from "../src/data";
import { createNewCampaign } from "../src/services/campaign";
import { createInitialBattleState } from "../src/services/chapter";
import { assignConvoyWeapon, buyWeapon, cycleRosterWeapon, setRosterDeployment } from "../src/services/loadout";

test("deployment phase can bench a unit without deleting roster progress", () => {
  const campaign = setRosterDeployment(createNewCampaign(), "rowan", false, ["aldric", "valentin", "mirelle", "cecilia", "rowan", "seren"]);
  const state = createInitialBattleState("ch01", campaign);

  assert.equal(state.phase, "deploy");
  assert.equal(campaign.roster.find((entry) => entry.unitDefId === "rowan")!.deployed, false);
  assert.equal(state.units.some((unit) => unit.defId === "rowan" && unit.team === "ally"), false);
});

test("deployment guard keeps at least one unit in the current chapter", () => {
  let campaign = createNewCampaign();
  const ids = ["aldric", "valentin", "mirelle", "cecilia", "rowan", "seren"];
  for (const unitId of ids.slice(1)) {
    campaign = setRosterDeployment(campaign, unitId, false, ids);
  }

  assert.throws(() => setRosterDeployment(campaign, "aldric", false, ids), /至少需要一名/);
});

test("loadout can cycle carried weapons and move usable weapons from convoy", () => {
  let campaign = createNewCampaign();
  campaign = cycleRosterWeapon(campaign, "aldric");
  assert.equal(campaign.roster.find((entry) => entry.unitDefId === "aldric")!.weaponId, "iron_sword");

  const beforeGold = campaign.gold;
  campaign = buyWeapon(campaign, "horseslayer");
  campaign = assignConvoyWeapon(campaign, "aldric", "horseslayer");
  const aldric = campaign.roster.find((entry) => entry.unitDefId === "aldric")!;

  assert.equal(campaign.gold, beforeGold - getWeapon("horseslayer").cost);
  assert.equal(campaign.convoy.horseslayer, 0);
  assert.equal(aldric.weaponId, "horseslayer");
  assert.ok(aldric.weaponIds.includes("horseslayer"));
});
