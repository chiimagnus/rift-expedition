import assert from "node:assert/strict";
import test from "node:test";
import { chapterCatalog, classCatalog, skillCatalog, terrainCatalog, unitCatalog } from "../src/data";
import { createInitialBattleState } from "../src/services/chapter";

test("content baseline covers documented M0/M1 surfaces", () => {
  assert.equal(terrainCatalog.length, 18);
  assert.equal(skillCatalog.length, 26);
  assert.ok(classCatalog.length >= 10);
  assert.ok(unitCatalog.length >= 12);
});

test("chapter 01 is a 14x10 playable tactical map with both teams", () => {
  const chapter = chapterCatalog[0]!;
  assert.equal(chapter.map.length, 10);
  assert.equal(chapter.map.every((row) => row.length === 14), true);

  const state = createInitialBattleState(chapter.id);
  assert.equal(state.grid.length, 10);
  assert.equal(state.grid[0]!.length, 14);
  assert.equal(state.units.filter((unit) => unit.team === "ally").length, 6);
  assert.equal(state.units.filter((unit) => unit.team === "enemy").length, 6);
});
