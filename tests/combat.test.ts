import assert from "node:assert/strict";
import test from "node:test";
import { magicTriangle, weaponTriangle } from "../src/data/content";
import { createInitialBattleState } from "../src/services/chapter";
import { forecastCombat, resolveCombat } from "../src/services/combat";

test("weapon and magic matrices have zero row sums", () => {
  for (const row of Object.values(weaponTriangle)) {
    assert.equal(Object.values(row).reduce((sum, value) => sum + value, 0), 0);
  }
  for (const row of Object.values(magicTriangle)) {
    assert.equal(Object.values(row).reduce((sum, value) => sum + value, 0), 0);
  }
});

test("A/03 physical example plus A/06 forest defense keeps forecast math", () => {
  const state = createInitialBattleState();
  state.grid = [["forest"]];
  state.units = [
    {
      id: "sword",
      defId: "cecilia",
      team: "ally",
      classId: "sword_fighter",
      hp: 30,
      stats: { hp: 30, str: 18, mag: 0, skill: 12, spd: 14, luck: 0, def: 5, res: 2, move: 5, con: 9 },
      weaponId: "iron_sword",
      weaponUses: { iron_sword: 40 },
      weaponForge: { iron_sword: 0 },
      skillIds: [],
      statuses: [],
      skillUses: {},
      pos: { x: 0, y: 0 },
      acted: false,
      alive: true,
      level: 1,
      exp: 0,
    },
    {
      id: "axe",
      defId: "nord_raider",
      team: "enemy",
      classId: "sword_fighter",
      hp: 30,
      stats: { hp: 30, str: 10, mag: 0, skill: 8, spd: 9, luck: 3, def: 7, res: 1, move: 5, con: 9 },
      weaponId: "iron_axe",
      weaponUses: { iron_axe: 35 },
      weaponForge: { iron_axe: 0 },
      skillIds: [],
      statuses: [],
      skillUses: {},
      pos: { x: 0, y: 0 },
      acted: false,
      alive: true,
      level: 1,
      exp: 0,
    },
  ];

  const forecast = forecastCombat(state, "sword", "axe");
  assert.equal(forecast.damage, 16);
  assert.equal(forecast.hit, 88);
  assert.equal(forecast.followUp, true);
});

test("combat resolution is deterministic from stored rng state", () => {
  const left = createInitialBattleState();
  const right = createInitialBattleState();
  left.units.find((unit) => unit.id === "aldric")!.pos = { x: 9, y: 3 };
  right.units.find((unit) => unit.id === "aldric")!.pos = { x: 9, y: 3 };

  resolveCombat(left, "aldric", "bjorn");
  resolveCombat(right, "aldric", "bjorn");

  assert.deepEqual(
    left.units.map((unit) => [unit.id, unit.hp, unit.alive]),
    right.units.map((unit) => [unit.id, unit.hp, unit.alive]),
  );
  assert.equal(left.rngState, right.rngState);
});

test("combat spends weapon durability and blocks broken weapons", () => {
  const state = createInitialBattleState();
  const aldric = state.units.find((unit) => unit.id === "aldric")!;
  aldric.pos = { x: 9, y: 3 };
  aldric.weaponUses[aldric.weaponId] = 1;

  resolveCombat(state, "aldric", "bjorn");

  assert.equal(aldric.weaponUses[aldric.weaponId], 0);
  assert.ok(state.log.some((line) => line.includes("损坏")));
  assert.throws(() => resolveCombat(state, "aldric", "bjorn"), /耐久耗尽/);
});
