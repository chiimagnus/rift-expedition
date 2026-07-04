import assert from "node:assert/strict";
import test from "node:test";
import { chapterCatalog } from "../src/data";
import type { ChapterDefeatCondition, ChapterVictoryCondition } from "../src/models/types";
import { processChapterEvents } from "../src/services/chapterEvents";
import { createInitialBattleState, findUnit, updateOutcome } from "../src/services/chapter";

test("chapter objectives are structured and reference deployed units", () => {
  for (const chapter of chapterCatalog) {
    assert.ok(chapter.victoryCondition, `${chapter.id}:victoryCondition`);
    validateVictoryCondition(chapter.id, chapter.victoryCondition!, deploymentIds(chapter), allyDefIds(chapter));
    for (const condition of chapter.defeatConditions ?? []) {
      validateDefeatCondition(chapter.id, condition, deploymentIds(chapter), allyDefIds(chapter));
    }
  }
});

test("joined story chapters deploy both twins for dual-protagonist objectives", () => {
  for (const chapterId of ["ch07", "ch09", "ch12", "ch18", "ch23"]) {
    const state = createInitialBattleState(chapterId);
    assert.ok(state.units.some((unit) => unit.defId === "aldric" && unit.team === "ally"), chapterId);
    assert.ok(state.units.some((unit) => unit.defId === "elara" && unit.team === "ally"), chapterId);
  }
});

test("seize and escape objectives resolve when required units reach the goal cell", () => {
  const seize = createInitialBattleState("ch08");
  findUnit(seize, "aldric").pos = { x: 6, y: 4 };
  updateOutcome(seize);
  assert.equal(seize.phase, "victory");

  const escape = createInitialBattleState("ch07");
  findUnit(escape, "aldric").pos = { x: 7, y: 4 };
  findUnit(escape, "elara").pos = { x: 7, y: 4 };
  updateOutcome(escape);
  assert.equal(escape.phase, "victory");
});

test("survive and compound objectives honor the required turn count", () => {
  const survive = createInitialBattleState("ch15");
  survive.turn = 3;
  updateOutcome(survive);
  assert.equal(survive.phase, "player");
  survive.turn = 4;
  updateOutcome(survive);
  assert.equal(survive.phase, "victory");

  const bridge = createInitialBattleState("ch03");
  bridge.turn = 2;
  processChapterEvents(bridge, "enemyStart");
  for (const enemy of bridge.units.filter((unit) => unit.team === "enemy")) {
    enemy.alive = false;
  }
  bridge.turn = 3;
  updateOutcome(bridge);
  assert.equal(bridge.phase, "player");
  bridge.turn = 4;
  updateOutcome(bridge);
  assert.equal(bridge.phase, "victory");
});

test("protect and boss objectives resolve defeat and victory", () => {
  const protectedState = createInitialBattleState("ch06");
  findUnit(protectedState, "valentin").alive = false;
  updateOutcome(protectedState);
  assert.equal(protectedState.phase, "defeat");

  const bossState = createInitialBattleState("ch14");
  findUnit(bossState, "cecilia_boss").alive = false;
  updateOutcome(bossState);
  assert.equal(bossState.phase, "victory");
});

function validateVictoryCondition(chapterId: string, condition: ChapterVictoryCondition, instanceIds: Set<string>, allies: Set<string>): void {
  if (condition.type === "defeatBoss") {
    for (const target of condition.targetInstanceIds) {
      assert.ok(instanceIds.has(target), `${chapterId}:boss:${target}`);
    }
  } else if (condition.type === "seize" || condition.type === "escape") {
    assert.ok(condition.x >= 0 && condition.x < 14, `${chapterId}:objective:x`);
    assert.ok(condition.y >= 0 && condition.y < 10, `${chapterId}:objective:y`);
    for (const unitDefId of condition.unitDefIds ?? []) {
      assert.ok(allies.has(unitDefId), `${chapterId}:objective:${unitDefId}`);
    }
  } else if (condition.type === "survive") {
    assert.ok(condition.turns > 0, `${chapterId}:survive`);
  } else if (condition.type === "all" || condition.type === "any") {
    assert.ok(condition.conditions.length > 0, `${chapterId}:compound`);
    for (const nested of condition.conditions) {
      validateVictoryCondition(chapterId, nested, instanceIds, allies);
    }
  }
}

function validateDefeatCondition(chapterId: string, condition: ChapterDefeatCondition, instanceIds: Set<string>, allies: Set<string>): void {
  for (const instanceId of condition.instanceIds ?? []) {
    assert.ok(instanceIds.has(instanceId), `${chapterId}:protect:${instanceId}`);
  }
  for (const unitDefId of condition.unitDefIds ?? []) {
    assert.ok(allies.has(unitDefId), `${chapterId}:protect:${unitDefId}`);
  }
}

function deploymentIds(chapter: (typeof chapterCatalog)[number]): Set<string> {
  return new Set(chapter.deployments.map((deployment) => deployment.instanceId));
}

function allyDefIds(chapter: (typeof chapterCatalog)[number]): Set<string> {
  return new Set(chapter.deployments.filter((deployment) => deployment.team === "ally").map((deployment) => deployment.unitDefId));
}
