import assert from "node:assert/strict";
import test from "node:test";
import { chapterCatalog, classCatalog, endingCatalog, skillCatalog, terrainCatalog, unitCatalog } from "../src/data";
import { createInitialBattleState } from "../src/services/chapter";

test("content baseline covers documented M0/M1 surfaces", () => {
  assert.equal(terrainCatalog.length, 18);
  assert.equal(skillCatalog.length, 26);
  assert.ok(classCatalog.length >= 10);
  assert.ok(unitCatalog.length >= 12);
  assert.equal(chapterCatalog.length, 24);
  assert.equal(endingCatalog.length, 4);
});

test("all 24 chapters have a 14x10 playable tactical map with both teams", () => {
  for (const chapter of chapterCatalog) {
    assert.equal(chapter.map.length, 10, chapter.id);
    assert.equal(chapter.map.every((row) => row.length === 14), true, chapter.id);

    const state = createInitialBattleState(chapter.id);
    assert.equal(state.grid.length, 10, chapter.id);
    assert.equal(state.grid[0]!.length, 14, chapter.id);
    assert.ok(state.units.some((unit) => unit.team === "ally"), chapter.id);
    assert.ok(state.units.some((unit) => unit.team === "enemy"), chapter.id);
  }
});

test("chapter chain runs from ch01 to ch24 without gaps", () => {
  const ids = new Set(chapterCatalog.map((chapter) => chapter.id));
  for (let i = 1; i <= 24; i += 1) {
    assert.ok(ids.has(`ch${String(i).padStart(2, "0")}`));
  }
  for (const chapter of chapterCatalog.slice(0, -1)) {
    assert.ok(chapter.nextChapterId, chapter.id);
    assert.ok(ids.has(chapter.nextChapterId!), chapter.id);
  }
  assert.equal(chapterCatalog.at(-1)!.nextChapterId, undefined);
});
