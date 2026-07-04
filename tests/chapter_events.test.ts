import assert from "node:assert/strict";
import test from "node:test";
import { runEnemyTurn } from "../src/services/ai";
import { processChapterEvents } from "../src/services/chapterEvents";
import { createInitialBattleState, findUnit, updateOutcome } from "../src/services/chapter";

test("reinforcement events are telegraphed and block premature rout victory", () => {
  const state = createInitialBattleState("ch03");
  assert.ok(state.log.some((line) => line.includes("北境援军下回合")));

  for (const enemy of state.units.filter((unit) => unit.team === "enemy")) {
    enemy.alive = false;
  }
  updateOutcome(state);
  assert.equal(state.phase, "player");

  state.turn = 2;
  const spawned = processChapterEvents(state, "enemyStart");

  assert.equal(spawned.length, 2);
  assert.ok(state.units.some((unit) => unit.id === "ch03_wave_raider" && unit.alive));
});

test("watchful prevents ambush reinforcements from acting on arrival", () => {
  const state = createInitialBattleState("ch12");
  const aldric = findUnit(state, "aldric");
  aldric.skillIds.push("watchful");
  aldric.pos = { x: 12, y: 1 };
  for (const enemy of state.units.filter((unit) => unit.team === "enemy")) {
    enemy.alive = false;
  }
  state.turn = 2;
  const beforeHp = aldric.hp;

  runEnemyTurn(state);

  assert.equal(aldric.hp, beforeHp);
  assert.ok(state.units.some((unit) => unit.id === "ch12_zealot_wave"));
  assert.ok(state.log.some((line) => line.includes("警戒识破伏击")));
});
