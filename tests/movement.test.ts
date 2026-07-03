import assert from "node:assert/strict";
import test from "node:test";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { movementCost, reachableCells } from "../src/services/movement";

test("terrain movement follows A/06 costs", () => {
  const state = createInitialBattleState();
  const valentin = findUnit(state, "valentin");
  const elara = findUnit(state, "elara");

  state.grid = [["forest", "mountain", "river"]];

  assert.equal(movementCost(state, valentin, { x: 0, y: 0 }), 2);
  assert.equal(movementCost(state, valentin, { x: 1, y: 0 }), 3);
  assert.equal(movementCost(state, valentin, { x: 2, y: 0 }), null);
  assert.equal(movementCost(state, elara, { x: 2, y: 0 }), 1);
});

test("reachable cells block occupied enemies and impassable terrain", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  state.grid = [
    ["plains", "river", "plains"],
    ["plains", "plains", "plains"],
    ["plains", "plains", "plains"],
  ];
  state.units = [
    { ...aldric, pos: { x: 0, y: 0 }, stats: { ...aldric.stats, move: 3 } },
    { ...findUnit(createInitialBattleState(), "bjorn"), pos: { x: 2, y: 2 } },
  ];

  const reachable = reachableCells(state, state.units[0]!);
  assert.equal(reachable.has("1,0"), false);
  assert.equal(reachable.has("2,2"), false);
  assert.equal(reachable.has("2,1"), true);
});
