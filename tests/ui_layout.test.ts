import assert from "node:assert/strict";
import test from "node:test";
import { pageSlice } from "../src/ui/layout";

test("pageSlice exposes every item across deployment pages", () => {
  const units = ["aldric", "valentin", "mirelle", "cecilia", "rowan", "seren", "elara", "sigrun", "bjorn"];

  const first = pageSlice(units, 0, 5);
  const second = pageSlice(units, 1, 5);

  assert.deepEqual(first.items, ["aldric", "valentin", "mirelle", "cecilia", "rowan"]);
  assert.deepEqual(second.items, ["seren", "elara", "sigrun", "bjorn"]);
  assert.deepEqual([...first.items, ...second.items], units);
});

test("pageSlice clamps empty and out-of-range pages", () => {
  assert.deepEqual(pageSlice([], 9, 5), { page: 0, totalPages: 1, start: 0, end: 0, items: [] });
  assert.equal(pageSlice(["aldric"], -2, 5).page, 0);
  assert.equal(pageSlice(["aldric"], 2, 5).page, 0);
});
