import assert from "node:assert/strict";
import test from "node:test";
import { getWeapon } from "../src/data";
import { createNewCampaign } from "../src/services/campaign";
import { createInitialBattleState } from "../src/services/chapter";
import { forecastCombat } from "../src/services/combat";
import { forgeWeaponCost, repairWeaponCost } from "../src/services/equipment";
import { assignConvoyWeapon, buyWeapon, cycleRosterWeapon, forgeRosterWeapon, repairRosterWeapon, setRosterDeployment } from "../src/services/loadout";

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
  assert.equal(aldric.weaponUses.horseslayer, getWeapon("horseslayer").durability);
  assert.equal(aldric.weaponForge.horseslayer, 0);
});

test("loadout can repair and forge carried weapons", () => {
  let campaign = createNewCampaign();
  campaign = {
    ...campaign,
    gold: 5000,
    roster: campaign.roster.map((entry) =>
      entry.unitDefId === "aldric"
        ? { ...entry, weaponUses: { ...entry.weaponUses, [entry.weaponId]: entry.weaponUses[entry.weaponId]! - 3 } }
        : entry,
    ),
  };
  const damaged = campaign.roster.find((entry) => entry.unitDefId === "aldric")!;
  const repairCost = repairWeaponCost(damaged);

  campaign = repairRosterWeapon(campaign, "aldric");
  const repaired = campaign.roster.find((entry) => entry.unitDefId === "aldric")!;
  assert.equal(campaign.gold, 5000 - repairCost);
  assert.equal(repaired.weaponUses[repaired.weaponId], getWeapon(repaired.weaponId).durability);

  const forgeCost = forgeWeaponCost(repaired);
  campaign = forgeRosterWeapon(campaign, "aldric");
  const forged = campaign.roster.find((entry) => entry.unitDefId === "aldric")!;
  assert.equal(campaign.gold, 5000 - repairCost - forgeCost);
  assert.equal(forged.weaponForge[forged.weaponId], 1);

  const baseState = createInitialBattleState("ch01", createNewCampaign());
  const forgedState = createInitialBattleState("ch01", campaign);
  baseState.units.find((unit) => unit.id === "aldric")!.pos = { x: 9, y: 3 };
  forgedState.units.find((unit) => unit.id === "aldric")!.pos = { x: 9, y: 3 };
  assert.equal(forecastCombat(forgedState, "aldric", "bjorn").damage, forecastCombat(baseState, "aldric", "bjorn").damage + 1);
});
