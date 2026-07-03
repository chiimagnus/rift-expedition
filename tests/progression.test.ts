import assert from "node:assert/strict";
import test from "node:test";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { gainExperience, nextExpForLevel } from "../src/services/progression";
import { createRng } from "../src/services/rng";

test("experience can level a unit with deterministic stat growth", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  const beforeTotal = Object.values(aldric.stats).reduce((sum, value) => sum + value, 0);
  const rng = createRng(state.rngState);

  const logs = gainExperience(state, rng, aldric, nextExpForLevel(aldric.level));

  assert.equal(aldric.level, 2);
  assert.ok(Object.values(aldric.stats).reduce((sum, value) => sum + value, 0) > beforeTotal);
  assert.equal(logs.length, 1);
});
