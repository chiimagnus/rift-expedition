import assert from "node:assert/strict";
import test from "node:test";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { cellKey } from "../src/services/movement";
import { BattleViewModel } from "../src/viewmodels/BattleViewModel";

test("clicking a highlighted enemy moves into range before attacking", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains"]];
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  state.units = [aldric, bjorn];
  aldric.team = "ally";
  aldric.pos = { x: 0, y: 0 };
  aldric.stats.skill = 100;
  bjorn.team = "enemy";
  bjorn.pos = { x: 2, y: 0 };
  const beforeHp = bjorn.hp;
  const vm = new BattleViewModel(state);
  vm.selectedUnitId = "aldric";

  assert.equal(vm.selectedAttackable.has(cellKey(bjorn.pos)), true);
  vm.selectCell(bjorn.pos);

  assert.deepEqual(aldric.pos, { x: 1, y: 0 });
  assert.ok(bjorn.hp < beforeHp);
  assert.equal(aldric.acted, true);
});

test("paladin canto keeps only remaining movement after attacking", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains", "plains", "plains", "plains"]];
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  const raider = findUnit(state, "raider_a");
  state.units = [aldric, bjorn, raider];
  aldric.team = "ally";
  aldric.classId = "paladin";
  aldric.skillIds.push("paladin_canto");
  aldric.pos = { x: 0, y: 0 };
  aldric.stats.move = 4;
  aldric.stats.str = 50;
  aldric.stats.skill = 100;
  bjorn.team = "enemy";
  bjorn.pos = { x: 2, y: 0 };
  bjorn.hp = 1;
  raider.team = "enemy";
  raider.pos = { x: 5, y: 0 };
  const vm = new BattleViewModel(state);
  vm.selectedUnitId = "aldric";

  vm.selectCell(bjorn.pos);

  assert.equal(vm.selectedUnitId, "aldric");
  assert.equal(aldric.acted, true);
  assert.equal(aldric.cantoMoveLeft, 3);
  assert.equal(vm.selectedAttackable.size, 0);
  assert.equal(vm.selectedReachable.has("4,0"), true);

  vm.selectCell({ x: 4, y: 0 });

  assert.deepEqual(aldric.pos, { x: 4, y: 0 });
  assert.equal(aldric.cantoMoveLeft, 0);
  assert.equal(vm.selectedUnitId, undefined);
});
