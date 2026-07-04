import assert from "node:assert/strict";
import test from "node:test";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { refreshRound } from "../src/services/skills";

test("terrain round effects heal forts and thrones", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  aldric.hp = 10;
  state.grid[aldric.pos.y]![aldric.pos.x] = "fort";

  refreshRound(state);

  assert.equal(aldric.hp, 12);
  assert.ok(state.log[0]!.includes("恢复 2 点"));

  const bjorn = findUnit(state, "bjorn");
  bjorn.hp = 10;
  state.grid[bjorn.pos.y]![bjorn.pos.x] = "throne";

  refreshRound(state);

  assert.equal(bjorn.hp, 12);
});

test("poison bog damages units and can defeat them", () => {
  const state = createInitialBattleState();
  const rowan = findUnit(state, "rowan");
  rowan.hp = 2;
  state.grid[rowan.pos.y]![rowan.pos.x] = "poison_bog";

  refreshRound(state);

  assert.equal(rowan.hp, 0);
  assert.equal(rowan.alive, false);
  assert.ok(state.log.some((line) => line.includes("毒沼")));
});
