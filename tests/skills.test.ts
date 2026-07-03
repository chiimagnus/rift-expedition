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
