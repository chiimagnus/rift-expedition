import assert from "node:assert/strict";
import test from "node:test";
import { chooseEnemyAction } from "../src/services/ai";
import { createInitialBattleState, findUnit } from "../src/services/chapter";
import { forecastCombat, resolveCombat } from "../src/services/combat";
import { activateSkill, activeSkills, refreshRound } from "../src/services/skills";
import { effectiveStats } from "../src/services/status";

test("healing wave restores allied HP and spends action", () => {
  const state = createInitialBattleState();
  const seren = findUnit(state, "seren");
  const aldric = findUnit(state, "aldric");
  seren.pos = { x: 2, y: 8 };
  aldric.pos = { x: 3, y: 8 };
  aldric.hp = 10;

  const result = activateSkill(state, "seren", "healing_wave", "aldric");

  assert.equal(result.ok, true);
  assert.equal(aldric.hp, 27);
  assert.equal(seren.acted, true);
  assert.ok(seren.exp > 0);
  assert.equal(state.bonds["aldric:seren"], 5);
});

test("stigma awakening raises forecast damage and adds dragon taint", () => {
  const state = createInitialBattleState();
  findUnit(state, "aldric").pos = { x: 9, y: 3 };
  const before = forecastCombat(state, "aldric", "bjorn").damage;

  const result = activateSkill(state, "aldric", "stigma_awaken", "aldric");
  findUnit(state, "aldric").acted = false;
  const after = forecastCombat(state, "aldric", "bjorn").damage;

  assert.equal(result.ok, true);
  assert.equal(state.flags["dragonTaint:aldric"], 1);
  assert.ok(after > before);
});

test("aegis halves incoming damage", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  aldric.skillIds.push("aegis");
  aldric.pos = { x: 9, y: 3 };
  bjorn.pos = { x: 10, y: 3 };

  const normal = forecastCombat(state, "bjorn", "aldric").damage;
  const result = activateSkill(state, "aldric", "aegis", "aldric");
  aldric.acted = false;
  resolveCombat(state, "bjorn", "aldric");

  assert.equal(result.ok, true);
  assert.ok(aldric.hp > aldric.stats.hp - normal);
});

test("charge primes cavalry damage once per turn", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  aldric.skillIds.push("charge");
  aldric.pos = { x: 9, y: 3 };
  bjorn.pos = { x: 10, y: 3 };
  const before = forecastCombat(state, "aldric", "bjorn").damage;

  assert.equal(activateSkill(state, "aldric", "charge", "aldric").ok, true);
  assert.ok(forecastCombat(state, "aldric", "bjorn").damage > before);
  assert.equal(activateSkill(state, "aldric", "charge", "aldric").ok, false);
  state.turn += 1;
  assert.equal(activateSkill(state, "aldric", "charge", "aldric").ok, true);
});

test("combat passive skills alter forecast and resolution", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains", "forest"]];
  const rowan = findUnit(state, "rowan");
  const bjorn = findUnit(state, "bjorn");
  rowan.pos = { x: 0, y: 0 };
  bjorn.pos = { x: 3, y: 0 };

  const blockedByTerrain = forecastCombat(state, "rowan", "bjorn").hit;
  rowan.skillIds.push("cloud_piercer");
  assert.ok(forecastCombat(state, "rowan", "bjorn").hit > blockedByTerrain);
  rowan.skillIds.push("quickdraw");
  rowan.stats.spd = bjorn.stats.spd + 3;
  assert.equal(forecastCombat(state, "rowan", "bjorn").followUp, true);
  assert.doesNotThrow(() => resolveCombat(state, "rowan", "bjorn"));
});

test("damage, crit, and accuracy passives share forecast math", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains"]];
  const cecilia = findUnit(state, "cecilia");
  const valentin = findUnit(state, "valentin");
  cecilia.pos = { x: 0, y: 0 };
  valentin.pos = { x: 1, y: 0 };
  cecilia.weaponId = "iron_axe";
  cecilia.weaponUses.iron_axe = 35;
  cecilia.weaponForge.iron_axe = 0;
  cecilia.stats.skill = 20;
  valentin.stats.spd = 31;
  valentin.stats.luck = 10;

  const normalDamage = forecastCombat(state, "cecilia", "valentin").damage;
  cecilia.skillIds.push("armor_break", "iaijutsu");
  const lowHit = forecastCombat(state, "cecilia", "valentin").hit;
  cecilia.skillIds.push("steady_hand");
  const skilled = forecastCombat(state, "cecilia", "valentin");
  assert.ok(skilled.damage > normalDamage);
  assert.ok(skilled.crit > 0);
  assert.ok(lowHit < 60);
  assert.equal(skilled.hit, 60);

  valentin.skillIds.push("calm");
  assert.equal(forecastCombat(state, "cecilia", "valentin").crit, 0);
});

