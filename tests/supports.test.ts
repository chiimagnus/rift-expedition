import assert from "node:assert/strict";
import test from "node:test";
import { BOND } from "../src/data";
import { createNewCampaign } from "../src/services/campaign";
import { availableSupportConversations, bondKey, bondRank, supportConversationKey, viewSupportConversation } from "../src/services/supports";

test("bond ranks follow configured thresholds", () => {
  assert.equal(bondRank(BOND.C), "C");
  assert.equal(bondRank(BOND.B), "B");
  assert.equal(bondRank(BOND.A), "A");
  assert.equal(bondRank(BOND.S), "S");
});

test("viewing an unlocked support marks it read and grants pair skill", () => {
  const campaign = {
    ...createNewCampaign(),
    bonds: { [bondKey("aldric", "mirelle")]: BOND.B },
  };

  const before = availableSupportConversations(campaign).find((support) => support.pair.id === "aldric_mirelle" && support.rank === "B");
  assert.equal(before?.viewed, false);

  const viewed = viewSupportConversation(campaign, "aldric_mirelle", "B");
  const mirelle = viewed.roster.find((entry) => entry.unitDefId === "mirelle")!;

  assert.equal(viewed.flags[supportConversationKey("aldric_mirelle", "B")], true);
  assert.ok(mirelle.skillIds.includes("oath_resonance"));
});
