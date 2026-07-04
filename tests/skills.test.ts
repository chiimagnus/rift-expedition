import assert from "node:assert/strict";
import test from "node:test";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { forecastCombat, resolveCombat } from "../src/services/combat";
import { activateSkill, refreshRound } from "../src/services/skills";

test("healing wave restores allied HP and spends action", () => {
  const state = createInitialBattleState();
  const seren = findUnit(state, "seren");
  const aldric = findUnit(state, "aldric");
  seren.pos = { x: 2, y: 8 };
  aldric.pos = { x: 3, y: 8 };
  aldric.hp = 10;

  const result = activateSkill(state, "seren", "healing_wave", "aldric");

  assert.equal(result.ok, true);
  assert.equal(aldric.hp, 27);
  assert.equal(seren.acted, true);
  assert.ok(seren.exp > 0);
  assert.equal(state.bonds["aldric:seren"], 5);
});

test("stigma awakening raises forecast damage and adds dragon taint", () => {
  const state = createInitialBattleState();
  findUnit(state, "aldric").pos = { x: 9, y: 3 };
  const before = forecastCombat(state, "aldric", "bjorn").damage;

  const result = activateSkill(state, "aldric", "stigma_awaken", "aldric");
  findUnit(state, "aldric").acted = false;
  const after = forecastCombat(state, "aldric", "bjorn").damage;

  assert.equal(result.ok, true);
  assert.equal(state.flags["dragonTaint:aldric"], 1);
  assert.ok(after > before);
});

test("aegis halves incoming damage", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  aldric.skillIds.push("aegis");
  aldric.pos = { x: 9, y: 3 };
  bjorn.pos = { x: 10, y: 3 };

  const normal = forecastCombat(state, "bjorn", "aldric").damage;
  const result = activateSkill(state, "aldric", "aegis", "aldric");
  aldric.acted = false;
  resolveCombat(state, "bjorn", "aldric");

  assert.equal(result.ok, true);
  assert.ok(aldric.hp > aldric.stats.hp - normal);
});

test("combat passive skills alter forecast and resolution", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains", "forest"]];
  const rowan = findUnit(state, "rowan");
  const bjorn = findUnit(state, "bjorn");
  rowan.pos = { x: 0, y: 0 };
  bjorn.pos = { x: 3, y: 0 };

  const blockedByTerrain = forecastCombat(state, "rowan", "bjorn").hit;
  rowan.skillIds.push("cloud_piercer");
  assert.ok(forecastCombat(state, "rowan", "bjorn").hit > blockedByTerrain);
  rowan.skillIds.push("quickdraw");
  rowan.stats.spd = bjorn.stats.spd + 3;
  assert.equal(forecastCombat(state, "rowan", "bjorn").followUp, true);
  assert.doesNotThrow(() => resolveCombat(state, "rowan", "bjorn"));
});

test("damage, crit, and accuracy passives share forecast math", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains"]];
  const cecilia = findUnit(state, "cecilia");
  const valentin = findUnit(state, "valentin");
  cecilia.pos = { x: 0, y: 0 };
  valentin.pos = { x: 1, y: 0 };
  cecilia.weaponId = "iron_axe";
  cecilia.weaponUses.iron_axe = 35;
  cecilia.weaponForge.iron_axe = 0;
  cecilia.stats.skill = 20;
  valentin.stats.spd = 31;
  valentin.stats.luck = 10;

  const normalDamage = forecastCombat(state, "cecilia", "valentin").damage;
  cecilia.skillIds.push("armor_break", "iaijutsu");
  const lowHit = forecastCombat(state, "cecilia", "valentin").hit;
  cecilia.skillIds.push("steady_hand");
  const skilled = forecastCombat(state, "cecilia", "valentin");
  assert.ok(skilled.damage > normalDamage);
  assert.ok(skilled.crit > 0);
  assert.ok(lowHit < 60);
  assert.equal(skilled.hit, 60);

  valentin.skillIds.push("calm");
  assert.equal(forecastCombat(state, "cecilia", "valentin").crit, 0);
});

test("foresight spends its once-per-battle dodge and poison blade applies status", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains"]];
  const cecilia = findUnit(state, "cecilia");
  const bjorn = findUnit(state, "bjorn");
  cecilia.pos = { x: 0, y: 0 };
  bjorn.pos = { x: 1, y: 0 };
  cecilia.skillIds.push("foresight");
  cecilia.stats.spd = 20;
  cecilia.weaponUses[cecilia.weaponId] = 0;
  bjorn.stats.spd = 5;

  const beforeHp = cecilia.hp;
  assert.equal(forecastCombat(state, "bjorn", "cecilia").hit, 0);
  resolveCombat(state, "bjorn", "cecilia");
  assert.equal(cecilia.hp, beforeHp);
  assert.equal(cecilia.skillUses.foresight, 1);

  bjorn.skillIds.push("poison_blade", "steady_hand");
  cecilia.statuses = [];
  cecilia.stats.spd = 0;
  cecilia.stats.luck = 0;
  resolveCombat(state, "bjorn", "cecilia");
  assert.ok(cecilia.statuses.some((status) => status.id === "poison"));
});

test("round refresh accrues adjacent bonds and ticks statuses", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  const cecilia = findUnit(state, "cecilia");
  aldric.statuses.push({ id: "sprint", turns: 1 });
  aldric.pos = { x: 1, y: 1 };
  cecilia.pos = { x: 1, y: 2 };

  refreshRound(state);

  assert.equal(aldric.statuses.length, 0);
  assert.equal(state.bonds["aldric:cecilia"], 3);
});