test("foresight spends its once-per-battle dodge and poison blade applies status", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains"]];
  const cecilia = findUnit(state, "cecilia");
  const bjorn = findUnit(state, "bjorn");
  cecilia.pos = { x: 0, y: 0 };
  bjorn.pos = { x: 1, y: 0 };
  cecilia.skillIds.push("foresight");
  cecilia.stats.spd = 20;
  cecilia.weaponUses[cecilia.weaponId] = 0;
  bjorn.stats.spd = 5;

  const beforeHp = cecilia.hp;
  assert.equal(forecastCombat(state, "bjorn", "cecilia").hit, 0);
  resolveCombat(state, "bjorn", "cecilia");
  assert.equal(cecilia.hp, beforeHp);
  assert.equal(cecilia.skillUses.foresight, 1);

  bjorn.skillIds.push("poison_blade", "steady_hand");
  bjorn.classId = "scout";
  cecilia.statuses = [];
  cecilia.stats.spd = 0;
  cecilia.stats.luck = 0;
  assert.equal(activateSkill(state, "bjorn", "poison_blade", "bjorn").ok, true);
  resolveCombat(state, "bjorn", "cecilia");
  assert.ok(cecilia.statuses.some((status) => status.id === "poison"));
});

test("rally, barrier, mark, silence, and freeze active skills apply statuses", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains", "plains"]];
  const seren = findUnit(state, "seren");
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  seren.skillIds.push("rally_defense", "rally_speed", "barrier", "mark_target", "silence", "freeze_field");
  seren.pos = { x: 0, y: 0 };
  aldric.pos = { x: 1, y: 0 };
  bjorn.pos = { x: 3, y: 0 };

  assert.equal(activateSkill(state, "seren", "rally_defense", "seren").ok, true);
  assert.equal(effectiveStats(aldric).def, aldric.stats.def + 2);
  seren.acted = false;
  assert.equal(activateSkill(state, "seren", "rally_speed", "seren").ok, true);
  assert.equal(effectiveStats(aldric).spd, aldric.stats.spd + 2);
  seren.acted = false;
  assert.equal(activateSkill(state, "seren", "barrier", "aldric").ok, true);
  assert.equal(effectiveStats(aldric).res, aldric.stats.res + 5);

  const baseHit = forecastCombat(state, "aldric", "bjorn").hit;
  seren.acted = false;
  assert.equal(activateSkill(state, "seren", "mark_target", "bjorn").ok, true);
  assert.ok(forecastCombat(state, "aldric", "bjorn").hit > baseHit);

  bjorn.skillIds.push("aegis");
  seren.acted = false;
  assert.equal(activateSkill(state, "seren", "silence", "bjorn").ok, true);
  assert.equal(activeSkills(bjorn).length, 0);

  seren.acted = false;
  assert.equal(activateSkill(state, "seren", "freeze_field", "bjorn").ok, true);
  assert.equal(effectiveStats(bjorn).move, Math.max(0, bjorn.stats.move - 2));
});

test("positioning active skills swap, push, smite, and pull units", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains", "plains", "plains"]];
  const aldric = findUnit(state, "aldric");
  const cecilia = findUnit(state, "cecilia");
  const rowan = findUnit(state, "rowan");
  aldric.skillIds.push("swap", "shove", "smite", "rescue_pull");
  aldric.pos = { x: 1, y: 0 };
  cecilia.pos = { x: 2, y: 0 };
  rowan.pos = { x: 0, y: 0 };

  assert.equal(activateSkill(state, "aldric", "swap", "cecilia").ok, true);
  assert.deepEqual(aldric.pos, { x: 2, y: 0 });
  assert.deepEqual(cecilia.pos, { x: 1, y: 0 });

  aldric.acted = false;
  aldric.pos = { x: 1, y: 0 };
  cecilia.pos = { x: 2, y: 0 };
  assert.equal(activateSkill(state, "aldric", "shove", "cecilia").ok, true);
  assert.deepEqual(cecilia.pos, { x: 3, y: 0 });

  aldric.acted = false;
  cecilia.pos = { x: 2, y: 0 };
  cecilia.skillIds.push("bulwark");
  assert.equal(activateSkill(state, "aldric", "smite", "cecilia").ok, false);
  cecilia.skillIds = cecilia.skillIds.filter((id) => id !== "bulwark");
  assert.equal(activateSkill(state, "aldric", "smite", "cecilia").ok, true);
  assert.deepEqual(cecilia.pos, { x: 4, y: 0 });

  aldric.acted = false;
  cecilia.pos = { x: 4, y: 0 };
  rowan.pos = { x: 3, y: 0 };
  assert.equal(activateSkill(state, "aldric", "rescue_pull", "rowan").ok, true);
  assert.deepEqual(rowan.pos, { x: 2, y: 0 });
});

