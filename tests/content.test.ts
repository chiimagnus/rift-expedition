import assert from "node:assert/strict";
import test from "node:test";
import { chapterCatalog, classCatalog, endingCatalog, skillCatalog, supportPairCatalog, terrainCatalog, unitCatalog, weaponCatalog } from "../src/data";
import { createInitialBattleState } from "../src/services/chapter";

test("content baseline covers documented M0/M1 surfaces", () => {
  assert.equal(terrainCatalog.length, 18);
  assert.equal(skillCatalog.length, 70);
  assert.equal(classCatalog.length, 35);
  assert.equal(unitCatalog.length, 35);
  assert.equal(chapterCatalog.length, 24);
  assert.equal(endingCatalog.length, 4);
});

test("content ids are unique across each catalog", () => {
  for (const catalog of [terrainCatalog, weaponCatalog, skillCatalog, classCatalog, unitCatalog, chapterCatalog, endingCatalog, supportPairCatalog]) {
    const ids = catalog.map((entry) => entry.id);
    assert.equal(new Set(ids).size, ids.length);
  }
});

test("content references resolve across units, classes, skills, supports, and chapters", () => {
  const classIds = new Set(classCatalog.map((item) => item.id));
  const weaponIds = new Set(weaponCatalog.map((item) => item.id));
  const skillIds = new Set(skillCatalog.map((item) => item.id));
  const unitIds = new Set(unitCatalog.map((item) => item.id));

  for (const classDef of classCatalog) {
    for (const promoted of classDef.promotesTo ?? []) {
      assert.ok(classIds.has(promoted), `${classDef.id} -> ${promoted}`);
    }
    for (const skillId of classDef.skillIds ?? []) {
      assert.ok(skillIds.has(skillId), `${classDef.id}:${skillId}`);
    }
  }

  for (const unit of unitCatalog) {
    assert.ok(classIds.has(unit.classId), unit.id);
    for (const weaponId of unit.weaponIds) {
      assert.ok(weaponIds.has(weaponId), `${unit.id}:${weaponId}`);
    }
    for (const skillId of unit.skillIds) {
      assert.ok(skillIds.has(skillId), `${unit.id}:${skillId}`);
    }
  }

  for (const weapon of weaponCatalog) {
    assert.ok(weapon.durability > 0, `${weapon.id}:durability`);
    assert.ok(weapon.cost > 0, `${weapon.id}:cost`);
  }

  for (const pair of supportPairCatalog) {
    assert.ok(unitIds.has(pair.units[0]), pair.id);
    assert.ok(unitIds.has(pair.units[1]), pair.id);
    assert.ok(skillIds.has(pair.unlockSkillId), pair.id);
    assert.ok(pair.ranks.includes(pair.unlockRank), `${pair.id}:unlockRank`);
    for (const rank of pair.ranks) {
      assert.ok(pair.conversations.some((conversation) => conversation.rank === rank), `${pair.id}:${rank}`);
    }
  }

  for (const chapter of chapterCatalog) {
    const chapterInstanceIds = new Set(chapter.deployments.map((deployment) => deployment.instanceId));
    for (const deployment of chapter.deployments) {
      assert.ok(unitIds.has(deployment.unitDefId), `${chapter.id}:${deployment.unitDefId}`);
      if (deployment.weaponId) {
        assert.ok(weaponIds.has(deployment.weaponId), `${chapter.id}:${deployment.weaponId}`);
      }
    }
    for (const event of chapter.events ?? []) {
      assert.ok(event.id, `${chapter.id}:event:id`);
      assert.ok(event.turn > 1, `${chapter.id}:${event.id}:turn`);
      assert.ok(event.deployments.length > 0, `${chapter.id}:${event.id}:deployments`);
      if (event.ambush) {
        assert.ok(event.telegraph, `${chapter.id}:${event.id}:ambushTelegraph`);
      }
      for (const deployment of event.deployments) {
        assert.ok(!chapterInstanceIds.has(deployment.instanceId), `${chapter.id}:${event.id}:${deployment.instanceId}:duplicate`);
        chapterInstanceIds.add(deployment.instanceId);
        assert.ok(unitIds.has(deployment.unitDefId), `${chapter.id}:${event.id}:${deployment.unitDefId}`);
        if (deployment.weaponId) {
          assert.ok(weaponIds.has(deployment.weaponId), `${chapter.id}:${event.id}:${deployment.weaponId}`);
        }
      }
    }
  }
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
