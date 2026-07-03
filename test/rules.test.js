'use strict';
// 纯逻辑单元测试：仅用 Node 内置 node:test + node:assert，零依赖、不联网。
// 运行： node --test test/rules.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
require('../src/rules.js'); // 副作用：挂载 globalThis.RiftRules
const R = globalThis.RiftRules;

test('地图为 ROWS 行 × COLS 列，且每格地形均已定义', () => {
  assert.equal(R.MAP.length, R.ROWS);
  for (const row of R.MAP) {
    assert.equal(row.length, R.COLS);
    for (const ch of row) assert.ok(R.TERR[ch], `未知地形: ${ch}`);
  }
});

test('地形代价与阻挡符合设计', () => {
  assert.equal(R.TERR.G.cost, 1);
  assert.equal(R.TERR.F.cost, 2);
  assert.equal(R.TERR.F.def, 2);
  assert.equal(R.TERR.W.block, true);
  assert.equal(R.TERR.M.block, true);
});

test('单位定义字段完整且数值合法', () => {
  for (const key of Object.keys(R.DEF)) {
    const d = R.DEF[key];
    for (const f of ['n', 'hp', 'atk', 'def', 'mov', 'rng', 'kind', 'dmg']) {
      assert.ok(d[f] !== undefined, `${key}.${f} 缺失`);
    }
    assert.ok(d.hp > 0 && d.mov > 0 && d.rng >= 1, `${key} 数值非法`);
  }
});

test('calcDmg 始终为 ≥1 的整数，且 crit 为布尔', () => {
  const atk = { def: { atk: 1 } };
  const def = { def: { def: 99 }, x: 0, y: 3 }; // 极高防御，验证伤害下限 =1
  for (let i = 0; i < 300; i++) {
    const r = R.calcDmg(atk, def);
    assert.ok(Number.isInteger(r.dmg) && r.dmg >= 1, `dmg 非法: ${r.dmg}`);
    assert.equal(typeof r.crit, 'boolean');
  }
});

test('reachable 尊重移动力、地形阻挡与边界', () => {
  const occAt = () => null; // 空场：无单位阻挡
  const u = { id: 0, side: 'ally', x: 0, y: 3, def: { mov: 3 } };
  const reach = R.reachable(u, occAt);
  assert.equal(reach['0,3'].cost, 0); // 起点可达、代价 0
  for (const k in reach) {
    if (k[0] === '_') continue;
    const [x, y] = k.split(',').map(Number);
    assert.ok(!R.terr(x, y).block, `不应包含阻挡地形 ${k}`);
    assert.ok(reach[k].cost <= 3, `代价超出移动力 ${k}`);
  }
});

test('pathTo 重建的路径每步四邻相接且终点正确', () => {
  const occAt = () => null;
  const u = { id: 0, side: 'ally', x: 0, y: 3, def: { mov: 4 } };
  const reach = R.reachable(u, occAt);
  const target = Object.keys(reach).find((k) => k[0] !== '_' && k !== '0,3');
  const [tx, ty] = target.split(',').map(Number);
  const path = R.pathTo(reach, tx, ty);
  assert.ok(path && path.length >= 1);
  let prev = { x: 0, y: 3 };
  for (const s of path) {
    assert.equal(Math.abs(s.x - prev.x) + Math.abs(s.y - prev.y), 1, '相邻步进');
    prev = s;
  }
  assert.deepEqual(path[path.length - 1], { x: tx, y: ty });
});