test("damage active skills affect multiple tactical shapes", () => {
  const state = createInitialBattleState();
  state.grid = [
    ["plains", "plains", "plains", "plains", "plains"],
    ["plains", "plains", "plains", "plains", "plains"],
  ];
  const cecilia = findUnit(state, "cecilia");
  const rowan = findUnit(state, "rowan");
  const mirelle = findUnit(state, "mirelle");
  const bjorn = findUnit(state, "bjorn");
  const scout = findUnit(state, "scout_a");
  const raider = findUnit(state, "raider_a");
  cecilia.skillIds.push("gale_cross");
  rowan.skillIds.push("piercing_shot");
  mirelle.skillIds.push("meteor");
  cecilia.pos = { x: 0, y: 0 };
  rowan.pos = { x: 2, y: 1 };
  mirelle.pos = { x: 0, y: 0 };
  bjorn.pos = { x: 1, y: 0 };
  scout.pos = { x: 1, y: 1 };
  raider.pos = { x: 4, y: 1 };
  const bjornHp = bjorn.hp;
  const scoutHp = scout.hp;
  const raiderHp = raider.hp;

  assert.equal(activateSkill(state, "cecilia", "gale_cross", "bjorn").ok, true);
  assert.ok(bjorn.hp < bjornHp);
  assert.ok(scout.hp < scoutHp);
  const scoutAfterGale = scout.hp;

  rowan.acted = false;
  assert.equal(activateSkill(state, "rowan", "piercing_shot", "raider_a").ok, true);
  assert.ok(raider.hp < raiderHp);
  assert.equal(scout.hp, scoutAfterGale);

  const beforeMeteor = bjorn.hp;
  mirelle.acted = false;
  assert.equal(activateSkill(state, "mirelle", "meteor", "bjorn").ok, true);
  assert.ok(bjorn.hp < beforeMeteor);
});

test("resurrection, refresh, and stigma actives alter persistent battle state", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains"]];
  const seren = findUnit(state, "seren");
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  seren.skillIds.push("resurrection", "saint_refresh");
  aldric.skillIds.push("stigma_seal", "stigma_roar");
  seren.pos = { x: 0, y: 0 };
  aldric.pos = { x: 1, y: 0 };
  bjorn.pos = { x: 2, y: 0 };
  aldric.alive = false;
  aldric.hp = 0;

  assert.equal(activateSkill(state, "seren", "resurrection", "aldric").ok, true);
  assert.equal(aldric.alive, true);
  assert.ok(aldric.hp > 0);

  seren.acted = false;
  aldric.acted = true;
  assert.equal(activateSkill(state, "seren", "saint_refresh", "aldric").ok, true);
  assert.equal(aldric.acted, false);

  state.flags["dragonTaint:aldric"] = 2;
  aldric.acted = false;
  assert.equal(activateSkill(state, "aldric", "stigma_seal", "aldric").ok, true);
  assert.equal(state.flags["dragonTaint:aldric"], 1);

  aldric.acted = false;
  assert.equal(activateSkill(state, "aldric", "stigma_roar", "aldric").ok, true);
  assert.equal(state.flags["dragonTaint:aldric"], 2);
  assert.ok(bjorn.statuses.some((status) => status.id === "frozen"));
});

test("taunt active skill redirects enemy AI when the source is reachable", () => {
  const state = createInitialBattleState();
  state.grid = [["plains", "plains", "plains"]];
  const valentin = findUnit(state, "valentin");
  const aldric = findUnit(state, "aldric");
  const bjorn = findUnit(state, "bjorn");
  valentin.skillIds.push("taunt");
  valentin.pos = { x: 0, y: 0 };
  aldric.pos = { x: 2, y: 0 };
  bjorn.pos = { x: 1, y: 0 };
  aldric.hp = 1;

  assert.equal(activateSkill(state, "valentin", "taunt", "bjorn").ok, true);
  const action = chooseEnemyAction(state, bjorn);
  assert.equal(action.attackTargetId, "valentin");
});

test("round refresh accrues adjacent bonds and ticks statuses", () => {
  const state = createInitialBattleState();
  const aldric = findUnit(state, "aldric");
  const cecilia = findUnit(state, "cecilia");
  aldric.statuses.push({ id: "sprint", turns: 1 });
  aldric.pos = { x: 1, y: 1 };
  cecilia.pos = { x: 1, y: 2 };

  refreshRound(state);

  assert.equal(aldric.statuses.length, 0);
  assert.equal(state.bonds["aldric:cecilia"], 3);
});
