import assert from "node:assert/strict";
import test from "node:test";
import { getWeapon } from "../src/data";
import { createNewCampaign } from "../src/services/campaign";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { promoteRosterUnit, promotionTargets } from "../src/services/classes";
import { assignConvoyWeapon } from "../src/services/loadout";
import { movementCost } from "../src/services/movement";

test("promotion unlocks target class, class skill, and capped stat bump", () => {
  let campaign = createNewCampaign();
  campaign = {
    ...campaign,
    roster: campaign.roster.map((entry) =>
      entry.unitDefId === "cecilia"
        ? {
            ...entry,
            level: 10,
            stats: { ...entry.stats, hp: 58, str: 30, mag: 29, skill: 29, spd: 29, def: 29, res: 29 },
          }
        : entry,
    ),
  };
  const cecilia = campaign.roster.find((entry) => entry.unitDefId === "cecilia")!;
  assert.deepEqual(promotionTargets(cecilia), ["swordmaster", "hero"]);

  campaign = promoteRosterUnit(campaign, "cecilia", "swordmaster");
  const promoted = campaign.roster.find((entry) => entry.unitDefId === "cecilia")!;

  assert.equal(promoted.classId, "swordmaster");
  assert.equal(promoted.stats.hp, 60);
  assert.equal(promoted.stats.str, 30);
  assert.equal(promoted.stats.mag, 30);
  assert.equal(promoted.stats.move, cecilia.stats.move + 1);
  assert.ok(promoted.skillIds.includes("iaijutsu"));
});

test("promotion persists into battle and changes terrain movement rules", () => {
  let campaign = createNewCampaign();
  campaign = { ...campaign, roster: campaign.roster.map((entry) => (entry.unitDefId === "aldric" ? { ...entry, level: 10 } : entry)) };
  campaign = promoteRosterUnit(campaign, "aldric", "dragon_king");

  const state = createInitialBattleState("ch01", campaign);
  state.grid = [["forest"]];
  const aldric = findUnit(state, "aldric");

  assert.equal(aldric.classId, "dragon_king");
  assert.equal(movementCost(state, aldric, { x: 0, y: 0 }), 2);
});

test("promotion updates convoy weapon permissions for the promoted class", () => {
  let campaign = createNewCampaign();
  campaign = { ...campaign, roster: campaign.roster.map((entry) => (entry.unitDefId === "seren" ? { ...entry, level: 10 } : entry)) };

  assert.throws(() => assignConvoyWeapon(campaign, "seren", "fire"), /无法装备/);
  campaign = promoteRosterUnit(campaign, "seren", "bishop");
  campaign = assignConvoyWeapon(campaign, "seren", "fire");
  const seren = campaign.roster.find((entry) => entry.unitDefId === "seren")!;

  assert.equal(seren.weaponId, "fire");
  assert.equal(seren.weaponUses.fire, getWeapon("fire").durability);
  assert.ok(seren.skillIds.includes("resurrection"));
});
