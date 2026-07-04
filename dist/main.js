"use strict";
var RiftExpedition = (() => {
  // src/data/chapter01.ts
  var chapter01 = {
    id: "ch01",
    title: "01 \u8FB9\u5883\u906D\u9047",
    act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB",
    objective: "\u51FB\u9000\u5317\u5883\u5148\u950B\uFF1B\u827E\u62C9\u83C8\u4E0E\u6BD4\u7EA6\u6069\u4F1A\u64A4\u9000\uFF0C\u6218\u6597\u540E\u8FDB\u5165\u4E0B\u4E00\u7AE0\u4F0F\u7B14\u3002",
    victoryCondition: { type: "rout" },
    nextChapterId: "ch02",
    victoryText: [
      "\u5317\u5883\u5148\u950B\u9000\u5165\u6797\u7EBF\u3002\u5965\u5FB7\u91CC\u514B\u6CA1\u6709\u8FFD\u51FB\uFF0C\u4ED6\u7B2C\u4E00\u6B21\u6000\u7591\u201C\u51C0\u5316\u201D\u8FD9\u4E2A\u8BCD\u3002",
      "\u827E\u62C9\u83C8\u56DE\u671B\u6865\u5934\uFF0C\u8BB0\u4F4F\u4E86\u90A3\u4E2A\u6CA1\u6709\u4E0B\u6B7B\u624B\u7684\u5357\u65B9\u9A91\u58EB\u3002"
    ],
    terrainLegend: {
      P: "plains",
      R: "road",
      F: "forest",
      M: "mountain",
      W: "river",
      B: "bridge",
      V: "village",
      A: "altar"
    },
    map: [
      "MMFFPPPPRRPPFF",
      "MFFPPPPPRRPPPF",
      "FFPPPWWBRRPPPF",
      "FPPPPWWBRRPPPP",
      "PPPVPPPRRPPPPP",
      "PPPPFFFPRRPPPP",
      "PPPPFPPPRRPPPF",
      "PPPPPPPPRRFFFF",
      "PPPPPAAARRPPFM",
      "PPPPPPPPPPPFMM"
    ],
    deployments: [
      { unitDefId: "aldric", instanceId: "aldric", team: "ally", x: 3, y: 8, weaponId: "iron_lance" },
      { unitDefId: "valentin", instanceId: "valentin", team: "ally", x: 2, y: 8, weaponId: "iron_lance" },
      { unitDefId: "mirelle", instanceId: "mirelle", team: "ally", x: 4, y: 9, weaponId: "fire" },
      { unitDefId: "cecilia", instanceId: "cecilia", team: "ally", x: 1, y: 8, weaponId: "iron_sword" },
      { unitDefId: "rowan", instanceId: "rowan", team: "ally", x: 2, y: 9, weaponId: "short_bow" },
      { unitDefId: "seren", instanceId: "seren", team: "ally", x: 0, y: 9, weaponId: "heal_staff" },
      { unitDefId: "elara", instanceId: "elara", team: "enemy", x: 11, y: 1, weaponId: "thunder" },
      { unitDefId: "sigrun", instanceId: "sigrun", team: "enemy", x: 12, y: 2, weaponId: "iron_lance" },
      { unitDefId: "bjorn", instanceId: "bjorn", team: "enemy", x: 10, y: 3, weaponId: "iron_axe" },
      { unitDefId: "nord_raider", instanceId: "raider_a", team: "enemy", x: 9, y: 2, weaponId: "iron_axe" },
      { unitDefId: "nord_scout", instanceId: "scout_a", team: "enemy", x: 12, y: 5, weaponId: "iron_sword" },
      { unitDefId: "ice_mage", instanceId: "ice_mage_a", team: "enemy", x: 9, y: 5, weaponId: "ice" }
    ],
    visits: [
      {
        id: "border_hamlet",
        x: 3,
        y: 4,
        label: "\u8FB9\u5883\u6751",
        message: "\u6751\u6C11\u628A\u85CF\u8D77\u7684\u6CBB\u7597\u6756\u4EA4\u7ED9\u5965\u5FB7\u91CC\u514B\uFF1A\u522B\u8BA9\u5723\u5149\u53EA\u5269\u5BA1\u5224\u3002",
        weaponId: "heal_staff",
        weaponCount: 1,
        flag: "visitedBorderHamlet",
        value: true
      }
    ],
    opening: [
      "\u5965\u5FB7\u91CC\u514B\uFF1A\u8FB9\u5883\u6751\u8FD8\u5728\u71C3\u70E7\u3002\u6559\u4F1A\u8BF4\u5317\u5883\u4EBA\u7686\u4E3A\u5F02\u7AEF\uFF0C\u4F46\u706B\u7130\u6CA1\u6709\u56DE\u7B54\u6211\u3002",
      "\u74E6\u4F26\u4E01\uFF1A\u5B88\u4F4F\u6865\u53E3\uFF0C\u522B\u8BA9\u5E74\u8F7B\u4EBA\u51B2\u8FDB\u68EE\u6797\u3002\u9A91\u5175\u5728\u6797\u91CC\u4F1A\u6B7B\u5F97\u5F88\u96BE\u770B\u3002",
      "\u827E\u62C9\u83C8\uFF1A\u5357\u65B9\u9A91\u58EB\u4E5F\u4F1A\u4FDD\u62A4\u6751\u5E84\uFF1F\u771F\u8BBD\u523A\u3002\u90A3\u5C31\u8BA9\u6211\u770B\u770B\u4F60\u7684\u5251\uFF0C\u5230\u5E95\u5B88\u8C01\u3002"
    ]
  };

  // src/data/campaign.ts
  var legend = chapter01.terrainLegend;
  var maps = {
    border: chapter01.map,
    village: [
      "FFPPPVVPRRPPFF",
      "FPPPPPPPRRPPPF",
      "PPVPPWWBRRPPPF",
      "PPPPPWWBRRPPPP",
      "PPPVPPPRRPPPPP",
      "PPPFFFFPRRPPPP",
      "PPPPFPPPRRPPPF",
      "PPPPPPPPRRFFFF",
      "PPPPPAAARRPPFM",
      "PPPPPPPPPPPFMM"
    ],
    bridge: [
      "MMFFPPPPRRPPFF",
      "MFFPPWWBRRPPPF",
      "FFPPPWWBRRPPPF",
      "FPPPPWWBRRPPPP",
      "PPPPWWBBRRPPPP",
      "PPPPWWBBRRPPPP",
      "PPPPFWWBRRPPPF",
      "PPPPPPPPRRFFFF",
      "PPPPPAAARRPPFM",
      "PPPPPPPPPPPFMM"
    ],
    snow: [
      "MMFFMMMPRRPPFF",
      "MFFPMMMPRRPPPF",
      "FFPPPWWBRRPPPF",
      "FPPPPWWBRRPPPP",
      "PPPVPPPRRPPPPP",
      "PPPFFFFPRRPPPP",
      "PPPMFPPPRRPPPF",
      "PPPMMPPPRRFFFF",
      "PPPMPAAARRPPFM",
      "PPPPPPPPPPPFMM"
    ],
    altar: [
      "MMFFPPPPRRPPFF",
      "MFFPPPPPRRPPPF",
      "FFPPPWWBRRPPPF",
      "FPPPPWWBRRPPPP",
      "PPPVAAAARRPPPP",
      "PPPFAAAARRPPPP",
      "PPPPAAAARRPPPF",
      "PPPPPPPPRRFFFF",
      "PPPPPAAARRPPFM",
      "PPPPPPPPPPPFMM"
    ]
  };
  var soreinAllies = [
    { unitDefId: "aldric", instanceId: "aldric", team: "ally", x: 3, y: 8, weaponId: "iron_lance" },
    { unitDefId: "valentin", instanceId: "valentin", team: "ally", x: 2, y: 8, weaponId: "iron_lance" },
    { unitDefId: "mirelle", instanceId: "mirelle", team: "ally", x: 4, y: 9, weaponId: "fire" },
    { unitDefId: "cecilia", instanceId: "cecilia", team: "ally", x: 1, y: 8, weaponId: "iron_sword" },
    { unitDefId: "rowan", instanceId: "rowan", team: "ally", x: 2, y: 9, weaponId: "short_bow" },
    { unitDefId: "seren", instanceId: "seren", team: "ally", x: 0, y: 9, weaponId: "heal_staff" }
  ];
  var nordheimAllies = [
    { unitDefId: "elara", instanceId: "elara", team: "ally", x: 3, y: 8, weaponId: "thunder" },
    { unitDefId: "sigrun", instanceId: "sigrun", team: "ally", x: 2, y: 8, weaponId: "iron_lance" },
    { unitDefId: "bjorn", instanceId: "bjorn", team: "ally", x: 4, y: 9, weaponId: "iron_axe" },
    { unitDefId: "nord_scout", instanceId: "scout_ally", team: "ally", x: 1, y: 8, weaponId: "iron_sword" },
    { unitDefId: "ice_mage", instanceId: "ice_mage_ally", team: "ally", x: 2, y: 9, weaponId: "ice" }
  ];
  var nordheimEnemies = [
    { unitDefId: "elara", instanceId: "elara", team: "enemy", x: 11, y: 1, weaponId: "thunder" },
    { unitDefId: "sigrun", instanceId: "sigrun", team: "enemy", x: 12, y: 2, weaponId: "iron_lance" },
    { unitDefId: "bjorn", instanceId: "bjorn", team: "enemy", x: 10, y: 3, weaponId: "iron_axe" },
    { unitDefId: "nord_raider", instanceId: "raider_a", team: "enemy", x: 9, y: 2, weaponId: "iron_axe" },
    { unitDefId: "nord_scout", instanceId: "scout_a", team: "enemy", x: 12, y: 5, weaponId: "iron_sword" },
    { unitDefId: "ice_mage", instanceId: "ice_mage_a", team: "enemy", x: 9, y: 5, weaponId: "ice" }
  ];
  var soreinEnemies = [
    { unitDefId: "aldric", instanceId: "aldric_enemy", team: "enemy", x: 11, y: 1, weaponId: "iron_lance" },
    { unitDefId: "valentin", instanceId: "valentin_enemy", team: "enemy", x: 10, y: 2, weaponId: "iron_lance" },
    { unitDefId: "mirelle", instanceId: "mirelle_enemy", team: "enemy", x: 9, y: 4, weaponId: "fire" },
    { unitDefId: "cecilia", instanceId: "cecilia_enemy", team: "enemy", x: 12, y: 3, weaponId: "iron_sword" },
    { unitDefId: "rowan", instanceId: "rowan_enemy", team: "enemy", x: 12, y: 5, weaponId: "short_bow" }
  ];
  var churchEnemies = [
    { unitDefId: "cecilia", instanceId: "cecilia_boss", team: "enemy", x: 11, y: 1, weaponId: "iron_sword" },
    { unitDefId: "valentin", instanceId: "templar_a", team: "enemy", x: 10, y: 2, weaponId: "iron_lance" },
    { unitDefId: "mirelle", instanceId: "court_mage_a", team: "enemy", x: 9, y: 4, weaponId: "fire" },
    { unitDefId: "rowan", instanceId: "bow_guard_a", team: "enemy", x: 12, y: 5, weaponId: "short_bow" },
    { unitDefId: "nord_raider", instanceId: "zealot_a", team: "enemy", x: 10, y: 5, weaponId: "hammer" },
    { unitDefId: "ice_mage", instanceId: "oracle_a", team: "enemy", x: 12, y: 2, weaponId: "thunder" }
  ];
  var joinedAllies = [...soreinAllies, ...nordheimAllies.slice(0, 3)];
  var outlines = [
    { id: "ch02", title: "02 \u7126\u571F\u6751\u5E84", act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB", objective: "\u62A4\u9001\u96BE\u6C11\u7A7F\u8FC7\u6751\u5E84\uFF0C\u51FB\u9000\u6559\u4F1A\u5BA1\u5224\u961F\u3002", victoryCondition: { type: "escape", x: 13, y: 8, unitDefIds: ["aldric"] }, map: "village", side: "sorein", opening: ["\u5BA1\u5224\u5B98\u7684\u706B\u628A\u7167\u4EAE\u6751\u53E3\uFF0C\u74E6\u4F26\u4E01\u547D\u4EE4\u6240\u6709\u4EBA\u5148\u6551\u4EBA\u3002"], victoryText: ["\u5E78\u5B58\u8005\u4F4E\u58F0\u8BF4\uFF0C\u7EB5\u706B\u8005\u7A7F\u7740\u5723\u5149\u6559\u4F1A\u7684\u767D\u888D\u3002"] },
    { id: "ch03", title: "03 \u65AD\u6865\u963B\u51FB", act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB", objective: "\u5B88\u4F4F\u6865\u53E3 3 \u56DE\u5408\u5E76\u51FB\u9000\u5317\u5883\u8FFD\u5175\u3002", victoryCondition: { type: "all", conditions: [{ type: "survive", turns: 3 }, { type: "rout" }] }, map: "bridge", side: "sorein", opening: ["\u65AD\u6865\u53EA\u5269\u4E00\u7EBF\u901A\u8DEF\uFF0C\u9A91\u5175\u65E0\u6CD5\u5C55\u5F00\uFF0C\u68EE\u6797\u6210\u4E86\u771F\u6B63\u7684\u654C\u4EBA\u3002"], victoryText: ["\u74E6\u4F26\u4E01\u8D1F\u4F24\uFF0C\u4ED6\u638C\u5FC3\u91CC\u6525\u7740\u4E00\u679A\u6559\u4F1A\u7EB9\u7AE0\u3002"] },
    { id: "ch04", title: "04 \u53CC\u7EBF\u5E76\u884C", act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB", objective: "\u5207\u6362\u5230\u827E\u62C9\u83C8\u89C6\u89D2\uFF0C\u6551\u51FA\u88AB\u5357\u519B\u56F4\u6355\u7684\u65CF\u4EBA\u3002", victoryCondition: { type: "seize", x: 2, y: 2, unitDefIds: ["elara"] }, map: "snow", side: "nordheim", opening: ["\u5317\u5883\u7684\u96EA\u76D6\u4E0D\u4F4F\u8840\u8FF9\u3002\u827E\u62C9\u83C8\u7B2C\u4E00\u6B21\u8BA9\u73A9\u5BB6\u770B\u89C1\u6218\u4E89\u7684\u53E6\u4E00\u9762\u3002"], victoryText: ["\u5357\u65B9\u4EBA\u7684\u9A91\u58EB\u9053\uFF0C\u5728\u96EA\u5730\u91CC\u663E\u5F97\u548C\u8C0E\u8A00\u4E00\u6837\u82CD\u767D\u3002"] },
    { id: "ch05", title: "05 \u96EA\u591C\u5947\u88AD", act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB", objective: "\u5144\u59B9\u9635\u8425\u6B63\u9762\u4EA4\u950B\uFF0C\u4EFB\u4E00\u4E3B\u89D2\u64A4\u9000\u5373\u53EF\u8FC7\u5173\u3002", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["elara"] }, map: "snow", side: "sorein", opening: ["\u96EA\u591C\u91CC\uFF0C\u4E24\u679A\u9F99\u75D5\u9694\u7740\u6218\u573A\u9690\u9690\u53D1\u70EB\u3002"], victoryText: ["\u6CA1\u4EBA\u77E5\u9053\u4E3A\u4EC0\u4E48\u6700\u540E\u4E00\u51FB\u504F\u4E86\u534A\u5BF8\u3002"] },
    { id: "ch06", title: "06 \u8840\u8272\u9ECE\u660E", act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB", objective: "\u4FDD\u62A4\u74E6\u4F26\u4E01\u64A4\u79BB\uFF0C\u51FB\u7834\u8FFD\u51FB\u8005\u3002", victoryCondition: { type: "rout" }, defeatConditions: [{ type: "protectUnit", unitDefIds: ["valentin"] }], map: "village", side: "sorein", opening: ["\u9ECE\u660E\u50CF\u8840\u4E00\u6837\u6F2B\u8FC7\u9EA6\u7530\u3002\u74E6\u4F26\u4E01\u8BF4\uFF0C\u522B\u76F8\u4FE1\u6BCF\u4E00\u9053\u5723\u5149\u3002"], victoryText: ["\u74E6\u4F26\u4E01\u6218\u6B7B\uFF0C\u51F6\u5668\u4E0A\u5E26\u7740\u6559\u4F1A\u7EB9\u7AE0\u3002"] },
    { id: "ch07", title: "07 \u4FF1\u864F\u4E0E\u5BF9\u8BDD", act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB", objective: "\u5144\u59B9\u88AB\u56DA\uFF0C\u540C\u573A\u8D8A\u8FC7\u5B88\u536B\u63A7\u5236\u533A\u5E76\u4F1A\u5408\u3002", victoryCondition: { type: "escape", x: 7, y: 4, unitDefIds: ["aldric", "elara"] }, map: "bridge", side: "joined", opening: ["\u540C\u4E00\u4E2A\u6218\u4FD8\u8425\u91CC\uFF0C\u5965\u5FB7\u91CC\u514B\u548C\u827E\u62C9\u83C8\u7EC8\u4E8E\u4EA4\u6362\u4E86\u540D\u5B57\u3002"], victoryText: ["\u654C\u4EBA\u7684\u8138\u53D8\u5F97\u5177\u4F53\uFF0C\u4EC7\u6068\u7B2C\u4E00\u6B21\u8FDF\u7591\u3002"] },
    { id: "ch08", title: "08 \u9003\u4EA1\u4E4B\u7EA6", act: "\u7B2C\u4E00\u5E55\uFF1A\u76F8\u9047\u4E0E\u80CC\u53DB", objective: "\u5408\u529B\u8D8A\u72F1\uFF0C\u5360\u9886\u51FA\u53E3\u3002", victoryCondition: { type: "seize", x: 6, y: 4 }, map: "altar", side: "joined", opening: ["\u8D8A\u72F1\u4E0D\u662F\u540C\u76DF\uFF0C\u53EA\u662F\u540C\u4E00\u6761\u8DEF\u4E0A\u6682\u65F6\u4E0D\u80FD\u4E92\u76F8\u6740\u6B7B\u3002"], victoryText: ["\u7BDD\u706B\u65C1\uFF0C\u53CC\u751F\u52A8\u673A\u7B2C\u4E00\u6B21\u5408\u5728\u4E00\u8D77\u3002"] },
    { id: "ch09", title: "09 \u9F99\u75D5\u5171\u9E23", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u8C03\u67E5\u9F99\u75D5\u796D\u575B\uFF0C\u51FB\u9000\u88AB\u5438\u5F15\u6765\u7684\u6559\u4F1A\u519B\u3002", victoryCondition: { type: "seize", x: 6, y: 4, unitDefIds: ["aldric", "elara"] }, map: "altar", side: "joined", opening: ["\u796D\u575B\u56DE\u5E94\u4E24\u4EBA\u7684\u8840\uFF0C\u77F3\u7F1D\u91CC\u4EAE\u8D77\u7329\u7EA2\u7EB9\u8DEF\u3002"], victoryText: ["\u4E24\u679A\u5723\u75D5\u540C\u65F6\u707C\u75DB\uFF0C\u5C01\u5370\u771F\u76F8\u9732\u51FA\u7B2C\u4E00\u9053\u88C2\u7F1D\u3002"] },
    { id: "ch10", title: "10 \u5723\u90FD\u7591\u4E91", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u6F5C\u5165\u6863\u6848\u9986\uFF0C\u593A\u53D6\u53CC\u751F\u8BB0\u5F55\u3002", victoryCondition: { type: "seize", x: 5, y: 0 }, map: "village", side: "joined", opening: ["\u5723\u90FD\u7684\u949F\u58F0\u592A\u6574\u9F50\uFF0C\u6574\u9F50\u5F97\u50CF\u5BA1\u5224\u3002"], victoryText: ["\u6863\u6848\u5199\u7740\uFF1A\u53CC\u751F\u5B50\u51FA\u751F\u5F53\u591C\u5373\u88AB\u5206\u79BB\u3002"] },
    { id: "ch11", title: "11 \u5F11\u7236\u771F\u76F8", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u7A81\u7834\u6559\u4F1A\u5C01\u9501\uFF0C\u63ED\u5F00\u5F11\u7236\u547D\u4EE4\u3002", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "bridge", side: "joined", opening: ["\u771F\u76F8\u4E0D\u662F\u94A5\u5319\uFF0C\u662F\u5200\u3002\u5B83\u4F1A\u5148\u5272\u5F00\u63E1\u4F4F\u5B83\u7684\u4EBA\u3002"], victoryText: ["\u517B\u7236\u66FE\u5949\u6559\u4F1A\u4E4B\u547D\u6740\u6B7B\u4E24\u4EBA\u7684\u751F\u7236\u3002"] },
    { id: "ch12", title: "12 \u7981\u5FCC\u4E4B\u5FC3", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u62A4\u9001\u53CC\u751F\u79BB\u5F00\u4F0F\u51FB\u5708\uFF0C\u4FDD\u6301\u4E8C\u4EBA\u5B58\u6D3B\u3002", victoryCondition: { type: "escape", x: 13, y: 8, unitDefIds: ["aldric", "elara"] }, defeatConditions: [{ type: "protectUnit", unitDefIds: ["aldric", "elara"] }], map: "snow", side: "joined", opening: ["\u8840\u7F18\u4E0E\u5FC3\u610F\u540C\u65F6\u843D\u4E0B\uFF0C\u4EFB\u4F55\u7B54\u6848\u90FD\u50CF\u80CC\u53DB\u3002"], victoryText: ["\u4ED6\u4EEC\u6CA1\u6709\u8BF4\u51FA\u53E3\uFF0C\u4F46\u6218\u573A\u5DF2\u7ECF\u66FF\u4ED6\u4EEC\u56DE\u7B54\u3002"] },
    { id: "ch13", title: "13 \u53DB\u56FD\u6289\u62E9", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u51FB\u9000\u4E24\u56FD\u8FFD\u5175\uFF0C\u5E76\u9009\u62E9\u5012\u5411\u5357\u3001\u5317\u6216\u4E2D\u7ACB\u3002", victoryCondition: { type: "rout" }, map: "bridge", side: "joined", opening: ["\u6CA1\u6709\u4E2D\u7ACB\u7684\u65D7\u5E1C\uFF0C\u53EA\u6709\u613F\u610F\u4E3A\u4E2D\u7ACB\u6D41\u7684\u8840\u3002"], victoryText: ["\u9009\u62E9\u88AB\u5199\u5165\u4E16\u754C\u72B6\u6001\uFF0C\u76DF\u53CB\u5F00\u59CB\u8BA1\u7B97\u79BB\u961F\u4E0E\u7559\u4E0B\u7684\u4EE3\u4EF7\u3002"] },
    { id: "ch14", title: "14 \u65E7\u53CB\u4E3A\u654C", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u51FB\u8D25\u88AB\u6D17\u8111\u7684\u585E\u897F\u8389\u4E9A\uFF0C\u53EF\u89E6\u53D1\u529D\u964D\u4F0F\u7B14\u3002", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "village", side: "joined", opening: ["\u585E\u897F\u8389\u4E9A\u4E3E\u5251\u65F6\uFF0C\u773C\u795E\u50CF\u88AB\u64E6\u6389\u4E86\u4E00\u534A\u3002"], victoryText: ["\u65E7\u53CB\u6CA1\u6709\u9192\u6765\uFF0C\u4F46\u5979\u542C\u89C1\u4E86\u81EA\u5DF1\u7684\u540D\u5B57\u3002"] },
    { id: "ch15", title: "15 \u7EC7\u547D\u4F4E\u8BED", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u5728\u795E\u6BBF\u4E2D\u6491\u8FC7\u5B97\u5EA7\u7684\u4E09\u9636\u6BB5\u538B\u8FEB\u3002", victoryCondition: { type: "survive", turns: 3 }, map: "altar", side: "joined", opening: ["\u5B97\u5EA7\u8BF4\uFF1A\u4ECE\u5934\u5230\u5C3E\uFF0C\u90FD\u662F\u6211\u7684\u68CB\u5C40\u3002"], victoryText: ["\u795E\u4E0D\u662F\u7B54\u6848\uFF0C\u795E\u662F\u5E55\u540E\u9ED1\u624B\u3002"] },
    { id: "ch16", title: "16 \u4F17\u53DB\u4EB2\u79BB", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u5728\u961F\u4F0D\u91CD\u7EC4\u4E2D\u5B88\u4F4F\u64A4\u79BB\u70B9\u3002", victoryCondition: { type: "escape", x: 0, y: 9, unitDefIds: ["aldric"] }, map: "snow", side: "joined", opening: ["\u9009\u62E9\u5F00\u59CB\u6536\u8D26\u3002\u6709\u4EBA\u79BB\u961F\uFF0C\u6709\u4EBA\u7559\u4E0B\uFF0C\u4E5F\u6709\u4EBA\u6C89\u9ED8\u3002"], victoryText: ["\u961F\u4F0D\u53D8\u5C0F\u4E86\uFF0C\u4F46\u6BCF\u4E00\u6B65\u90FD\u66F4\u50CF\u81EA\u5DF1\u7684\u610F\u5FD7\u3002"] },
    { id: "ch17", title: "17 \u9F99\u810A\u8FDC\u5F81", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u7A7F\u8D8A\u9F99\u810A\u5C71\u8109\uFF0C\u5360\u9886\u796D\u575B\u5165\u53E3\u3002", victoryCondition: { type: "seize", x: 6, y: 4 }, map: "snow", side: "joined", opening: ["\u9F99\u810A\u5C71\u8109\u50CF\u4E00\u6761\u6B7B\u53BB\u7684\u795E\u6A2A\u5728\u5927\u9646\u4E2D\u592E\u3002"], victoryText: ["\u5C71\u98CE\u91CC\u4F20\u6765\u53E4\u9F99\u4F4E\u9E23\uFF0C\u50CF\u5728\u53EC\u56DE\u81EA\u5DF1\u7684\u8840\u3002"] },
    { id: "ch18", title: "18 \u89C9\u9192\u4EE3\u4EF7", act: "\u7B2C\u4E8C\u5E55\uFF1A\u771F\u76F8\u4E0E\u6491\u88C2", objective: "\u4F7F\u7528\u6216\u538B\u5236\u9F99\u75D5\u89C9\u9192\uFF0C\u963B\u6B62\u5931\u63A7\u3002", victoryCondition: { type: "survive", turns: 3 }, defeatConditions: [{ type: "protectUnit", unitDefIds: ["aldric", "elara"] }], map: "altar", side: "joined", opening: ["\u529B\u91CF\u7ED9\u51FA\u6377\u5F84\uFF0C\u4E5F\u5728\u7EC8\u70B9\u7D22\u8981\u7075\u9B42\u3002"], victoryText: ["\u9F99\u5316\u503C\u6210\u4E3A\u7ED3\u5C40\u7684\u503A\u3002"] },
    { id: "ch19", title: "19 \u5723\u90FD\u51B3\u6218", act: "\u7B2C\u4E09\u5E55\uFF1A\u732E\u796D\u4E0E\u6539\u547D", objective: "\u653B\u5165\u5723\u90FD\uFF0C\u51FB\u8D25\u7EC7\u547D\u5B97\u5EA7\u7684\u4EE3\u884C\u8005\u3002", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "village", side: "joined", opening: ["\u5723\u90FD\u7684\u5927\u95E8\u4E3A\u6218\u4E89\u655E\u5F00\uFF0C\u4E5F\u4E3A\u8C0E\u8A00\u655E\u5F00\u3002"], victoryText: ["\u5B97\u5EA7\u5012\u4E0B\u524D\u7B11\u4E86\uFF0C\u56E0\u4E3A\u5C01\u5370\u4ECD\u7136\u9700\u8981\u727A\u7272\u3002"] },
    { id: "ch20", title: "20 \u5C01\u5370\u771F\u76F8", act: "\u7B2C\u4E09\u5E55\uFF1A\u732E\u796D\u4E0E\u6539\u547D", objective: "\u5B88\u4F4F\u5C01\u5370\u6838\u5FC3\uFF0C\u8BFB\u53D6\u53E4\u9F99\u8BB0\u5FC6\u3002", victoryCondition: { type: "survive", turns: 3 }, map: "altar", side: "joined", opening: ["\u771F\u76F8\u7EC8\u4E8E\u5B8C\u6574\uFF1A\u5C01\u5370\u9700\u8981\u4E00\u540D\u9F99\u75D5\u8005\u4F5C\u4E3A\u6954\u5B50\u3002"], victoryText: ["\u6D3B\u4E0B\u53BB\u4E0E\u62EF\u6551\u4E16\u754C\uFF0C\u4E0D\u518D\u80FD\u540C\u65F6\u6210\u7ACB\u3002"] },
    { id: "ch21", title: "21 \u6700\u540E\u7684\u652F\u63F4", act: "\u7B2C\u4E09\u5E55\uFF1A\u732E\u796D\u4E0E\u6539\u547D", objective: "\u5168\u5458\u652F\u63F4\u4F1A\u8BDD\u6536\u675F\uFF0C\u62B5\u5FA1\u6700\u540E\u56F4\u527F\u3002", victoryCondition: { type: "rout" }, map: "bridge", side: "joined", opening: ["\u6BCF\u4E2A\u4EBA\u90FD\u5728\u9ECE\u660E\u524D\u8BF4\u51FA\u6700\u50CF\u9057\u8A00\u7684\u8BDD\u3002"], victoryText: ["\u7F81\u7ECA\u4E0D\u662F\u5956\u52B1\uFF0C\u662F\u9009\u62E9\u65F6\u624B\u4E0A\u7684\u91CD\u91CF\u3002"] },
    { id: "ch22", title: "22 \u795E\u6BBF\u4E4B\u95E8", act: "\u7B2C\u4E09\u5E55\uFF1A\u732E\u796D\u4E0E\u6539\u547D", objective: "\u7A81\u5165\u9F99\u795E\u5C01\u5370\u6838\u5FC3\uFF0C\u51FB\u7834\u95E8\u524D\u5B88\u536B\u3002", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "altar", side: "joined", opening: ["\u795E\u6BBF\u4E4B\u95E8\u6CA1\u6709\u9501\uFF0C\u56E0\u4E3A\u5B83\u4E00\u76F4\u5728\u7B49\u94A5\u5319\u957F\u5927\u3002"], victoryText: ["\u95E8\u5F00\u4E86\uFF0C\u4E16\u754C\u5B89\u9759\u5F97\u50CF\u5C4F\u4F4F\u547C\u5438\u3002"] },
    { id: "ch23", title: "23 \u53CC\u751F\u4E4B\u62E9", act: "\u7B2C\u4E09\u5E55\uFF1A\u732E\u796D\u4E0E\u6539\u547D", objective: "\u771F\u6B63\u4E92\u65A5\u7684\u7ED3\u5C40\u5206\u652F\uFF1A\u732E\u796D\u5144\u3001\u732E\u796D\u59B9\u6216\u5F11\u795E\u6539\u547D\u3002", victoryCondition: { type: "seize", x: 6, y: 4, unitDefIds: ["aldric", "elara"] }, map: "altar", side: "joined", opening: ["\u5BBF\u547D\u628A\u4E09\u6761\u8DEF\u6446\u5728\u9762\u524D\uFF0C\u6BCF\u4E00\u6761\u90FD\u8981\u7559\u4E0B\u4E9B\u4EC0\u4E48\u3002"], victoryText: ["\u9009\u62E9\u843D\u4E0B\uFF0C\u7ED3\u5C40\u5F00\u59CB\u3002"] },
    { id: "ch24", title: "24 \u7EC8\u5E55", act: "\u7B2C\u4E09\u5E55\uFF1A\u732E\u796D\u4E0E\u6539\u547D", objective: "\u6309\u7B2C 23 \u7AE0\u6289\u62E9\u8FDB\u5165\u5BF9\u5E94\u7ED3\u5C40\uFF0C\u51FB\u7834\u6700\u540E\u5F62\u6001\u3002", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "altar", side: "joined", opening: ["\u6700\u540E\u7684\u6218\u6597\u4E0D\u662F\u4E3A\u4E86\u8BC1\u660E\u8C01\u66F4\u5F3A\uFF0C\u800C\u662F\u8BC1\u660E\u547D\u8FD0\u5E76\u975E\u552F\u4E00\u4F5C\u8005\u3002"], victoryText: ["\u53CC\u751F\u7684\u6545\u4E8B\u5728\u8840\u4E0E\u5149\u4E4B\u95F4\u6536\u675F\u3002"] }
  ];
  var endingCatalog = [
    { id: "sacrifice_aldric", title: "\u727A\u7272\u5144", condition: "\u7B2C23\u7AE0\u9009\u62E9\u732E\u796D\u5144\u4E14\u5965\u5FB7\u91CC\u514B\u5B58\u6D3B", tone: "\u60B2\u58EE\uFF0C\u59B9\u80CC\u8D1F", text: ["\u5965\u5FB7\u91CC\u514B\u6210\u4E3A\u65B0\u7684\u5C01\u5370\u6954\u5B50\u3002\u827E\u62C9\u83C8\u5E26\u7740\u4ED6\u7684\u67AA\u79BB\u5F00\u5723\u90FD\u3002"] },
    { id: "sacrifice_elara", title: "\u727A\u7272\u59B9", condition: "\u7B2C23\u7AE0\u9009\u62E9\u732E\u796D\u59B9\u4E14\u827E\u62C9\u83C8\u5B58\u6D3B", tone: "\u60B2\u58EE\uFF0C\u5144\u80CC\u8D1F", text: ["\u827E\u62C9\u83C8\u5728\u9F99\u75D5\u5149\u4E2D\u6D88\u5931\u3002\u5965\u5FB7\u91CC\u514B\u7B2C\u4E00\u6B21\u8FDD\u6297\u795E\uFF0C\u5374\u6CA1\u80FD\u8FDD\u6297\u5931\u53BB\u3002"] },
    { id: "defy_god", title: "\u5F11\u795E\u6539\u547D", condition: "\u5168\u9F99\u75D5\u89C9\u9192\u7EBF\u8FBE\u6210\uFF0C\u9F99\u5316\u503C\u53D7\u63A7\uFF0C\u5173\u952E\u7F81\u7ECA\u8FBE S", tone: "\u53CD\u6297\u5BBF\u547D\uFF0C\u60E8\u80DC", text: ["\u53CC\u751F\u6CA1\u6709\u732E\u796D\u5F7C\u6B64\u3002\u4ED6\u4EEC\u628A\u5251\u6307\u5411\u7EC7\u547D\u795E\uFF0C\u8D62\u4E0B\u4E00\u6761\u6709\u4EE3\u4EF7\u7684\u81EA\u7531\u3002"] },
    { id: "dragonfall", title: "\u53CC\u53CC\u9F99\u5316", condition: "\u9F99\u5316\u503C\u8D85\u9608\u503C", tone: "\u9690\u85CF\u574F\u7ED3\u5C40", text: ["\u4E24\u679A\u5723\u75D5\u4E00\u8D77\u788E\u88C2\u3002\u9F99\u795E\u9192\u6765\uFF0C\u4E16\u754C\u7EC8\u4E8E\u6CA1\u6709\u4E86\u6218\u4E89\uFF0C\u4E5F\u6CA1\u6709\u4E86\u4EBA\u3002"] }
  ];
  var storyChapters = outlines.map((outline, index) => {
    const nextChapterId = index === outlines.length - 1 ? void 0 : outlines[index + 1].id;
    const choice = choiceFor(outline.id);
    const events = eventsFor(outline.id);
    const visits = visitsFor(outline.id);
    return {
      id: outline.id,
      title: outline.title,
      act: outline.act,
      objective: outline.objective,
      victoryCondition: outline.victoryCondition,
      ...outline.defeatConditions ? { defeatConditions: outline.defeatConditions } : {},
      victoryText: outline.victoryText,
      terrainLegend: legend,
      map: maps[outline.map],
      deployments: deploymentsFor(outline.side),
      ...events.length > 0 ? { events } : {},
      ...visits.length > 0 ? { visits } : {},
      opening: outline.opening,
      ...nextChapterId ? { nextChapterId } : {},
      ...choice ? { choice } : {}
    };
  });
  var fullChapterCatalog = [chapter01, ...storyChapters];
  function deploymentsFor(side) {
    if (side === "nordheim") {
      return [...nordheimAllies, ...soreinEnemies];
    }
    if (side === "joined") {
      return [...joinedAllies, ...churchEnemies];
    }
    if (side === "church") {
      return [...joinedAllies, ...churchEnemies];
    }
    return [...soreinAllies, ...nordheimEnemies];
  }
  function choiceFor(chapterId) {
    if (chapterId === "ch13") {
      return {
        id: "allegiance",
        prompt: "\u7B2C13\u7AE0\u53DB\u56FD\u6289\u62E9\uFF1A\u5012\u5411\u54EA\u4E00\u8FB9\uFF1F",
        options: [
          { text: "\u5012\u5411\u7D22\u96F7\u56E0\uFF0C\u4FDD\u4F4F\u5357\u5883\u6C11\u4F17", flag: "allegiance", value: 1 },
          { text: "\u5012\u5411\u8BFA\u5FB7\u6D77\u59C6\uFF0C\u5B88\u62A4\u53E4\u9F99\u4FE1\u4EF0", flag: "allegiance", value: 2 },
          { text: "\u4E2D\u7ACB\u9003\u4EA1\uFF0C\u8C01\u90FD\u4E0D\u732E\u796D", flag: "allegiance", value: 3 }
        ]
      };
    }
    if (chapterId === "ch23") {
      return {
        id: "ending_choice",
        prompt: "\u7B2C23\u7AE0\u53CC\u751F\u4E4B\u62E9\uFF1A\u5C01\u5370\u9700\u8981\u4EE3\u4EF7\u3002",
        options: [
          { text: "\u732E\u796D\u5965\u5FB7\u91CC\u514B", flag: "endingChoice", value: 1 },
          { text: "\u732E\u796D\u827E\u62C9\u83C8", flag: "endingChoice", value: 2 },
          { text: "\u62D2\u7EDD\u732E\u796D\uFF0C\u5F11\u795E\u6539\u547D", flag: "endingChoice", value: 3 }
        ]
      };
    }
    return void 0;
  }
  function eventsFor(chapterId) {
    if (chapterId === "ch03") {
      return [
        {
          id: "north_bridge_wave",
          type: "reinforcement",
          turn: 2,
          phase: "enemyStart",
          ambush: true,
          telegraph: "\u6797\u7EBF\u5916\u54CD\u8D77\u53F7\u89D2\uFF0C\u5317\u5883\u63F4\u519B\u4E0B\u56DE\u5408\u4F1A\u4ECE\u897F\u5317\u5C71\u9053\u538B\u4E0A\u3002",
          message: "\u5317\u5883\u63F4\u519B\u4ECE\u897F\u5317\u5C71\u9053\u6740\u51FA\u3002",
          deployments: [
            { unitDefId: "nord_raider", instanceId: "ch03_wave_raider", team: "enemy", x: 0, y: 1, weaponId: "iron_axe" },
            { unitDefId: "nord_scout", instanceId: "ch03_wave_scout", team: "enemy", x: 1, y: 1, weaponId: "iron_sword" }
          ]
        }
      ];
    }
    if (chapterId === "ch12") {
      return [
        {
          id: "church_pincer",
          type: "reinforcement",
          turn: 2,
          phase: "enemyStart",
          ambush: true,
          telegraph: "\u96EA\u96FE\u91CC\u4F20\u6765\u5723\u949F\u56DE\u58F0\uFF0C\u6559\u4F1A\u4F0F\u5175\u4E0B\u56DE\u5408\u4F1A\u4ECE\u4E1C\u5317\u5305\u6284\u3002",
          message: "\u6559\u4F1A\u4F0F\u5175\u6495\u5F00\u96EA\u96FE\uFF0C\u622A\u65AD\u9000\u8DEF\u3002",
          deployments: [
            { unitDefId: "nord_raider", instanceId: "ch12_zealot_wave", team: "enemy", x: 13, y: 0, weaponId: "hammer" },
            { unitDefId: "ice_mage", instanceId: "ch12_oracle_wave", team: "enemy", x: 12, y: 0, weaponId: "thunder" }
          ]
        }
      ];
    }
    if (chapterId === "ch15") {
      return [
        {
          id: "pontiff_second_phase",
          type: "reinforcement",
          turn: 2,
          phase: "enemyStart",
          telegraph: "\u796D\u575B\u7EB9\u8DEF\u8F6C\u4E3A\u767D\u91D1\u8272\uFF0C\u4E0B\u56DE\u5408\u5B97\u5EA7\u4F1A\u53EC\u6765\u7B2C\u4E8C\u9636\u6BB5\u5B88\u536B\u3002",
          message: "\u7EC7\u547D\u5B88\u536B\u54CD\u5E94\u796D\u575B\uFF0C\u6218\u7EBF\u5347\u7EA7\u3002",
          deployments: [
            { unitDefId: "valentin", instanceId: "ch15_templar_phase2", team: "enemy", x: 8, y: 4, weaponId: "iron_lance" },
            { unitDefId: "ice_mage", instanceId: "ch15_oracle_phase2", team: "enemy", x: 9, y: 5, weaponId: "thunder" }
          ]
        },
        {
          id: "pontiff_third_phase",
          type: "reinforcement",
          turn: 3,
          phase: "enemyStart",
          telegraph: "\u796D\u575B\u88C2\u7F1D\u55B7\u51FA\u9F99\u75D5\u5149\uFF0C\u4E0B\u56DE\u5408\u5B97\u5EA7\u4F1A\u538B\u5165\u6700\u7EC8\u9636\u6BB5\u3002",
          message: "\u9F99\u75D5\u5149\u66B4\u6DA8\uFF0C\u6700\u7EC8\u5B88\u536B\u903C\u8FD1\u796D\u575B\u3002",
          deployments: [
            { unitDefId: "mirelle", instanceId: "ch15_mage_phase3", team: "enemy", x: 5, y: 6, weaponId: "fire" },
            { unitDefId: "rowan", instanceId: "ch15_bow_phase3", team: "enemy", x: 8, y: 6, weaponId: "short_bow" }
          ]
        }
      ];
    }
    if (chapterId === "ch20") {
      return [
        {
          id: "seal_core_guard",
          type: "reinforcement",
          turn: 3,
          phase: "enemyStart",
          telegraph: "\u5C01\u5370\u6838\u5FC3\u5F00\u59CB\u9006\u8F6C\uFF0C\u4E0B\u56DE\u5408\u53E4\u9F99\u8BB0\u5FC6\u4F1A\u5524\u9192\u5B88\u536B\u3002",
          message: "\u53E4\u9F99\u8BB0\u5FC6\u5316\u4F5C\u5B88\u536B\uFF0C\u903C\u8FEB\u961F\u4F0D\u5B88\u4F4F\u6838\u5FC3\u3002",
          deployments: [
            { unitDefId: "lost_dragonkin", instanceId: "ch20_memory_dragon", team: "enemy", x: 6, y: 4, weaponId: "wyrmslayer" },
            { unitDefId: "dragon_elder", instanceId: "ch20_memory_elder", team: "enemy", x: 7, y: 5, weaponId: "fire" }
          ]
        }
      ];
    }
    return [];
  }
  function visitsFor(chapterId) {
    if (chapterId === "ch02") {
      return [
        {
          id: "refugee_cellar",
          x: 2,
          y: 2,
          label: "\u7126\u571F\u6751\u5730\u7A96",
          message: "\u96BE\u6C11\u4ECE\u5730\u7A96\u9012\u51FA\u94B1\u888B\uFF1A\u62FF\u53BB\u4FEE\u6B66\u5668\uFF0C\u522B\u8BA9\u4E0B\u4E00\u4E2A\u6751\u5B50\u4E5F\u70E7\u8D77\u6765\u3002",
          gold: 300,
          flag: "savedRefugeeCellar",
          value: true
        }
      ];
    }
    if (chapterId === "ch10") {
      return [
        {
          id: "archive_contact",
          x: 5,
          y: 0,
          label: "\u6863\u6848\u9986\u5BC6\u5BA4",
          message: "\u6863\u6848\u7BA1\u7406\u5458\u7559\u4E0B\u77ED\u5F13\u548C\u5BC6\u8BED\uFF1A\u6559\u4F1A\u5728\u8BB0\u5F55\u53CC\u751F\uFF0C\u4E5F\u5728\u62B9\u6389\u8BC1\u4EBA\u3002",
          weaponId: "short_bow",
          weaponCount: 1,
          flag: "archiveContactHelped",
          value: true
        }
      ];
    }
    if (chapterId === "ch14") {
      return [
        {
          id: "cecilia_memory",
          x: 2,
          y: 2,
          label: "\u65E7\u53CB\u6C11\u5C45",
          message: "\u5C4B\u5185\u8FD8\u6302\u7740\u585E\u897F\u8389\u4E9A\u65E7\u65E5\u7684\u8A93\u8BCD\u3002\u5965\u5FB7\u91CC\u514B\u8BB0\u4F4F\u4E86\u80FD\u5524\u9192\u5979\u7684\u8BDD\u3002",
          gold: 200,
          flag: "ceciliaMemoryFound",
          value: true
        }
      ];
    }
    return [];
  }

  // src/data/expandedContent.ts
  var infantry = { hp: 70, str: 45, mag: 5, skill: 55, spd: 55, luck: 40, def: 30, res: 20 };
  var cavalry = { hp: 75, str: 50, mag: 5, skill: 45, spd: 45, luck: 35, def: 35, res: 15 };
  var flying = { hp: 60, str: 40, mag: 10, skill: 55, spd: 60, luck: 45, def: 20, res: 30 };
  var armor = { hp: 90, str: 55, mag: 0, skill: 35, spd: 20, luck: 25, def: 55, res: 15 };
  var mage = { hp: 55, str: 5, mag: 55, skill: 45, spd: 45, luck: 30, def: 15, res: 40 };
  var archer = { hp: 60, str: 45, mag: 5, skill: 55, spd: 50, luck: 35, def: 25, res: 20 };
  var healer = { hp: 55, str: 5, mag: 45, skill: 40, spd: 45, luck: 45, def: 15, res: 40 };
  var dragon = { hp: 80, str: 55, mag: 45, skill: 55, spd: 55, luck: 45, def: 40, res: 40 };
  var extraClassCatalog = [
    { id: "wyvern_lord", name: "\u9F99\u9A91\u5C06", moveKind: "fly", tags: ["flying", "cavalry"], weaponKinds: ["lance", "axe"], skillIds: ["dive"] },
    { id: "sky_knight", name: "\u5929\u7A7A\u9A91\u58EB", moveKind: "fly", tags: ["flying"], weaponKinds: ["lance"] },
    { id: "falcon_knight", name: "\u96BC\u9A91", moveKind: "fly", tags: ["flying"], weaponKinds: ["sword", "lance"], skillIds: ["falcon_mercy"] },
    { id: "temple_guard", name: "\u5723\u6BBF\u536B", moveKind: "foot", tags: ["armored"], weaponKinds: ["lance", "staff"], skillIds: ["shield_wall"] },
    { id: "archmage", name: "\u5927\u6CD5\u5E08", moveKind: "foot", tags: ["mage"], weaponKinds: ["fire", "ice", "thunder"], skillIds: ["archmage_focus"] },
    { id: "ranger", name: "\u6E38\u4FA0", moveKind: "foot", tags: ["archer", "scout"], weaponKinds: ["bow", "sword"], skillIds: ["ranger_skirmish"] },
    { id: "saint", name: "\u5723\u5973", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"], skillIds: ["saint_refresh"] },
    { id: "thief", name: "\u795E\u5077", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword", "bow"], skillIds: ["trailblazer"] },
    { id: "assassin", name: "\u523A\u5BA2", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword"], skillIds: ["assassin_lethality"] },
    { id: "wyvern_rider", name: "\u9F99\u9A91\u5175", moveKind: "fly", tags: ["flying", "cavalry"], weaponKinds: ["lance"] },
    { id: "warrior", name: "\u52C7\u58EB", moveKind: "foot", tags: ["infantry"], weaponKinds: ["axe", "bow"] },
    { id: "war_cleric", name: "\u6218\u6597\u4FEE\u58EB", moveKind: "foot", tags: ["healer", "infantry"], weaponKinds: ["staff", "axe"] },
    { id: "dancer", name: "\u6218\u9F13\u821E\u8005", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"] },
    { id: "ballista", name: "\u9B54\u5BFC\u70AE", moveKind: "foot", tags: ["siege", "archer"], weaponKinds: ["bow", "thunder"], skillIds: ["ballista_lockon"] },
    { id: "valkyrie", name: "\u5973\u6B66\u795E", moveKind: "fly", tags: ["flying", "mage"], weaponKinds: ["lance", "ice", "thunder"] },
    { id: "black_knight", name: "\u9ED1\u9A91\u58EB", moveKind: "horse", tags: ["cavalry", "armored"], weaponKinds: ["sword", "lance"], skillIds: ["black_knight_dread"] }
  ];
  var passiveSkills = [
    { id: "forest_guard", name: "\u68EE\u536B", kind: "passive", trigger: "onDefend", effect: ["terrainForest:def+2"], condition: "\u68EE\u6797", description: "\u5728\u68EE\u6797\u4E2D\u989D\u5916\u83B7\u5F97\u9632\u5FA1\u3002" },
    { id: "anti_arrow_stance", name: "\u907F\u77E2\u59FF\u6001", kind: "passive", trigger: "onDefend", effect: ["avoidVsBow:+20"], description: "\u53D7\u5230\u5F13\u653B\u51FB\u65F6\u56DE\u907F\u63D0\u5347\u3002" },
    { id: "linebreaker", name: "\u7834\u9635", kind: "passive", trigger: "onAttack", effect: ["bonusVsArmored:+3"], description: "\u5BF9\u91CD\u7532\u989D\u5916\u9020\u6210\u4F24\u5BB3\u3002" },
    { id: "mercy", name: "\u6148\u60B2", kind: "passive", trigger: "onAttack", effect: ["nonlethal"], description: "\u51FB\u5012\u53EF\u529D\u964D\u5355\u4F4D\u65F6\u4FDD\u7559\u64A4\u9000\u3002" },
    { id: "snowstep", name: "\u96EA\u884C", kind: "passive", trigger: "onMove", effect: ["ignoreSnowSlow"], description: "\u96EA\u5730\u548C\u5C71\u5730\u79FB\u52A8\u60E9\u7F5A\u964D\u4F4E\u3002" },
    { id: "battle_prayer", name: "\u6218\u7977", kind: "passive", trigger: "onTurnStart", effect: ["adjacentHit:+5"], description: "\u76F8\u90BB\u53CB\u519B\u547D\u4E2D\u5C0F\u5E45\u63D0\u5347\u3002" },
    { id: "watchful", name: "\u8B66\u6212", kind: "passive", trigger: "onEnemyPhase", effect: ["cannotBeAmbushed"], description: "\u4E0D\u4F1A\u88AB\u4F0F\u51FB\u589E\u63F4\u53D6\u5F97\u5148\u624B\u3002" },
    { id: "dragon_resonance", name: "\u9F99\u8109\u5171\u632F", kind: "passive", trigger: "onStigma", effect: ["bondGain:+2"], condition: "\u9F99\u88D4", description: "\u9F99\u75D5\u76F8\u5173\u884C\u52A8\u63D0\u9AD8\u7F81\u7ECA\u6536\u76CA\u3002" },
    { id: "steady_hand", name: "\u7A33\u624B", kind: "passive", trigger: "onAttack", effect: ["hitFloor:60"], description: "\u4E3B\u52A8\u653B\u51FB\u663E\u793A\u547D\u4E2D\u4E0D\u4F4E\u4E8E 60%\u3002" },
    { id: "last_stand", name: "\u80CC\u6C34", kind: "passive", trigger: "onDefend", effect: ["defRes:+3"], condition: "HP<30%", description: "\u4F4E\u8840\u91CF\u65F6\u9632\u5FA1\u4E0E\u9B54\u9632\u63D0\u5347\u3002" },
    { id: "quickdraw", name: "\u901F\u5C04", kind: "passive", trigger: "onAttack", effect: ["bowFollowupThreshold:-1"], condition: "\u5F13", description: "\u5F13\u5175\u66F4\u5BB9\u6613\u8FFD\u51FB\u3002" },
    { id: "mage_slayer", name: "\u7834\u6CD5", kind: "passive", trigger: "onAttack", effect: ["bonusVsMage:+3"], description: "\u5BF9\u6CD5\u5E08\u989D\u5916\u9020\u6210\u4F24\u5BB3\u3002" },
    { id: "shield_wall", name: "\u76FE\u5899", kind: "passive", trigger: "bondAdjacent", effect: ["adjacentDef:+2"], condition: "\u91CD\u7532", description: "\u76F8\u90BB\u53CB\u519B\u83B7\u5F97\u9632\u5FA1\u3002" },
    { id: "trailblazer", name: "\u5F00\u8DEF", kind: "passive", trigger: "onMove", effect: ["allyMoveThrough"], description: "\u53CB\u519B\u53EF\u7A7F\u8FC7\u81EA\u5DF1\u6240\u5728\u683C\u3002" },
    { id: "holy_focus", name: "\u5723\u5B9A", kind: "passive", trigger: "onHeal", effect: ["healCrit"], description: "\u6CBB\u7597\u65F6\u6709\u6982\u7387\u989D\u5916\u56DE\u590D\u3002" },
    { id: "blood_memory", name: "\u8840\u5FC6", kind: "passive", trigger: "onDefeatAlly", effect: ["taintToPower"], condition: "\u9F99\u88D4", description: "\u53CB\u519B\u5012\u4E0B\u4F1A\u5F3A\u5316\u4E0B\u4E00\u6B21\u9F99\u75D5\u884C\u52A8\u3002" }
  ];
  var activeSkills = [
    { id: "rally_defense", name: "\u9632\u5FA1\u53F7\u4EE4", kind: "active", trigger: "manual", effect: ["area:adjacent", "def:+2"], cost: "\u6BCF\u62182\u6B21", description: "\u63D0\u5347\u90BB\u8FD1\u53CB\u519B\u9632\u5FA1\u3002" },
    { id: "rally_speed", name: "\u75BE\u901F\u53F7\u4EE4", kind: "active", trigger: "manual", effect: ["area:adjacent", "spd:+2"], cost: "\u6BCF\u62182\u6B21", description: "\u63D0\u5347\u90BB\u8FD1\u53CB\u519B\u901F\u5EA6\u3002" },
    { id: "rescue_pull", name: "\u6551\u63F4\u7275\u5F15", kind: "active", trigger: "manual", effect: ["forceMove:allyPull"], cost: "\u6BCF\u62181\u6B21", description: "\u628A\u53CB\u519B\u62C9\u5230\u8EAB\u8FB9\u3002" },
    { id: "swap", name: "\u6362\u4F4D", kind: "active", trigger: "manual", effect: ["swapPosition"], description: "\u4E0E\u76F8\u90BB\u53CB\u519B\u4EA4\u6362\u4F4D\u7F6E\u3002" },
    { id: "shove", name: "\u63A8\u51FB", kind: "active", trigger: "manual", effect: ["forceMove:push"], description: "\u63A8\u52A8\u76EE\u6807\u4E00\u683C\u3002" },
    { id: "smite", name: "\u731B\u63A8", kind: "active", trigger: "manual", effect: ["forceMove:push2"], cost: "\u6BCF\u62181\u6B21", description: "\u63A8\u52A8\u76EE\u6807\u4E24\u683C\u3002" },
    { id: "mark_target", name: "\u6807\u8BB0\u76EE\u6807", kind: "active", trigger: "manual", effect: ["targetDebuff:avoid-15"], description: "\u964D\u4F4E\u76EE\u6807\u56DE\u907F\uFF0C\u65B9\u4FBF\u96C6\u706B\u3002" },
    { id: "silence", name: "\u5C01\u6280", kind: "active", trigger: "manual", effect: ["status:silence"], cost: "\u6BCF\u62181\u6B21", description: "\u5C01\u9501\u76EE\u6807\u4E3B\u52A8\u6280\u80FD\u4E00\u56DE\u5408\u3002" },
    { id: "barrier", name: "\u9B54\u9632\u5C4F\u969C", kind: "active", trigger: "manual", effect: ["res:+5"], cost: "\u6BCF\u62182\u6B21", description: "\u63D0\u9AD8\u53CB\u519B\u9B54\u9632\u3002" },
    { id: "fortify", name: "\u7FA4\u4F53\u6CBB\u7597", kind: "active", trigger: "manual", effect: ["heal:allAdjacent"], cost: "\u6BCF\u62181\u6B21", description: "\u6CBB\u7597\u76F8\u90BB\u53CB\u519B\u3002" },
    { id: "piercing_shot", name: "\u8D2F\u901A\u5C04\u51FB", kind: "active", trigger: "manual", effect: ["lineDamage"], cost: "\u6BCF\u62181\u6B21", description: "\u6CBF\u76F4\u7EBF\u5C04\u51FB\u591A\u4E2A\u654C\u4EBA\u3002" },
    { id: "meteor", name: "\u9668\u661F", kind: "active", trigger: "manual", effect: ["range:4", "fireDamage"], cost: "\u6BCF\u62181\u6B21", description: "\u8FDC\u8DDD\u79BB\u706B\u7130\u6253\u51FB\u3002" },
    { id: "freeze_field", name: "\u51B0\u5C01\u9635", kind: "active", trigger: "manual", effect: ["area:slow"], cost: "\u6BCF\u62181\u6B21", description: "\u964D\u4F4E\u8303\u56F4\u5185\u654C\u4EBA\u79FB\u52A8\u3002" }
  ];
  var classSkills = [
    { id: "paladin_canto", name: "\u5723\u9A91\xB7\u518D\u79FB\u52A8", kind: "class", trigger: "afterAction", effect: ["moveRemaining"], condition: "\u5723\u9A91\u58EB", description: "\u884C\u52A8\u540E\u53EF\u4F7F\u7528\u5269\u4F59\u79FB\u52A8\u529B\u3002" },
    { id: "hero_dual_wield", name: "\u52C7\u8005\xB7\u53CC\u6301", kind: "class", trigger: "always", effect: ["equip:sword,axe"], condition: "\u52C7\u8005", description: "\u5251\u65A7\u53CC\u6301\u5E76\u964D\u4F4E\u6362\u6B66\u5668\u6210\u672C\u3002" },
    { id: "falcon_mercy", name: "\u96BC\u9A91\xB7\u6551\u62A4", kind: "class", trigger: "manual", effect: ["carryAlly"], condition: "\u96BC\u9A91", description: "\u53EF\u5E26\u79BB\u76F8\u90BB\u53CB\u519B\u3002" },
    { id: "archmage_focus", name: "\u5927\u6CD5\u5E08\xB7\u805A\u7126", kind: "class", trigger: "onAttack", effect: ["singleSchoolMight:+3"], condition: "\u5927\u6CD5\u5E08", description: "\u5355\u7CFB\u9B54\u6CD5\u5A01\u529B\u63D0\u9AD8\u3002" },
    { id: "ranger_skirmish", name: "\u6E38\u4FA0\xB7\u6E38\u51FB", kind: "class", trigger: "afterAttack", effect: ["stepBack"], condition: "\u6E38\u4FA0", description: "\u653B\u51FB\u540E\u540E\u64A4\u4E00\u683C\u3002" },
    { id: "saint_refresh", name: "\u5723\u5973\xB7\u9F13\u821E", kind: "class", trigger: "manual", effect: ["refreshAlly"], condition: "\u5723\u5973", description: "\u8BA9\u76F8\u90BB\u53CB\u519B\u518D\u6B21\u884C\u52A8\u4E00\u6B21\u3002" },
    { id: "assassin_lethality", name: "\u523A\u5BA2\xB7\u5FC5\u6740", kind: "class", trigger: "onCrit", effect: ["lethality"], condition: "\u523A\u5BA2", description: "\u66B4\u51FB\u6709\u6982\u7387\u76F4\u63A5\u51FB\u5012\u76EE\u6807\u3002" },
    { id: "ballista_lockon", name: "\u9B54\u5BFC\u70AE\xB7\u9501\u5B9A", kind: "class", trigger: "onAttack", effect: ["ignoreRangePenalty"], condition: "\u9B54\u5BFC\u70AE", description: "\u8D85\u8FDC\u7A0B\u653B\u51FB\u4E0D\u5403\u8DDD\u79BB\u60E9\u7F5A\u3002" },
    { id: "black_knight_dread", name: "\u9ED1\u9A91\xB7\u5A01\u538B", kind: "class", trigger: "aura", effect: ["enemyHit:-10"], condition: "\u9ED1\u9A91\u58EB", description: "\u964D\u4F4E\u5468\u56F4\u654C\u4EBA\u547D\u4E2D\u3002" }
  ];
  var bondSkills = [
    { id: "feint_snare", name: "\u4F6F\u653B\u7275\u5236", kind: "bond", trigger: "bondAdjacent", effect: ["targetAvoid:-10"], condition: "\u6BD4\u7EA6\u6069\xD7\u5362\u5361 B", description: "\u559C\u5267\u642D\u6863\u7275\u5236\u654C\u4EBA\u3002" },
    { id: "absolution_light", name: "\u5FCF\u6094\u4E4B\u5149", kind: "bond", trigger: "bondAdjacent", effect: ["recruitCecilia"], condition: "\u585E\u897F\u8389\u4E9A\xD7\u5965\u5FB7\u91CC\u514B A", description: "\u63A8\u52A8\u65E7\u53CB\u529D\u8D4E\u7EBF\u3002" },
    { id: "sister_guard", name: "\u96EA\u8A93\u62A4\u536B", kind: "bond", trigger: "allyDefended", effect: ["guardElara"], condition: "\u827E\u62C9\u83C8\xD7\u5E0C\u683C\u9732\u6069 B", description: "\u66FF\u827E\u62C9\u83C8\u627F\u53D7\u4E00\u6B21\u653B\u51FB\u3002" },
    { id: "forbidden_vow", name: "\u7981\u8A93\u5171\u9E23", kind: "bond", trigger: "bondAdjacent", effect: ["stigmaCostDown"], condition: "\u53CC\u751F S", description: "\u771F\u7ED3\u5C40\u8DEF\u7EBF\u964D\u4F4E\u9F99\u75D5\u4EE3\u4EF7\u3002" }
  ];
  var stigmaSkills = [
    { id: "stigma_seal", name: "\u9F99\u75D5\u5C01\u5370", kind: "stigma", trigger: "manual", effect: ["taint:-1", "selfDamage"], cost: "\u727A\u7272 HP", condition: "\u5723\u75D5\u4F7F", description: "\u4EE5\u751F\u547D\u538B\u4F4E\u9F99\u5316\u503C\u3002" },
    { id: "stigma_roar", name: "\u9F99\u543C", kind: "stigma", trigger: "manual", effect: ["areaFear"], cost: "\u9F99\u5316\u503C +1", condition: "\u9F99\u738B", description: "\u9707\u6151\u8303\u56F4\u654C\u4EBA\u5E76\u63A8\u5F00\u3002" }
  ];
  var extraSkillCatalog = [...passiveSkills, ...activeSkills, ...classSkills, ...bondSkills, ...stigmaSkills];
  var extraUnitCatalog = [
    { id: "temple_captain", name: "\u5723\u6BBF\u536B\u961F\u957F", faction: "sorein", classId: "temple_guard", level: 4, baseStats: { hp: 29, str: 10, mag: 6, skill: 9, spd: 6, luck: 6, def: 12, res: 8, move: 4, con: 11 }, growths: armor, weaponIds: ["iron_lance", "heal_staff"], skillIds: ["shield_wall"] },
    { id: "lucian", name: "\u53CC\u5B50\u9A91\u58EB\xB7\u5362\u4FEE\u5B89", faction: "sorein", classId: "lance_cavalier", level: 2, baseStats: { hp: 24, str: 9, mag: 1, skill: 8, spd: 9, luck: 6, def: 7, res: 2, move: 7, con: 8 }, growths: cavalry, weaponIds: ["iron_lance"], skillIds: ["charge"] },
    { id: "livia", name: "\u53CC\u5B50\u9A91\u58EB\xB7\u8389\u8587\u5A05", faction: "sorein", classId: "lance_cavalier", level: 2, baseStats: { hp: 23, str: 8, mag: 2, skill: 10, spd: 10, luck: 8, def: 6, res: 3, move: 7, con: 7 }, growths: cavalry, weaponIds: ["iron_sword"], skillIds: ["rally_speed"] },
    { id: "penitent_knight", name: "\u5FCF\u6094\u9A91\u58EB", faction: "sorein", classId: "paladin", level: 6, baseStats: { hp: 31, str: 12, mag: 3, skill: 11, spd: 10, luck: 4, def: 10, res: 5, move: 8, con: 9 }, growths: cavalry, weaponIds: ["iron_lance", "wyrmslayer"], skillIds: ["paladin_canto"] },
    { id: "court_mage", name: "\u5BAB\u5EF7\u6CD5\u5E08", faction: "sorein", classId: "mage", level: 3, baseStats: { hp: 20, str: 1, mag: 11, skill: 10, spd: 7, luck: 5, def: 3, res: 9, move: 5, con: 5 }, growths: mage, weaponIds: ["fire", "thunder"], skillIds: ["meteor"] },
    { id: "old_bishop", name: "\u8001\u4E3B\u6559", faction: "sorein", classId: "bishop", level: 7, baseStats: { hp: 24, str: 2, mag: 12, skill: 10, spd: 7, luck: 10, def: 4, res: 13, move: 5, con: 6 }, growths: healer, weaponIds: ["heal_staff", "fire"], skillIds: ["barrier"] },
    { id: "retired_sniper", name: "\u9000\u5F79\u72D9\u51FB\u624B", faction: "sorein", classId: "sniper", level: 6, baseStats: { hp: 26, str: 11, mag: 1, skill: 15, spd: 10, luck: 7, def: 6, res: 3, move: 5, con: 7 }, growths: archer, weaponIds: ["short_bow"], skillIds: ["cloud_piercer"] },
    { id: "wanderer_sword", name: "\u6D41\u6D6A\u5251\u5BA2", faction: "sorein", classId: "swordmaster", level: 5, baseStats: { hp: 25, str: 10, mag: 1, skill: 14, spd: 15, luck: 8, def: 5, res: 4, move: 6, con: 7 }, growths: infantry, weaponIds: ["iron_sword"], skillIds: ["iaijutsu"] },
    { id: "frost_shaman", name: "\u96F7\u7CFB\u8428\u6EE1", faction: "nordheim", classId: "mage", level: 3, baseStats: { hp: 20, str: 1, mag: 12, skill: 9, spd: 9, luck: 5, def: 3, res: 9, move: 5, con: 5 }, growths: mage, weaponIds: ["thunder"], skillIds: ["freeze_field"] },
    { id: "eagle_rider", name: "\u9A6F\u9E70\u98DE\u5175", faction: "nordheim", classId: "pegasus", level: 2, baseStats: { hp: 22, str: 8, mag: 3, skill: 11, spd: 13, luck: 7, def: 4, res: 7, move: 7, con: 6 }, growths: flying, weaponIds: ["iron_lance"], skillIds: ["anti_arrow_stance"] },
    { id: "tribal_warrior", name: "\u90E8\u65CF\u52C7\u58EB", faction: "nordheim", classId: "warrior", level: 4, baseStats: { hp: 32, str: 13, mag: 0, skill: 9, spd: 8, luck: 5, def: 8, res: 2, move: 5, con: 11 }, growths: infantry, weaponIds: ["iron_axe", "short_bow"], skillIds: ["last_stand"] },
    { id: "yrsa", name: "\u5973\u6B66\u795E\u5019\u8865\xB7\u4F0A\u5C14\u838E", faction: "nordheim", classId: "valkyrie", level: 4, baseStats: { hp: 24, str: 8, mag: 9, skill: 12, spd: 13, luck: 8, def: 5, res: 9, move: 7, con: 7 }, growths: flying, weaponIds: ["iron_lance", "ice"], skillIds: ["sister_guard"] },
    { id: "runa", name: "\u5973\u6B66\u795E\u5019\u8865\xB7\u9732\u5A1C", faction: "nordheim", classId: "valkyrie", level: 4, baseStats: { hp: 23, str: 7, mag: 10, skill: 11, spd: 14, luck: 9, def: 4, res: 10, move: 7, con: 6 }, growths: flying, weaponIds: ["iron_lance", "thunder"], skillIds: ["rally_speed"] },
    { id: "dragon_elder", name: "\u9F99\u88D4\u957F\u8001", faction: "nordheim", classId: "stigma_bearer", level: 8, baseStats: { hp: 29, str: 8, mag: 13, skill: 12, spd: 8, luck: 9, def: 8, res: 12, move: 5, con: 8 }, growths: dragon, weaponIds: ["fire", "heal_staff"], skillIds: ["stigma_seal"] },
    { id: "snow_ranger", name: "\u96EA\u539F\u6E38\u4FA0\xB7\u51EF\u5C14", faction: "nordheim", classId: "ranger", level: 3, baseStats: { hp: 23, str: 9, mag: 1, skill: 12, spd: 12, luck: 7, def: 5, res: 3, move: 6, con: 7 }, growths: archer, weaponIds: ["short_bow", "iron_sword"], skillIds: ["ranger_skirmish"] },
    { id: "war_drummer", name: "\u6218\u9F13\u821E\u8005", faction: "nordheim", classId: "dancer", level: 2, baseStats: { hp: 21, str: 3, mag: 7, skill: 8, spd: 11, luck: 11, def: 3, res: 7, move: 5, con: 5 }, growths: healer, weaponIds: ["heal_staff"], skillIds: ["saint_refresh"] },
    { id: "defector_paladin", name: "\u53DB\u9003\u5723\u9A91", faction: "nordheim", classId: "paladin", level: 5, baseStats: { hp: 30, str: 11, mag: 2, skill: 10, spd: 10, luck: 5, def: 9, res: 5, move: 8, con: 9 }, growths: cavalry, weaponIds: ["iron_lance", "horseslayer"], skillIds: ["paladin_canto"] },
    { id: "lost_dragonkin", name: "\u5931\u5FC6\u9F99\u88D4", faction: "nordheim", classId: "dragon_king", level: 6, baseStats: { hp: 30, str: 13, mag: 9, skill: 11, spd: 10, luck: 4, def: 10, res: 8, move: 5, con: 9 }, growths: dragon, weaponIds: ["wyrmslayer", "fire"], skillIds: ["stigma_roar"] },
    { id: "luca", name: "\u5362\u5361", faction: "neutral", classId: "ranger", level: 3, baseStats: { hp: 22, str: 8, mag: 1, skill: 13, spd: 12, luck: 10, def: 4, res: 3, move: 6, con: 6 }, growths: archer, weaponIds: ["short_bow", "iron_sword"], skillIds: ["feint_snare"] },
    { id: "mercenary_captain", name: "\u4F63\u5175\u56E2\u957F", faction: "neutral", classId: "hero", level: 6, baseStats: { hp: 31, str: 12, mag: 1, skill: 12, spd: 11, luck: 7, def: 8, res: 4, move: 6, con: 9 }, growths: infantry, weaponIds: ["iron_sword", "iron_axe"], skillIds: ["hero_dual_wield"] },
    { id: "hermit_sage", name: "\u9690\u5C45\u8D24\u8005", faction: "neutral", classId: "sage", level: 8, baseStats: { hp: 23, str: 1, mag: 14, skill: 14, spd: 9, luck: 8, def: 4, res: 14, move: 5, con: 6 }, growths: mage, weaponIds: ["fire", "ice", "thunder"], skillIds: ["triune_sage"] },
    { id: "penitent_judge", name: "\u8D4E\u7F6A\u5BA1\u5224\u5B98", faction: "church", classId: "war_cleric", level: 6, baseStats: { hp: 28, str: 9, mag: 9, skill: 10, spd: 8, luck: 4, def: 8, res: 10, move: 5, con: 8 }, growths: healer, weaponIds: ["heal_staff", "hammer"], skillIds: ["absolution_light"] },
    { id: "mysterious_black_knight", name: "\u795E\u79D8\u9ED1\u9A91\u58EB", faction: "neutral", classId: "black_knight", level: 10, baseStats: { hp: 34, str: 14, mag: 4, skill: 13, spd: 11, luck: 3, def: 14, res: 7, move: 7, con: 12 }, growths: armor, weaponIds: ["iron_sword", "iron_lance"], skillIds: ["black_knight_dread"] }
  ];
  var supportPairCatalog = [
    {
      id: "aldric_elara",
      units: ["aldric", "elara"],
      theme: "\u53CC\u751F\u5BBF\u547D/\u7981\u5FCC",
      unlockSkillId: "twin_pincer",
      unlockRank: "A",
      ranks: ["C", "B", "A", "S"],
      conversations: [
        {
          rank: "C",
          effect: "\u89E3\u9501\u8A93\u7EA6\u5171\u9E23\u96CF\u5F62\uFF0C\u8BB0\u5F55\u53CC\u751F\u76F4\u89C9\u3002",
          lines: [
            "\u827E\u62C9\u83C8\uFF1A\u4F60\u4EEC\u5357\u65B9\u4EBA\u6253\u4ED7\u603B\u62FF\u8154\u4F5C\u52BF\u3002\u521A\u624D\u90A3\u4E00\u5251\uFF0C\u4F60\u660E\u660E\u53EF\u4EE5\u53D6\u6211\u6027\u547D\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u6211\u4E0D\u77E5\u9053\u3002\u53EA\u662F\u90A3\u4E00\u77AC\u95F4\uFF0C\u603B\u89C9\u5F97\u4E0D\u8BE5\u3002",
            "\u827E\u62C9\u83C8\uFF1A\u771F\u5947\u602A\u3002\u6211\u4E5F\u662F\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u9F99\u75D5\u5171\u9E23\u65F6\u7F81\u7ECA\u6536\u76CA\u63D0\u9AD8\u3002",
          lines: [
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u796D\u575B\u5728\u56DE\u5E94\u6211\u4EEC\u3002\u4E0D\u662F\u56DE\u5E94\u519B\u65D7\uFF0C\u662F\u56DE\u5E94\u8840\u3002",
            "\u827E\u62C9\u83C8\uFF1A\u5982\u679C\u771F\u76F8\u8BC1\u660E\u6211\u4EEC\u4E0D\u8BE5\u5E76\u80A9\u5462\uFF1F",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u90A3\u5C31\u5148\u6D3B\u5230\u80FD\u8D28\u95EE\u771F\u76F8\u7684\u90A3\u5929\u3002"
          ]
        },
        {
          rank: "A",
          effect: "\u89E3\u9501\u53CC\u751F\u5939\u51FB\u3002",
          lines: [
            "\u827E\u62C9\u83C8\uFF1A\u6211\u6068\u8FC7\u4F60\u7684\u56FD\u5BB6\uFF0C\u4E5F\u6068\u8FC7\u81EA\u5DF1\u4E3A\u4EC0\u4E48\u65E0\u6CD5\u6068\u4F60\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u6211\u4E5F\u4E00\u6837\u3002\u547D\u8FD0\u628A\u6211\u4EEC\u653E\u5728\u4E24\u8FB9\uFF0C\u4F46\u5251\u53EF\u4EE5\u81EA\u5DF1\u9009\u62E9\u843D\u70B9\u3002",
            "\u827E\u62C9\u83C8\uFF1A\u90A3\u8FD9\u4E00\u6B21\uFF0C\u522B\u504F\u534A\u5BF8\u3002\u548C\u6211\u4E00\u8D77\u523A\u7A7F\u5B83\u3002"
          ]
        },
        {
          rank: "S",
          effect: "\u771F\u7ED3\u5C40\u5224\u5B9A\u8BFB\u53D6\u8BE5\u8A93\u7EA6\u3002",
          lines: [
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u5C01\u5370\u8981\u4E00\u6761\u547D\u3002\u795E\u4EE5\u4E3A\u8FD9\u5C31\u80FD\u8BA9\u6211\u4EEC\u91CD\u65B0\u5F7C\u6B64\u4E3A\u654C\u3002",
            "\u827E\u62C9\u83C8\uFF1A\u90A3\u5C31\u8BA9\u795E\u770B\u6E05\u695A\uFF0C\u8840\u4E0D\u662F\u67B7\u9501\uFF0C\u7231\u4E5F\u4E0D\u662F\u796D\u54C1\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u82E5\u4E16\u754C\u53EA\u7ED9\u4E00\u6761\u8DEF\uFF0C\u6211\u4EEC\u5C31\u628A\u8DEF\u780D\u51FA\u6765\u3002"
          ]
        }
      ]
    },
    {
      id: "aldric_mirelle",
      units: ["aldric", "mirelle"],
      theme: "\u7981\u5FCC\u6697\u604B",
      unlockSkillId: "oath_resonance",
      unlockRank: "B",
      ranks: ["C", "B", "A"],
      conversations: [
        {
          rank: "C",
          effect: "\u7C73\u745E\u5C14\u83B7\u5F97\u88AB\u770B\u89C1\u7684\u52A8\u673A\u3002",
          lines: [
            "\u7C73\u745E\u5C14\uFF1A\u6BBF\u4E0B\u603B\u662F\u51B2\u5728\u6700\u524D\u9762\uFF0C\u50CF\u4E0D\u9700\u8981\u4EFB\u4F55\u4EBA\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u6211\u9700\u8981\u706B\u529B\u538B\u4F4F\u5DE6\u7FFC\u3002\u521A\u624D\u82E5\u6CA1\u6709\u4F60\uFF0C\u6211\u4F1A\u6B7B\u5728\u90A3\u91CC\u3002",
            "\u7C73\u745E\u5C14\uFF1A\u4F60\u8BB0\u5F97\uFF1F\u90A3\u6211\u4E0B\u6B21\u4F1A\u8BA9\u4F60\u66F4\u96BE\u5FD8\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u89E3\u9501\u8A93\u7EA6\u5171\u9E23\u3002",
          lines: [
            "\u7C73\u745E\u5C14\uFF1A\u6211\u77E5\u9053\u81EA\u5DF1\u4E0D\u8BE5\u5962\u671B\u4E00\u4E2A\u7B54\u6848\u3002\u53EF\u6211\u81F3\u5C11\u60F3\u6210\u4E3A\u4F60\u7684\u529B\u91CF\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u529B\u91CF\u4E0D\u662F\u7AD9\u5728\u6211\u8EAB\u540E\u3002\u662F\u6709\u4EBA\u6562\u5728\u6211\u9519\u65F6\u62E6\u4F4F\u6211\u3002",
            "\u7C73\u745E\u5C14\uFF1A\u90A3\u4F60\u6700\u597D\u522B\u8BA8\u538C\u6211\u592A\u5435\u3002"
          ]
        },
        {
          rank: "A",
          effect: "\u7B2C13\u7AE0\u540E\u7C73\u745E\u5C14\u4E0D\u4F1A\u56E0\u9635\u8425\u9009\u62E9\u79BB\u961F\u3002",
          lines: [
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u8FD9\u6761\u8DEF\u4F1A\u8BA9\u7D22\u96F7\u56E0\u628A\u6211\u4EEC\u90FD\u5F53\u53DB\u5F92\u3002",
            "\u7C73\u745E\u5C14\uFF1A\u6211\u6015\u8FC7\u88AB\u629B\u4E0B\uFF0C\u4E0D\u6015\u88AB\u901A\u7F09\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u90A3\u5C31\u4E00\u8D77\u8D70\u3002\u4E0D\u662F\u547D\u4EE4\uFF0C\u662F\u8BF7\u6C42\u3002"
          ]
        }
      ]
    },
    {
      id: "elara_sigrun",
      units: ["elara", "sigrun"],
      theme: "\u59D0\u59B9\u60C5/\u80CC\u53DB",
      unlockSkillId: "sister_guard",
      unlockRank: "B",
      ranks: ["C", "B", "A"],
      conversations: [
        {
          rank: "C",
          effect: "\u5E0C\u683C\u9732\u6069\u6062\u590D\u62A4\u536B\u8A93\u8A00\u3002",
          lines: [
            "\u5E0C\u683C\u9732\u6069\uFF1A\u516C\u4E3B\uFF0C\u4F60\u53C8\u8131\u79BB\u9635\u7EBF\u3002",
            "\u827E\u62C9\u83C8\uFF1A\u5982\u679C\u6211\u6C38\u8FDC\u88AB\u9635\u7EBF\u6846\u4F4F\uFF0C\u5C31\u6C38\u8FDC\u770B\u4E0D\u89C1\u771F\u76F8\u3002",
            "\u5E0C\u683C\u9732\u6069\uFF1A\u90A3\u81F3\u5C11\u8BA9\u6211\u8DDF\u4E0A\u3002\u8D23\u9A82\u4F60\u4E5F\u662F\u62A4\u536B\u804C\u8D23\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u89E3\u9501\u96EA\u8A93\u62A4\u536B\u3002",
          lines: [
            "\u827E\u62C9\u83C8\uFF1A\u82E5\u6211\u9009\u62E9\u548C\u5357\u65B9\u4EBA\u5E76\u80A9\uFF0C\u5317\u5883\u4F1A\u79F0\u6211\u4E3A\u80CC\u53DB\u8005\u3002",
            "\u5E0C\u683C\u9732\u6069\uFF1A\u6211\u6548\u5FE0\u7684\u4E0D\u662F\u5317\u5883\u7684\u5634\uFF0C\u662F\u90A3\u4E2A\u4F1A\u4E3A\u58EB\u5175\u6536\u5C38\u7684\u4F60\u3002",
            "\u827E\u62C9\u83C8\uFF1A\u4F60\u603B\u77E5\u9053\u600E\u4E48\u8BA9\u6211\u6CA1\u6CD5\u901E\u5F3A\u3002"
          ]
        },
        {
          rank: "A",
          effect: "\u5E0C\u683C\u9732\u6069\u5728\u7B2C16\u7AE0\u91CD\u7EC4\u4E2D\u7559\u4E0B\u3002",
          lines: [
            "\u5E0C\u683C\u9732\u6069\uFF1A\u80CC\u53DB\u8FD9\u4E2A\u8BCD\u592A\u4FBF\u5B9C\u3002\u771F\u6B63\u6602\u8D35\u7684\u662F\u7EE7\u7EED\u76F8\u4FE1\u3002",
            "\u827E\u62C9\u83C8\uFF1A\u5982\u679C\u6211\u9519\u4E86\uFF1F",
            "\u5E0C\u683C\u9732\u6069\uFF1A\u90A3\u6211\u4F1A\u4EB2\u624B\u628A\u4F60\u62C9\u56DE\u6765\uFF0C\u800C\u4E0D\u662F\u628A\u4F60\u4EA4\u7ED9\u522B\u4EBA\u5BA1\u5224\u3002"
          ]
        }
      ]
    },
    {
      id: "bjorn_luca",
      units: ["bjorn", "luca"],
      theme: "\u559C\u5267\u642D\u6863",
      unlockSkillId: "feint_snare",
      unlockRank: "B",
      ranks: ["C", "B"],
      conversations: [
        {
          rank: "C",
          effect: "\u4E24\u4EBA\u5EFA\u7ACB\u8BF1\u654C\u9ED8\u5951\u3002",
          lines: [
            "\u5362\u5361\uFF1A\u4F60\u6BCF\u6B21\u51B2\u950B\u524D\u90FD\u543C\u90A3\u4E48\u5927\u58F0\uFF0C\u662F\u6218\u672F\u8FD8\u662F\u55D3\u95E8\u5931\u63A7\uFF1F",
            "\u6BD4\u7EA6\u6069\uFF1A\u654C\u4EBA\u770B\u6211\uFF0C\u4E0D\u770B\u4F60\u3002\u8FD9\u53EB\u727A\u7272\u3002",
            "\u5362\u5361\uFF1A\u884C\uFF0C\u90A3\u6211\u8D1F\u8D23\u5728\u4F60\u727A\u7272\u524D\u628A\u654C\u4EBA\u817F\u5C04\u8F6F\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u89E3\u9501\u4F6F\u653B\u7275\u5236\u3002",
          lines: [
            "\u6BD4\u7EA6\u6069\uFF1A\u4F60\u8DD1\u5F97\u592A\u5FEB\uFF0C\u6211\u90FD\u6765\u4E0D\u53CA\u66FF\u4F60\u6321\u5200\u3002",
            "\u5362\u5361\uFF1A\u4F60\u6321\u5200\u592A\u6162\uFF0C\u6211\u53EA\u597D\u5148\u628A\u5200\u9A97\u8D70\u3002",
            "\u6BD4\u7EA6\u6069\uFF1A\u542C\u7740\u50CF\u80C6\u5C0F\u3002\u7528\u8D77\u6765\u50CF\u806A\u660E\u3002\u6210\u4EA4\u3002"
          ]
        }
      ]
    },
    {
      id: "cecilia_aldric",
      units: ["cecilia", "aldric"],
      theme: "\u65E7\u53CB\u5BF9\u7ACB/\u529D\u8D4E",
      unlockSkillId: "absolution_light",
      unlockRank: "A",
      ranks: ["C", "B", "A"],
      conversations: [
        {
          rank: "C",
          effect: "\u65E7\u53CB\u7EBF\u8BB0\u5F55\u7B2C14\u7AE0\u529D\u964D\u4F0F\u7B14\u3002",
          lines: [
            "\u585E\u897F\u8389\u4E9A\uFF1A\u4F60\u53D8\u4E86\uFF0C\u5965\u5FB7\u91CC\u514B\u3002\u4EE5\u524D\u4F60\u4E0D\u4F1A\u8D28\u7591\u5723\u5149\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u4EE5\u524D\u6211\u4EE5\u4E3A\u5723\u5149\u4E0D\u4F1A\u70E7\u6751\u5B50\u3002",
            "\u585E\u897F\u8389\u4E9A\uFF1A\u522B\u903C\u6211\u628A\u4F60\u5F53\u53DB\u5F92\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u585E\u897F\u8389\u4E9A\u88AB\u6D17\u8111\u65F6\u4FDD\u7559\u52A8\u6447\u6807\u8BB0\u3002",
          lines: [
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u4F60\u624B\u5728\u6296\u3002",
            "\u585E\u897F\u8389\u4E9A\uFF1A\u90A3\u662F\u6124\u6012\u3002",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u4E0D\u3002\u4F60\u8FD8\u8BB0\u5F97\u6211\u4EEC\u66FE\u53D1\u8A93\u4FDD\u62A4\u8C01\u3002"
          ]
        },
        {
          rank: "A",
          effect: "\u89E3\u9501\u5FCF\u6094\u4E4B\u5149\u3002",
          lines: [
            "\u585E\u897F\u8389\u4E9A\uFF1A\u5982\u679C\u6211\u771F\u7684\u9519\u4E86\uFF0C\u90A3\u4E9B\u6B7B\u8005\u8981\u5411\u8C01\u8BA8\u503A\uFF1F",
            "\u5965\u5FB7\u91CC\u514B\uFF1A\u5411\u64CD\u7EB5\u4F60\u7684\u4EBA\uFF0C\u4E5F\u5411\u7EE7\u7EED\u6D3B\u7740\u7684\u6211\u4EEC\u3002",
            "\u585E\u897F\u8389\u4E9A\uFF1A\u90A3\u522B\u8BA9\u6211\u9003\u3002\u8BA9\u6211\u8FD8\u3002"
          ]
        }
      ]
    },
    {
      id: "lucian_livia",
      units: ["lucian", "livia"],
      theme: "\u53CC\u5B50\u9A91\u58EB",
      unlockSkillId: "rally_speed",
      unlockRank: "B",
      ranks: ["C", "B", "A"],
      conversations: [
        {
          rank: "C",
          effect: "\u53CC\u5B50\u5171\u4EAB\u9635\u578B\u63D0\u793A\u3002",
          lines: [
            "\u5362\u4FEE\u5B89\uFF1A\u5DE6\u7FFC\u592A\u8584\uFF0C\u6211\u53BB\u8865\u3002",
            "\u8389\u8587\u5A05\uFF1A\u4F60\u6BCF\u6B21\u8BF4\u8865\uFF0C\u6700\u540E\u90FD\u53D8\u6210\u5355\u9A91\u7A81\u51FB\u3002",
            "\u5362\u4FEE\u5B89\uFF1A\u6240\u4EE5\u6211\u624D\u6709\u4F60\u8D1F\u8D23\u628A\u6211\u9A82\u56DE\u6765\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u89E3\u9501\u75BE\u901F\u53F7\u4EE4\u3002",
          lines: [
            "\u8389\u8587\u5A05\uFF1A\u6211\u4EEC\u4E0D\u662F\u4E00\u628A\u5251\u7684\u4E24\u9762\u3002\u4F60\u603B\u8BE5\u5B66\u4F1A\u6162\u534A\u6B65\u3002",
            "\u5362\u4FEE\u5B89\uFF1A\u6162\u534A\u6B65\u4F1A\u5BB3\u4EBA\u3002",
            "\u8389\u8587\u5A05\uFF1A\u5FEB\u534A\u6B65\u4E5F\u4F1A\u3002\u542C\u6211\u7684\u8282\u594F\u3002"
          ]
        },
        {
          rank: "A",
          effect: "\u53CC\u5B50\u5728\u540C\u573A\u5B58\u6D3B\u65F6\u989D\u5916\u83B7\u5F97\u7F81\u7ECA\u3002",
          lines: [
            "\u5362\u4FEE\u5B89\uFF1A\u5C0F\u65F6\u5019\u6211\u4EE5\u4E3A\u4FDD\u62A4\u4F60\u5C31\u662F\u6321\u5728\u524D\u9762\u3002",
            "\u8389\u8587\u5A05\uFF1A\u73B0\u5728\u5462\uFF1F",
            "\u5362\u4FEE\u5B89\uFF1A\u73B0\u5728\u6211\u77E5\u9053\uFF0C\u662F\u76F8\u4FE1\u4F60\u80FD\u548C\u6211\u5E76\u6392\u3002"
          ]
        }
      ]
    },
    {
      id: "yrsa_runa",
      units: ["yrsa", "runa"],
      theme: "\u5973\u6B66\u795E\u5019\u8865",
      unlockSkillId: "sister_guard",
      unlockRank: "B",
      ranks: ["C", "B", "A"],
      conversations: [
        {
          rank: "C",
          effect: "\u4E24\u540D\u5019\u8865\u505C\u6B62\u4E92\u76F8\u62A2\u529F\u3002",
          lines: [
            "\u4F0A\u5C14\u838E\uFF1A\u4F60\u521A\u624D\u62A2\u4E86\u6211\u7684\u51FB\u7834\u3002",
            "\u9732\u5A1C\uFF1A\u6211\u6551\u4E86\u4F60\u7684\u547D\u3002",
            "\u4F0A\u5C14\u838E\uFF1A\u4E0B\u6B21\u5148\u8BF4\u6551\u547D\uFF0C\u518D\u8BF4\u62A2\u529F\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u89E3\u9501\u96EA\u8A93\u62A4\u536B\u3002",
          lines: [
            "\u9732\u5A1C\uFF1A\u5973\u6B66\u795E\u4E0D\u662F\u8C01\u98DE\u5F97\u6700\u9AD8\uFF0C\u662F\u8C01\u80FD\u628A\u540C\u4F34\u5E26\u56DE\u6765\u3002",
            "\u4F0A\u5C14\u838E\uFF1A\u542C\u8D77\u6765\u50CF\u6559\u5B98\u7684\u8BDD\u3002",
            "\u9732\u5A1C\uFF1A\u5979\u6B7B\u524D\u6559\u6211\u7684\u3002\u73B0\u5728\u8F6E\u5230\u6211\u4EEC\u8BB0\u4F4F\u3002"
          ]
        },
        {
          rank: "A",
          effect: "\u5973\u6B66\u795E\u7EBF\u5728\u7B2C\u4E09\u5E55\u63D0\u4F9B\u64A4\u79BB\u652F\u63F4\u3002",
          lines: [
            "\u4F0A\u5C14\u838E\uFF1A\u6211\u4E00\u76F4\u60F3\u8D62\u4F60\u3002",
            "\u9732\u5A1C\uFF1A\u73B0\u5728\u5462\uFF1F",
            "\u4F0A\u5C14\u838E\uFF1A\u73B0\u5728\u60F3\u548C\u4F60\u4E00\u8D77\u8D62\u4E00\u6B21\u5927\u7684\u3002"
          ]
        }
      ]
    },
    {
      id: "dragon_elder_lost",
      units: ["dragon_elder", "lost_dragonkin"],
      theme: "\u5931\u5FC6\u4E0E\u4F20\u627F",
      unlockSkillId: "stigma_seal",
      unlockRank: "A",
      ranks: ["C", "B", "A"],
      conversations: [
        {
          rank: "C",
          effect: "\u5931\u5FC6\u9F99\u88D4\u5F00\u59CB\u8FA8\u8BA4\u53E4\u9F99\u8BED\u3002",
          lines: [
            "\u9F99\u88D4\u957F\u8001\uFF1A\u4F60\u5FF5\u9519\u4E86\u3002\u90A3\u4E0D\u662F\u6218\u543C\uFF0C\u662F\u60BC\u8BCD\u3002",
            "\u5931\u5FC6\u9F99\u88D4\uFF1A\u6211\u4E3A\u4EC0\u4E48\u4F1A\u8BB0\u5F97\u5B83\u7684\u65CB\u5F8B\uFF1F",
            "\u9F99\u88D4\u957F\u8001\uFF1A\u56E0\u4E3A\u8840\u6BD4\u540D\u5B57\u8BB0\u5F97\u4E45\u3002"
          ]
        },
        {
          rank: "B",
          effect: "\u9F99\u75D5\u5931\u63A7\u65F6\u83B7\u5F97\u4E00\u6B21\u63D0\u793A\u3002",
          lines: [
            "\u5931\u5FC6\u9F99\u88D4\uFF1A\u68A6\u91CC\u6709\u706B\uFF0C\u6709\u7FC5\u8180\uFF0C\u8FD8\u6709\u6211\u6740\u6B7B\u7684\u4EBA\u3002",
            "\u9F99\u88D4\u957F\u8001\uFF1A\u8BB0\u5FC6\u56DE\u6765\u65F6\u4F1A\u5148\u50CF\u8BC5\u5492\u3002",
            "\u5931\u5FC6\u9F99\u88D4\uFF1A\u90A3\u4E4B\u540E\u5462\uFF1F",
            "\u9F99\u88D4\u957F\u8001\uFF1A\u4E4B\u540E\u770B\u4F60\u80AF\u4E0D\u80AF\u628A\u5B83\u53D8\u6210\u8D23\u4EFB\u3002"
          ]
        },
        {
          rank: "A",
          effect: "\u89E3\u9501\u9F99\u75D5\u5C01\u5370\u3002",
          lines: [
            "\u9F99\u88D4\u957F\u8001\uFF1A\u5C01\u5370\u4E0D\u662F\u5426\u5B9A\u529B\u91CF\uFF0C\u662F\u7ED9\u529B\u91CF\u4E00\u4E2A\u56DE\u5BB6\u7684\u65B9\u5411\u3002",
            "\u5931\u5FC6\u9F99\u88D4\uFF1A\u5982\u679C\u6211\u66FE\u7ECF\u5931\u63A7\uFF1F",
            "\u9F99\u88D4\u957F\u8001\uFF1A\u90A3\u4ECA\u5929\u5C31\u7531\u4F60\u6559\u522B\u4EBA\u5982\u4F55\u505C\u4E0B\u3002"
          ]
        }
      ]
    }
  ];

  // src/data/content.ts
  var COMBAT = {
    minDamage: 1,
    counterHit: 15,
    counterMight: 1,
    doublingThreshold: 4,
    critFromSkill: 0.5,
    doubleRNG: true,
    effMultiplier: 3,
    // ponytail: starting long-range penalty; tune with A/09 simulations once siege weapon data lands.
    longRangeHitPenalty: 10
  };
  var GROWTH = {
    baseNextExp: 36,
    nextExpExponent: 1.5,
    hitExp: 8,
    killBaseExp: 24,
    killLevelBonus: 8,
    supportExp: 10,
    promotionLevel: 10,
    levelCap: 20
  };
  var ECONOMY = {
    startingGold: 1200,
    convoyCapacityPerWeapon: 99,
    rosterWeaponCapacity: 4,
    repairCostRatio: 0.5,
    forgeMaxLevel: 3,
    forgeMightPerLevel: 1
  };
  var BOND = {
    C: 0,
    B: 40,
    A: 100,
    S: 180
  };
  var weaponTriangle = {
    sword: { sword: 0, axe: 1, lance: -1 },
    axe: { sword: -1, axe: 0, lance: 1 },
    lance: { sword: 1, axe: -1, lance: 0 }
  };
  var magicTriangle = {
    fire: { fire: 0, ice: 1, thunder: -1 },
    ice: { fire: -1, ice: 0, thunder: 1 },
    thunder: { fire: 1, ice: -1, thunder: 0 }
  };
  var infantryGrowth = { hp: 70, str: 45, mag: 5, skill: 55, spd: 55, luck: 40, def: 30, res: 20 };
  var flyingGrowth = { hp: 60, str: 40, mag: 10, skill: 55, spd: 60, luck: 45, def: 20, res: 30 };
  var armorGrowth = { hp: 90, str: 55, mag: 0, skill: 35, spd: 20, luck: 25, def: 55, res: 15 };
  var mageGrowth = { hp: 55, str: 5, mag: 55, skill: 45, spd: 45, luck: 30, def: 15, res: 40 };
  var archerGrowth = { hp: 60, str: 45, mag: 5, skill: 55, spd: 50, luck: 35, def: 25, res: 20 };
  var healerGrowth = { hp: 55, str: 5, mag: 45, skill: 40, spd: 45, luck: 45, def: 15, res: 40 };
  var dragonGrowth = { hp: 80, str: 55, mag: 45, skill: 55, spd: 55, luck: 45, def: 40, res: 40 };
  var terrainCatalog = [
    { id: "plains", name: "\u5E73\u539F", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 0, avoid: 0, effects: [] },
    { id: "road", name: "\u9053\u8DEF", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 0, avoid: 0, effects: ["fast"] },
    { id: "forest", name: "\u68EE\u6797", moveCost: { foot: 2, horse: 3, fly: 1 }, defense: 1, avoid: 20, effects: ["horseSlow"] },
    { id: "deep_forest", name: "\u5BC6\u6797", moveCost: { foot: 3, horse: null, fly: 1 }, defense: 2, avoid: 30, effects: ["horseBlocked"] },
    { id: "mountain", name: "\u5C71\u5730", moveCost: { foot: 3, horse: null, fly: 1 }, defense: 2, avoid: 30, effects: ["horseBlocked"] },
    { id: "peak", name: "\u5C71\u5CF0", moveCost: { foot: 4, horse: null, fly: 1 }, defense: 3, avoid: 40, effects: ["vision"] },
    { id: "fort", name: "\u8981\u585E", moveCost: { foot: 2, horse: 2, fly: 1 }, defense: 2, avoid: 20, effects: ["regen10"] },
    { id: "village", name: "\u6751\u5E84", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 1, avoid: 10, effects: ["visit"] },
    { id: "river", name: "\u6CB3\u6D41", moveCost: { foot: null, horse: null, fly: 1 }, defense: 0, avoid: 0, effects: ["water"] },
    { id: "shallows", name: "\u6D45\u6EE9", moveCost: { foot: 3, horse: 4, fly: 1 }, defense: 0, avoid: -10, effects: ["water"] },
    { id: "bridge", name: "\u6865", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 0, avoid: 0, effects: ["chokepoint"] },
    { id: "sand", name: "\u6C99\u5730", moveCost: { foot: 2, horse: 3, fly: 1 }, defense: 0, avoid: 0, effects: ["horseSlow"] },
    { id: "poison_bog", name: "\u6BD2\u6CBC", moveCost: { foot: 2, horse: 3, fly: 1 }, defense: 0, avoid: 10, effects: ["poison"] },
    { id: "lava", name: "\u706B\u5C71\u5CA9", moveCost: { foot: 2, horse: null, fly: 1 }, defense: 0, avoid: 0, effects: ["eruption"] },
    { id: "ruins", name: "\u5E9F\u589F", moveCost: { foot: 2, horse: 2, fly: 1 }, defense: 1, avoid: 15, effects: ["cover"] },
    { id: "altar", name: "\u9F99\u75D5\u796D\u575B", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 1, avoid: 10, effects: ["stigma"] },
    { id: "throne", name: "\u738B\u5EA7", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 3, avoid: 30, effects: ["bossRegen"] },
    { id: "cliff", name: "\u65AD\u5D16", moveCost: { foot: null, horse: null, fly: 1 }, defense: 0, avoid: 0, effects: ["fall"] }
  ];
  var baseClassCatalog = [
    { id: "dragon_lance", name: "\u9F99\u88D4\xB7\u67AA", moveKind: "horse", tags: ["cavalry", "dragon"], weaponKinds: ["lance", "sword"], promotesTo: ["paladin", "dragon_king", "stigma_bearer"] },
    { id: "dragon_pegasus", name: "\u9F99\u88D4\xB7\u5929\u9A6C", moveKind: "fly", tags: ["flying", "dragon"], weaponKinds: ["lance", "fire", "ice", "thunder"], promotesTo: ["sky_knight", "dragon_king", "stigma_bearer"] },
    { id: "sword_fighter", name: "\u5251\u58EB", moveKind: "foot", tags: ["infantry"], weaponKinds: ["sword"], promotesTo: ["swordmaster", "hero"] },
    { id: "lance_cavalier", name: "\u67AA\u9A91", moveKind: "horse", tags: ["cavalry"], weaponKinds: ["lance", "sword"], promotesTo: ["paladin", "wyvern_lord"] },
    { id: "pegasus", name: "\u5929\u9A6C", moveKind: "fly", tags: ["flying"], weaponKinds: ["lance", "sword"], promotesTo: ["sky_knight", "falcon_knight"] },
    { id: "armor", name: "\u88C5\u7532", moveKind: "foot", tags: ["armored"], weaponKinds: ["lance", "axe"], promotesTo: ["general", "temple_guard"] },
    { id: "mage", name: "\u6CD5\u5E08", moveKind: "foot", tags: ["mage"], weaponKinds: ["fire", "ice", "thunder"], promotesTo: ["sage", "archmage"] },
    { id: "archer", name: "\u5F13\u5175", moveKind: "foot", tags: ["archer"], weaponKinds: ["bow"], promotesTo: ["sniper", "ranger"] },
    { id: "healer", name: "\u6CBB\u7597", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"], promotesTo: ["bishop", "saint"] },
    { id: "scout", name: "\u65A5\u5019", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword", "bow"], promotesTo: ["thief", "assassin"] },
    { id: "swordmaster", name: "\u5251\u5723", moveKind: "foot", tags: ["infantry"], weaponKinds: ["sword"], skillIds: ["iaijutsu"] },
    { id: "hero", name: "\u52C7\u8005", moveKind: "foot", tags: ["infantry"], weaponKinds: ["sword", "axe"], skillIds: ["hero_dual_wield"] },
    { id: "paladin", name: "\u5723\u9A91\u58EB", moveKind: "horse", tags: ["cavalry"], weaponKinds: ["sword", "lance"], skillIds: ["paladin_canto"] },
    { id: "general", name: "\u5C06\u519B", moveKind: "foot", tags: ["armored"], weaponKinds: ["lance", "axe"], skillIds: ["bulwark"] },
    { id: "sage", name: "\u8D24\u8005", moveKind: "foot", tags: ["mage"], weaponKinds: ["fire", "ice", "thunder", "staff"], skillIds: ["triune_sage"] },
    { id: "sniper", name: "\u72D9\u51FB\u624B", moveKind: "foot", tags: ["archer"], weaponKinds: ["bow"], skillIds: ["cloud_piercer"] },
    { id: "bishop", name: "\u4E3B\u6559", moveKind: "foot", tags: ["healer", "mage"], weaponKinds: ["staff", "fire"], skillIds: ["resurrection"] },
    { id: "dragon_king", name: "\u9F99\u738B", moveKind: "foot", tags: ["dragon"], weaponKinds: ["dragon", "sword", "lance"], skillIds: ["stigma_roar"] },
    { id: "stigma_bearer", name: "\u5723\u75D5\u4F7F", moveKind: "foot", tags: ["dragon"], weaponKinds: ["dragon", "fire", "thunder"], skillIds: ["stigma_seal"] }
  ];
  var classCatalog = [...baseClassCatalog, ...extraClassCatalog];
  var weaponCatalog = [
    { id: "iron_sword", name: "\u94C1\u5251", kind: "sword", damageKind: "physical", might: 5, hit: 90, crit: 0, weight: 4, range: [1, 1], durability: 40, cost: 460 },
    { id: "iron_axe", name: "\u94C1\u65A7", kind: "axe", damageKind: "physical", might: 8, hit: 75, crit: 0, weight: 8, range: [1, 1], durability: 35, cost: 520 },
    { id: "iron_lance", name: "\u94C1\u67AA", kind: "lance", damageKind: "physical", might: 7, hit: 80, crit: 0, weight: 7, range: [1, 1], durability: 40, cost: 520 },
    { id: "short_bow", name: "\u77ED\u5F13", kind: "bow", damageKind: "physical", might: 6, hit: 85, crit: 0, weight: 5, range: [2, 2], durability: 35, cost: 560, effectiveTags: ["flying"] },
    { id: "fire", name: "\u708E\u672F", kind: "fire", damageKind: "magical", might: 7, hit: 95, crit: 0, weight: 3, range: [1, 2], durability: 35, cost: 620 },
    { id: "ice", name: "\u51B0\u672F", kind: "ice", damageKind: "magical", might: 6, hit: 90, crit: 5, weight: 4, range: [1, 2], durability: 30, cost: 660 },
    { id: "thunder", name: "\u96F7\u672F", kind: "thunder", damageKind: "magical", might: 8, hit: 80, crit: 10, weight: 5, range: [1, 2], durability: 30, cost: 740 },
    { id: "heal_staff", name: "\u6CBB\u7597\u6756", kind: "staff", damageKind: "healing", might: 12, hit: 100, crit: 0, weight: 1, range: [1, 1], durability: 30, cost: 600 },
    { id: "horseslayer", name: "\u7834\u9A91\u67AA", kind: "lance", damageKind: "physical", might: 8, hit: 75, crit: 0, weight: 10, range: [1, 1], durability: 20, cost: 980, effectiveTags: ["cavalry"] },
    { id: "hammer", name: "\u7834\u7532\u9524", kind: "axe", damageKind: "physical", might: 9, hit: 70, crit: 0, weight: 12, range: [1, 1], durability: 20, cost: 900, effectiveTags: ["armored"] },
    { id: "wyrmslayer", name: "\u9F99\u6740\u5251", kind: "sword", damageKind: "physical", might: 7, hit: 80, crit: 0, weight: 7, range: [1, 1], durability: 20, cost: 1200, effectiveTags: ["dragon"] }
  ];
  var baseSkillCatalog = [
    { id: "foresight", name: "\u89C1\u5207", kind: "passive", trigger: "onDefend", effect: ["speedGapEvade"], condition: "\u901F\u5EA6\u5DEE>=5", description: "\u901F\u5EA6\u5DEE\u8DB3\u591F\u65F6\u5FC5\u95EA\u4E00\u6B21\u653B\u51FB\u3002" },
    { id: "armor_break", name: "\u7834\u7532", kind: "passive", trigger: "onAttack", effect: ["ignoreDef:50"], condition: "\u65A7/\u9524", description: "\u65E0\u89C6\u76EE\u6807\u4E00\u534A\u9632\u5FA1\u3002" },
    { id: "dragon_slayer", name: "\u5C60\u9F99", kind: "passive", trigger: "onAttack", effect: ["effective:dragon"], condition: "\u9F99\u6740\u6B66\u5668", description: "\u5BF9\u9F99\u88D4\u7279\u653B\u3002" },
    { id: "adept", name: "\u8FDE\u51FB", kind: "passive", trigger: "onAttack", effect: ["extraHit:skill%"], description: "\u6280\u5DE7\u6982\u7387\u8FFD\u52A0\u4E00\u51FB\u3002" },
    { id: "calm", name: "\u51B7\u9759", kind: "passive", trigger: "onDefend", effect: ["negateCrit"], description: "\u654C\u4E0D\u53EF\u5BF9\u6211\u66B4\u51FB\u3002" },
    { id: "vengeance", name: "\u590D\u4EC7", kind: "passive", trigger: "onAttack", effect: ["lostHpDamage"], description: "\u53D7\u4F24\u8D8A\u91CD\uFF0C\u4E0B\u51FB\u5A01\u529B\u8D8A\u9AD8\u3002" },
    { id: "hold_fast", name: "\u575A\u5B88", kind: "passive", trigger: "onTurnEnd", effect: ["defenseMod:30%"], condition: "\u672A\u79FB\u52A8", description: "\u4E0D\u79FB\u52A8\u56DE\u5408\u9632\u5FA1\u63D0\u5347\u3002" },
    { id: "pathfinder", name: "\u8E0F\u5203", kind: "passive", trigger: "onMove", effect: ["ignoreForestSlow"], condition: "\u6B65\u5175", description: "\u68EE\u6797\u4E0E\u5C71\u5730\u4E0D\u518D\u62D6\u6162\u79FB\u52A8\u3002" },
    { id: "lucky_star", name: "\u5E78\u8FD0\u661F", kind: "passive", trigger: "onDefend", effect: ["doubleLuckAntiCrit"], description: "\u5E78\u8FD0\u7FFB\u500D\u53C2\u4E0E\u6297\u66B4\u3002" },
    { id: "gale_cross", name: "\u75BE\u98CE\u8FDE\u65A9", kind: "active", trigger: "manual", effect: ["area:cross", "damage"], cost: "\u6BCF\u62181\u6B21", description: "\u653B\u51FB\u5341\u5B57\u8303\u56F4\u3002" },
    { id: "aegis", name: "\u5723\u76FE", kind: "active", trigger: "manual", effect: ["damageTaken:50%"], cost: "\u6BCF\u62182\u6B21", description: "\u672C\u56DE\u5408\u53D7\u4F24\u51CF\u534A\u3002" },
    { id: "charge", name: "\u51B2\u950B", kind: "active", trigger: "manual", effect: ["moveDistanceMight"], cost: "\u6BCF\u56DE\u54081\u6B21", condition: "\u9A91\u5175", description: "\u79FB\u52A8\u540E\u653B\u51FB\u6309\u79FB\u52A8\u683C\u52A0\u5A01\u529B\u3002" },
    { id: "healing_wave", name: "\u6CBB\u6108\u6CE2", kind: "active", trigger: "manual", effect: ["heal:area"], cost: "\u6756\u8010\u4E45", description: "\u8303\u56F4\u56DE\u8840\u3002" },
    { id: "taunt", name: "\u6311\u8845", kind: "active", trigger: "manual", effect: ["taunt"], cost: "\u6BCF\u62181\u6B21", description: "\u5F3A\u5236\u90BB\u654C\u4E0B\u56DE\u5408\u653B\u6211\u3002" },
    { id: "sprint", name: "\u75BE\u8D70", kind: "active", trigger: "manual", effect: ["move:+3"], cost: "\u6BCF\u62181\u6B21", description: "\u672C\u56DE\u5408\u79FB\u52A8\u63D0\u5347\u3002" },
    { id: "poison_blade", name: "\u6BD2\u5203", kind: "active", trigger: "onHit", effect: ["status:poison"], condition: "\u76D7\u8D3C", description: "\u547D\u4E2D\u65BD\u52A0\u6301\u7EED\u6263\u8840\u3002" },
    { id: "iaijutsu", name: "\u5251\u5723\xB7\u5C45\u5408", kind: "class", trigger: "onAttack", effect: ["crit:double"], condition: "\u5251\u5723", description: "\u66B4\u51FB\u7387\u7FFB\u500D\u3002" },
    { id: "bulwark", name: "\u5C06\u519B\xB7\u58C1\u5792", kind: "class", trigger: "always", effect: ["noForcedMove"], condition: "\u5C06\u519B", description: "\u4E0D\u53EF\u88AB\u51FB\u9000\u6216\u62C9\u626F\u3002" },
    { id: "cloud_piercer", name: "\u72D9\u51FB\xB7\u7A7F\u4E91", kind: "class", trigger: "onAttack", effect: ["range:+1", "ignoreTerrainAvoid"], condition: "\u72D9\u51FB\u624B", description: "\u5C04\u7A0B\u63D0\u5347\u5E76\u65E0\u89C6\u5730\u5F62\u56DE\u907F\u3002" },
    { id: "triune_sage", name: "\u8D24\u8005\xB7\u4E09\u76F8", kind: "class", trigger: "always", effect: ["equip:fire,ice,thunder"], condition: "\u8D24\u8005", description: "\u53EF\u540C\u65F6\u643A\u4E09\u7CFB\u9B54\u6CD5\u3002" },
    { id: "dive", name: "\u9F99\u9A91\xB7\u4FEF\u51B2", kind: "class", trigger: "onAttack", effect: ["highGroundMight"], condition: "\u9F99\u9A91\u5C06", description: "\u4ECE\u9AD8\u5904\u653B\u51FB\u63D0\u5347\u5A01\u529B\u3002" },
    { id: "resurrection", name: "\u4E3B\u6559\xB7\u590D\u6D3B", kind: "class", trigger: "manual", effect: ["reviveAdjacent"], cost: "\u9650\u6B21", condition: "\u4E3B\u6559", description: "\u590D\u6D3B\u76F8\u90BB\u9635\u4EA1\u53CB\u519B\u3002" },
    { id: "twin_pincer", name: "\u53CC\u751F\u5939\u51FB", kind: "bond", trigger: "bondAdjacent", effect: ["guaranteeCrit"], condition: "\u7F81\u7ECAA", description: "\u5144\u59B9\u76F8\u90BB\u653B\u51FB\u5FC5\u66B4\u3002" },
    { id: "guard_lunge", name: "\u63F4\u62A4\u7A81\u523A", kind: "bond", trigger: "allyDefended", effect: ["redirectCounter"], condition: "\u7F81\u7ECAB", description: "\u90BB\u53CB\u88AB\u653B\u65F6\u66FF\u5176\u53CD\u51FB\u3002" },
    { id: "oath_resonance", name: "\u8A93\u7EA6\u5171\u9E23", kind: "bond", trigger: "bondAdjacent", effect: ["hit:+15", "avoid:+15"], condition: "\u7F81\u7ECAC", description: "\u76F8\u90BB\u53CC\u65B9\u547D\u4E2D\u4E0E\u56DE\u907F\u63D0\u5347\u3002" },
    { id: "stigma_awaken", name: "\u9F99\u75D5\u89C9\u9192", kind: "stigma", trigger: "manual", effect: ["stats:large", "dragonTaint:+1"], cost: "\u9F99\u5316\u503C", condition: "\u4E3B\u89D2\u9650\u5B9A", description: "\u4E09\u56DE\u5408\u5168\u5C5E\u6027\u5927\u589E\uFF0C\u4E4B\u540E\u9F99\u5316\u7D2F\u79EF\u3002" }
  ];
  var skillCatalog = [...baseSkillCatalog, ...extraSkillCatalog];
  var baseUnitCatalog = [
    { id: "aldric", name: "\u5965\u5FB7\u91CC\u514B", faction: "sorein", classId: "dragon_lance", level: 1, baseStats: { hp: 27, str: 11, mag: 4, skill: 10, spd: 9, luck: 7, def: 9, res: 4, move: 6, con: 9 }, growths: dragonGrowth, weaponIds: ["iron_lance", "iron_sword"], skillIds: ["oath_resonance", "stigma_awaken"], defeatBehavior: "retreat" },
    { id: "valentin", name: "\u74E6\u4F26\u4E01", faction: "sorein", classId: "armor", level: 3, baseStats: { hp: 30, str: 12, mag: 0, skill: 8, spd: 5, luck: 5, def: 13, res: 3, move: 4, con: 12 }, growths: armorGrowth, weaponIds: ["iron_lance"], skillIds: ["hold_fast"] },
    { id: "mirelle", name: "\u7C73\u745E\u5C14", faction: "sorein", classId: "mage", level: 1, baseStats: { hp: 19, str: 1, mag: 10, skill: 9, spd: 8, luck: 6, def: 3, res: 7, move: 5, con: 5 }, growths: mageGrowth, weaponIds: ["fire"], skillIds: ["triune_sage"] },
    { id: "cecilia", name: "\u585E\u897F\u8389\u4E9A", faction: "church", classId: "sword_fighter", level: 2, baseStats: { hp: 23, str: 9, mag: 2, skill: 11, spd: 11, luck: 5, def: 5, res: 4, move: 5, con: 7 }, growths: infantryGrowth, weaponIds: ["iron_sword"], skillIds: ["calm"] },
    { id: "rowan", name: "\u5C11\u5E74\u5F13\u624B", faction: "sorein", classId: "archer", level: 1, baseStats: { hp: 21, str: 8, mag: 1, skill: 10, spd: 8, luck: 6, def: 4, res: 2, move: 5, con: 6 }, growths: archerGrowth, weaponIds: ["short_bow"], skillIds: [] },
    { id: "seren", name: "\u89C1\u4E60\u5723\u5973", faction: "sorein", classId: "healer", level: 1, baseStats: { hp: 18, str: 1, mag: 8, skill: 7, spd: 7, luck: 8, def: 2, res: 8, move: 5, con: 5 }, growths: healerGrowth, weaponIds: ["heal_staff"], skillIds: ["healing_wave"] },
    { id: "elara", name: "\u827E\u62C9\u83C8", faction: "nordheim", classId: "dragon_pegasus", level: 1, baseStats: { hp: 24, str: 8, mag: 9, skill: 11, spd: 12, luck: 7, def: 5, res: 8, move: 7, con: 7 }, growths: dragonGrowth, weaponIds: ["iron_lance", "thunder"], skillIds: ["stigma_awaken"], defeatBehavior: "retreat" },
    { id: "sigrun", name: "\u5E0C\u683C\u9732\u6069", faction: "nordheim", classId: "pegasus", level: 3, baseStats: { hp: 25, str: 10, mag: 4, skill: 12, spd: 13, luck: 8, def: 6, res: 8, move: 7, con: 7 }, growths: flyingGrowth, weaponIds: ["iron_lance"], skillIds: ["guard_lunge"] },
    { id: "bjorn", name: "\u6BD4\u7EA6\u6069", faction: "nordheim", classId: "sword_fighter", level: 2, baseStats: { hp: 28, str: 12, mag: 0, skill: 8, spd: 8, luck: 5, def: 7, res: 2, move: 5, con: 10 }, growths: infantryGrowth, weaponIds: ["iron_axe"], skillIds: ["vengeance"], defeatBehavior: "retreat" },
    { id: "nord_raider", name: "\u5317\u5883\u65A7\u5175", faction: "nordheim", classId: "sword_fighter", level: 1, baseStats: { hp: 22, str: 9, mag: 0, skill: 7, spd: 7, luck: 3, def: 6, res: 1, move: 5, con: 9 }, growths: infantryGrowth, weaponIds: ["iron_axe"], skillIds: [] },
    { id: "nord_scout", name: "\u96EA\u539F\u6E38\u4FA0", faction: "nordheim", classId: "scout", level: 1, baseStats: { hp: 20, str: 7, mag: 0, skill: 10, spd: 11, luck: 6, def: 3, res: 2, move: 6, con: 6 }, growths: infantryGrowth, weaponIds: ["iron_sword"], skillIds: ["pathfinder"] },
    { id: "ice_mage", name: "\u51B0\u7CFB\u7CBE\u7075\u6CD5\u5E08", faction: "nordheim", classId: "mage", level: 1, baseStats: { hp: 18, str: 1, mag: 9, skill: 9, spd: 8, luck: 4, def: 2, res: 8, move: 5, con: 5 }, growths: mageGrowth, weaponIds: ["ice"], skillIds: [] }
  ];
  var unitCatalog = [...baseUnitCatalog, ...extraUnitCatalog];
  function byId(items, id) {
    const item = items.find((candidate) => candidate.id === id);
    if (!item) {
      throw new Error(`Unknown content id: ${id}`);
    }
    return item;
  }
  function isPhysicalTriangleKind(kind) {
    return kind === "sword" || kind === "axe" || kind === "lance";
  }
  function isMagicTriangleKind(kind) {
    return kind === "fire" || kind === "ice" || kind === "thunder";
  }

  // src/data/index.ts
  var chapterCatalog = fullChapterCatalog;
  var getChapter = (id) => byId(chapterCatalog, id);
  var getEnding = (id) => byId(endingCatalog, id);
  var getTerrain = (id) => byId(terrainCatalog, id);
  var getWeapon = (id) => byId(weaponCatalog, id);
  var getClass = (id) => byId(classCatalog, id);
  var getUnitDef = (id) => byId(unitCatalog, id);
  var getSkill = (id) => byId(skillCatalog, id);

  // src/services/equipment.ts
  function normalizeWeaponUses(weaponIds, uses) {
    const normalized = {};
    for (const weaponId of new Set(weaponIds)) {
      const weapon = getWeapon(weaponId);
      normalized[weaponId] = clampInteger(uses?.[weaponId] ?? weapon.durability, 0, weapon.durability);
    }
    return normalized;
  }
  function normalizeWeaponForge(weaponIds, forge) {
    const normalized = {};
    for (const weaponId of new Set(weaponIds)) {
      normalized[weaponId] = clampInteger(forge?.[weaponId] ?? 0, 0, ECONOMY.forgeMaxLevel);
    }
    return normalized;
  }
  function remainingWeaponUses(unit, weaponId = unit.weaponId) {
    const weapon = getWeapon(weaponId);
    return clampInteger(unit.weaponUses[weaponId] ?? weapon.durability, 0, weapon.durability);
  }
  function spendWeaponUse(unit, weaponId = unit.weaponId) {
    const remaining = remainingWeaponUses(unit, weaponId);
    const next = Math.max(0, remaining - 1);
    unit.weaponUses = { ...unit.weaponUses, [weaponId]: next };
    return next;
  }
  function weaponForgeLevel(unit, weaponId = unit.weaponId) {
    return clampInteger(unit.weaponForge[weaponId] ?? 0, 0, ECONOMY.forgeMaxLevel);
  }
  function weaponMight(unit, weapon) {
    return weapon.might + weaponForgeLevel(unit, weapon.id) * ECONOMY.forgeMightPerLevel;
  }
  function repairWeaponCost(entry, weaponId = entry.weaponId) {
    const weapon = getWeapon(weaponId);
    const missing = weapon.durability - clampInteger(entry.weaponUses[weaponId] ?? weapon.durability, 0, weapon.durability);
    if (missing <= 0) {
      return 0;
    }
    return Math.ceil(weapon.cost * ECONOMY.repairCostRatio * missing / weapon.durability);
  }
  function forgeWeaponCost(entry, weaponId = entry.weaponId) {
    const weapon = getWeapon(weaponId);
    const level = clampInteger(entry.weaponForge[weaponId] ?? 0, 0, ECONOMY.forgeMaxLevel);
    if (level >= ECONOMY.forgeMaxLevel) {
      return 0;
    }
    return weapon.cost * (level + 1);
  }
  function clampInteger(value, min, max) {
    if (!Number.isFinite(value)) {
      return max;
    }
    return Math.max(min, Math.min(max, Math.floor(value)));
  }

  // src/services/deployments.ts
  function instantiateDeployment(deployment, campaign) {
    const unitDef = getUnitDef(deployment.unitDefId);
    const rosterEntry = deployment.team === "ally" ? campaign?.roster.find((entry) => entry.unitDefId === unitDef.id) : void 0;
    if (deployment.team === "ally" && (campaign?.mode === "classic" && campaign.fallen.includes(unitDef.id) || rosterEntry?.deployed === false)) {
      return void 0;
    }
    const weaponId = deployment.team === "ally" ? rosterEntry?.weaponId ?? deployment.weaponId ?? unitDef.weaponIds[0] : deployment.weaponId ?? unitDef.weaponIds[0];
    if (!weaponId) {
      throw new Error(`Unit ${unitDef.id} has no weapon`);
    }
    const weaponIds = deployment.team === "ally" ? rosterEntry?.weaponIds ?? [weaponId] : [weaponId];
    const carriedWeaponIds = weaponIds.includes(weaponId) ? weaponIds : [...weaponIds, weaponId];
    return {
      id: deployment.instanceId,
      defId: unitDef.id,
      team: deployment.team,
      classId: deployment.team === "ally" ? rosterEntry?.classId ?? unitDef.classId : unitDef.classId,
      hp: rosterEntry?.stats.hp ?? unitDef.baseStats.hp,
      stats: { ...rosterEntry?.stats ?? unitDef.baseStats },
      weaponId,
      weaponUses: normalizeWeaponUses(carriedWeaponIds, rosterEntry?.weaponUses),
      weaponForge: normalizeWeaponForge(carriedWeaponIds, rosterEntry?.weaponForge),
      skillIds: [...rosterEntry?.skillIds ?? unitDef.skillIds],
      statuses: [],
      skillUses: {},
      pos: { x: deployment.x, y: deployment.y },
      acted: false,
      moved: false,
      cantoMoveLeft: 0,
      alive: true,
      level: rosterEntry?.level ?? unitDef.level,
      exp: rosterEntry?.exp ?? 0
    };
  }

  // src/services/classes.ts
  var promotionBonus = {
    hp: 3,
    str: 1,
    mag: 1,
    skill: 1,
    spd: 1,
    luck: 0,
    def: 1,
    res: 1,
    move: 1,
    con: 1
  };
  function classForUnit(unit) {
    return getClass(unit.classId);
  }
  function classForRoster(entry) {
    return getClass(entry.classId);
  }
  function canClassUseWeapon(classId, weaponId) {
    return getClass(classId).weaponKinds.includes(getWeapon(weaponId).kind);
  }
  function canRosterUseWeapon(entry, weaponId) {
    return canClassUseWeapon(entry.classId, weaponId);
  }
  function promotionTargets(entry) {
    if (entry.level < GROWTH.promotionLevel) {
      return [];
    }
    return [...getClass(entry.classId).promotesTo ?? []];
  }
  function promoteRosterUnit(campaign, unitDefId, targetClassId) {
    const entry = campaign.roster.find((candidate) => candidate.unitDefId === unitDefId);
    if (!entry) {
      throw new Error(`Unknown roster unit: ${unitDefId}`);
    }
    const targets = getClass(entry.classId).promotesTo ?? [];
    if (!targets.includes(targetClassId)) {
      throw new Error("\u8BE5\u804C\u4E1A\u4E0D\u80FD\u8F6C\u4E3A\u76EE\u6807\u804C\u4E1A\u3002");
    }
    if (entry.level < GROWTH.promotionLevel) {
      throw new Error(`Lv.${GROWTH.promotionLevel} \u540E\u624D\u80FD\u8F6C\u804C\u3002`);
    }
    const targetClass = getClass(targetClassId);
    const weaponId = canClassUseWeapon(targetClassId, entry.weaponId) ? entry.weaponId : firstUsableWeapon(entry, targetClass);
    if (!weaponId) {
      throw new Error("\u6CA1\u6709\u53EF\u88C5\u5907\u7684\u6B66\u5668\uFF0C\u65E0\u6CD5\u5B8C\u6210\u8F6C\u804C\u3002");
    }
    return {
      ...campaign,
      roster: campaign.roster.map(
        (candidate) => candidate.unitDefId === entry.unitDefId ? {
          ...cloneRosterEntry(candidate),
          classId: targetClass.id,
          stats: promotedStats(candidate.stats),
          weaponId,
          skillIds: mergeSkillIds(candidate.skillIds, targetClass.skillIds ?? [])
        } : cloneRosterEntry(candidate)
      ),
      savedAt: Date.now()
    };
  }
  function baseClassId(unitDefId) {
    return getUnitDef(unitDefId).classId;
  }
  function isKnownClassId(classId) {
    try {
      getClass(classId);
      return true;
    } catch {
      return false;
    }
  }
  function firstUsableWeapon(entry, classDef) {
    return entry.weaponIds.find((weaponId) => classDef.weaponKinds.includes(getWeapon(weaponId).kind));
  }
  function promotedStats(stats) {
    return {
      hp: Math.min(60, stats.hp + promotionBonus.hp),
      str: Math.min(30, stats.str + promotionBonus.str),
      mag: Math.min(30, stats.mag + promotionBonus.mag),
      skill: Math.min(30, stats.skill + promotionBonus.skill),
      spd: Math.min(30, stats.spd + promotionBonus.spd),
      luck: Math.min(30, stats.luck + promotionBonus.luck),
      def: Math.min(30, stats.def + promotionBonus.def),
      res: Math.min(30, stats.res + promotionBonus.res),
      move: stats.move + promotionBonus.move,
      con: stats.con + promotionBonus.con
    };
  }
  function mergeSkillIds(current, added) {
    for (const skillId of added) {
      getSkill(skillId);
    }
    return [.../* @__PURE__ */ new Set([...current, ...added])];
  }
  function cloneRosterEntry(entry) {
    return {
      ...entry,
      stats: { ...entry.stats },
      weaponIds: [...entry.weaponIds],
      weaponUses: { ...entry.weaponUses },
      weaponForge: { ...entry.weaponForge },
      skillIds: [...entry.skillIds]
    };
  }

  // src/services/skillEffects.ts
  var DREAD_AURA_RANGE = 2;
  function hasSkill(unit, skillId) {
    return unit.skillIds.includes(skillId);
  }
  function attackRange(unit, weapon) {
    const bonus = (hasSkill(unit, "cloud_piercer") && weapon.kind === "bow" ? 1 : 0) + (hasSkill(unit, "ballista_lockon") && (weapon.kind === "bow" || weapon.kind === "thunder") ? 2 : 0);
    return [weapon.range[0], weapon.range[1] + bonus];
  }
  function canUnitAttackAtDistance(unit, weapon, cells) {
    const range = attackRange(unit, weapon);
    return cells >= range[0] && cells <= range[1];
  }
  function ignoresTerrainAvoid(attacker, weapon) {
    return hasSkill(attacker, "cloud_piercer") && weapon.kind === "bow";
  }
  function armorBreaks(attacker, weapon) {
    return hasSkill(attacker, "armor_break") && weapon.kind === "axe";
  }
  function damageBonus(state, attacker, defender, weapon) {
    let bonus = 0;
    const defenderTags = classForUnit(defender).tags;
    if (hasSkill(attacker, "vengeance")) {
      bonus += Math.floor((attacker.stats.hp - attacker.hp) / 2);
    }
    if (hasSkill(attacker, "linebreaker") && defenderTags.includes("armored")) {
      bonus += 3;
    }
    if (hasSkill(attacker, "mage_slayer") && defenderTags.includes("mage")) {
      bonus += 3;
    }
    if (hasSkill(attacker, "dive") && classForUnit(attacker).tags.includes("flying") && terrainHeight(state, attacker) > terrainHeight(state, defender)) {
      bonus += 3;
    }
    if (hasSkill(attacker, "dragon_slayer") && weapon.effectiveTags?.includes("dragon") && defenderTags.includes("dragon")) {
      bonus += weapon.might * 2;
    }
    if (hasSkill(attacker, "archmage_focus") && isElementalMagic(weapon.kind)) {
      bonus += 3;
    }
    bonus += statusValue(attacker, "charge");
    return bonus;
  }
  function defenseBonus(state, defender, terrain, magical) {
    let bonus = 0;
    if ((terrain.id === "forest" || terrain.id === "deep_forest") && hasSkill(defender, "forest_guard")) {
      bonus += 2;
    }
    if (defender.hp <= Math.floor(defender.stats.hp * 0.3) && hasSkill(defender, "last_stand")) {
      bonus += 3;
    }
    if (!defender.moved && hasSkill(defender, "hold_fast")) {
      const baseDefense = magical ? defender.stats.res : defender.stats.def;
      bonus += Math.max(1, Math.floor(baseDefense * 0.3));
    }
    if (adjacentAllies(state, defender).some((ally) => hasSkill(ally, "shield_wall") && classForUnit(ally).tags.includes("armored"))) {
      bonus += magical ? 0 : 2;
    }
    return bonus;
  }
  function hitBonus(state, attacker) {
    let bonus = 0;
    if (adjacentAllies(state, attacker).some((ally) => hasSkill(ally, "battle_prayer"))) {
      bonus += 5;
    }
    if (hasSkill(attacker, "oath_resonance") && adjacentAllies(state, attacker).length > 0) {
      bonus += 15;
    }
    if (hasSkill(attacker, "feint_snare") && adjacentAllies(state, attacker).length > 0) {
      bonus += 10;
    }
    if (nearbyEnemies(state, attacker, DREAD_AURA_RANGE).some((enemy) => hasSkill(enemy, "black_knight_dread"))) {
      bonus -= 10;
    }
    return bonus;
  }
  function avoidBonus(state, defender, attackerWeapon) {
    let bonus = hasSkill(defender, "oath_resonance") && adjacentAllies(state, defender).length > 0 ? 15 : 0;
    if (attackerWeapon?.kind === "bow" && hasSkill(defender, "anti_arrow_stance")) {
      bonus += 20;
    }
    if (defender.statuses.some((status) => status.id === "marked" && status.turns > 0)) {
      bonus -= 15;
    }
    return bonus;
  }
  function rangeHitPenalty(attacker, weapon, cells) {
    if (cells <= weapon.range[1] || hasSkill(attacker, "ballista_lockon")) {
      return 0;
    }
    return COMBAT.longRangeHitPenalty;
  }
  function primeBloodMemory(state, fallen) {
    const witnesses = state.units.filter(
      (unit) => unit.alive && unit.team === fallen.team && unit.id !== fallen.id && hasSkill(unit, "blood_memory") && classForUnit(unit).tags.includes("dragon")
    );
    for (const witness of witnesses) {
      witness.skillUses.blood_memory = 1;
    }
    return witnesses;
  }
  function consumeBloodMemory(unit) {
    if ((unit.skillUses.blood_memory ?? 0) <= 0) {
      return false;
    }
    unit.skillUses.blood_memory = (unit.skillUses.blood_memory ?? 0) - 1;
    return true;
  }
  function critMultiplier(state, attacker) {
    if (hasSkill(attacker, "twin_pincer") && adjacentAllies(state, attacker).length > 0) {
      return 100;
    }
    return hasSkill(attacker, "iaijutsu") ? 2 : 1;
  }
  function critAvoidBonus(defender) {
    return hasSkill(defender, "calm") ? 100 : hasSkill(defender, "lucky_star") ? defender.stats.luck : 0;
  }
  function followUpThreshold(attacker, weapon) {
    return hasSkill(attacker, "quickdraw") && weapon.kind === "bow" ? 3 : 4;
  }
  function foresightReady(attacker, defender) {
    return hasSkill(defender, "foresight") && (defender.skillUses.foresight ?? 0) === 0 && defender.stats.spd - attacker.stats.spd >= 5;
  }
  function ignoresTerrainSlow(unit, terrain) {
    if (hasSkill(unit, "pathfinder") && classForUnit(unit).tags.includes("infantry")) {
      return terrain.id === "forest" || terrain.id === "deep_forest" || terrain.id === "mountain" || terrain.id === "peak";
    }
    return hasSkill(unit, "snowstep") && (terrain.id === "mountain" || terrain.id === "peak");
  }
  function adjacentAllies(state, unit) {
    return state.units.filter(
      (candidate) => candidate.alive && candidate.team === unit.team && candidate.id !== unit.id && Math.abs(candidate.pos.x - unit.pos.x) + Math.abs(candidate.pos.y - unit.pos.y) <= 1
    );
  }
  function nearbyEnemies(state, unit, range) {
    return state.units.filter(
      (candidate) => candidate.alive && candidate.team !== unit.team && Math.abs(candidate.pos.x - unit.pos.x) + Math.abs(candidate.pos.y - unit.pos.y) <= range
    );
  }
  function isElementalMagic(kind) {
    return kind === "fire" || kind === "ice" || kind === "thunder";
  }
  function terrainHeight(state, unit) {
    const terrainId = state.grid[unit.pos.y]?.[unit.pos.x];
    if (terrainId === "peak") {
      return 3;
    }
    if (terrainId === "mountain" || terrainId === "cliff") {
      return 2;
    }
    return terrainId === "forest" || terrainId === "deep_forest" ? 1 : 0;
  }
  function statusValue(unit, id) {
    return unit.statuses.find((status) => status.id === id && status.turns > 0)?.value ?? 0;
  }

  // src/services/chapterEvents.ts
  function processChapterEvents(state, phase) {
    const chapter = getChapter(state.chapterId);
    const spawned = [];
    for (const event of chapter.events ?? []) {
      warnUpcomingEvent(state, event);
      if (event.phase !== phase || state.turn < event.turn || isResolved(state, event)) {
        continue;
      }
      spawned.push(...spawnReinforcements(state, event));
      state.flags[eventFlag(state, event, "resolved")] = true;
    }
    return spawned;
  }
  function hasPendingHostileReinforcements(state) {
    return (getChapter(state.chapterId).events ?? []).some(
      (event) => !isResolved(state, event) && event.deployments.some((deployment) => deployment.team === "enemy")
    );
  }
  function warnUpcomingEvent(state, event) {
    if (!event.telegraph || state.turn !== event.turn - 1 || isWarned(state, event)) {
      return;
    }
    state.flags[eventFlag(state, event, "warned")] = true;
    state.log.unshift(event.telegraph);
  }
  function spawnReinforcements(state, event) {
    const spawned = [];
    for (const deployment of event.deployments) {
      if (state.units.some((unit2) => unit2.id === deployment.instanceId)) {
        continue;
      }
      const unit = instantiateDeployment(deployment);
      if (!unit) {
        continue;
      }
      const spawn = spawnCellFor(state, unit, { x: deployment.x, y: deployment.y });
      if (!spawn) {
        continue;
      }
      unit.pos = spawn;
      if (event.ambush && unit.team === "enemy" && hasWatchfulAlly(state)) {
        unit.acted = true;
      }
      state.units.push(unit);
      spawned.push(unit);
    }
    if (event.message && spawned.length > 0) {
      state.log.unshift(event.message);
    }
    if (event.ambush && spawned.some((unit) => unit.team === "enemy" && unit.acted)) {
      state.log.unshift("\u8B66\u6212\u8BC6\u7834\u4F0F\u51FB\uFF0C\u589E\u63F4\u65E0\u6CD5\u7ACB\u5373\u5148\u624B\u3002");
    }
    return spawned;
  }
  function spawnCellFor(state, unit, origin) {
    const occupied = new Set(state.units.filter((candidate) => candidate.alive).map((candidate) => cellKey(candidate.pos)));
    const candidates = [];
    for (let y = 0; y < state.grid.length; y += 1) {
      for (let x = 0; x < (state.grid[0]?.length ?? 0); x += 1) {
        candidates.push({ x, y });
      }
    }
    return candidates.filter((cell) => inBounds(state, cell) && !occupied.has(cellKey(cell)) && canStandOn(state, unit, cell)).sort((a, b) => distance(a, origin) - distance(b, origin) || a.y - b.y || a.x - b.x)[0];
  }
  function canStandOn(state, unit, cell) {
    const terrainId = state.grid[cell.y]?.[cell.x];
    return terrainId ? getTerrain(terrainId).moveCost[classForUnit(unit).moveKind] != null : false;
  }
  function inBounds(state, cell) {
    return cell.y >= 0 && cell.y < state.grid.length && cell.x >= 0 && cell.x < (state.grid[0]?.length ?? 0);
  }
  function cellKey(cell) {
    return `${cell.x},${cell.y}`;
  }
  function distance(a, b) {
    return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
  }
  function hasWatchfulAlly(state) {
    return state.units.some((unit) => unit.alive && unit.team === "ally" && hasSkill(unit, "watchful"));
  }
  function isWarned(state, event) {
    return state.flags[eventFlag(state, event, "warned")] === true;
  }
  function isResolved(state, event) {
    return state.flags[eventFlag(state, event, "resolved")] === true;
  }
  function eventFlag(state, event, suffix) {
    return `chapterEvent:${state.chapterId}:${event.id}:${suffix}`;
  }

  // src/services/chapter.ts
  function createInitialBattleState(chapterId = "ch01", campaign) {
    const chapter = getChapter(chapterId);
    const grid = chapter.map.map(
      (row) => [...row].map((symbol) => {
        const terrainId = chapter.terrainLegend[symbol];
        if (!terrainId) {
          throw new Error(`Unknown terrain symbol "${symbol}" in ${chapter.id}`);
        }
        return terrainId;
      })
    );
    const units = chapter.deployments.flatMap((deployment) => {
      const unit = instantiateDeployment(deployment, campaign);
      return unit ? [unit] : [];
    });
    const state = {
      chapterId: chapter.id,
      turn: 1,
      phase: campaign ? "deploy" : "player",
      grid,
      units,
      rngState: campaign?.seed ?? 1592639710,
      bonds: { ...campaign?.bonds ?? {} },
      flags: {
        ...campaign?.flags ?? {},
        "dragonTaint:aldric": campaign?.taint.aldric ?? 0,
        "dragonTaint:elara": campaign?.taint.elara ?? 0
      },
      log: [...chapter.opening].reverse()
    };
    processChapterEvents(state, "playerStart");
    return state;
  }
  function createRosterEntry(unitDefId, weaponId) {
    const unitDef = getUnitDef(unitDefId);
    const entryWeaponId = weaponId ?? unitDef.weaponIds[0];
    if (!entryWeaponId) {
      throw new Error(`Unit ${unitDef.id} has no weapon`);
    }
    const weaponIds = [.../* @__PURE__ */ new Set([...unitDef.weaponIds, entryWeaponId])];
    return {
      unitDefId: unitDef.id,
      classId: unitDef.classId,
      level: unitDef.level,
      exp: 0,
      stats: { ...unitDef.baseStats },
      weaponId: entryWeaponId,
      weaponIds,
      weaponUses: normalizeWeaponUses(weaponIds),
      weaponForge: normalizeWeaponForge(weaponIds),
      skillIds: [...unitDef.skillIds],
      deployed: true
    };
  }
  function findUnit(state, unitId) {
    const unit = state.units.find((candidate) => candidate.id === unitId);
    if (!unit) {
      throw new Error(`Unknown unit: ${unitId}`);
    }
    return unit;
  }
  function livingUnits(state, team) {
    return state.units.filter((unit) => unit.alive && (!team || unit.team === team));
  }
  function unitAt(state, x, y) {
    return state.units.find((unit) => unit.alive && unit.pos.x === x && unit.pos.y === y);
  }
  function updateOutcome(state) {
    if (state.phase === "victory" || state.phase === "defeat") {
      return;
    }
    const chapter = getChapter(state.chapterId);
    const allies = livingUnits(state, "ally");
    if (allies.length === 0) {
      state.phase = "defeat";
      state.log.unshift("\u6211\u65B9\u5168\u706D\u3002\u5BBF\u547D\u6682\u65F6\u541E\u6CA1\u4E86\u62B5\u6297\u3002");
      return;
    }
    const failedCondition = chapter.defeatConditions?.find((condition) => isDefeatConditionMet(state, condition));
    if (failedCondition) {
      state.phase = "defeat";
      state.log.unshift(defeatConditionText(state, failedCondition));
      return;
    }
    if (isVictoryConditionMet(state, chapter.victoryCondition ?? { type: "rout" })) {
      state.phase = "victory";
      state.log.unshift(victoryConditionText(chapter.victoryCondition ?? { type: "rout" }));
    }
  }
  function isVictoryConditionMet(state, condition) {
    if (condition.type === "rout") {
      return livingUnits(state, "enemy").length === 0 && !hasPendingHostileReinforcements(state);
    }
    if (condition.type === "defeatBoss") {
      return condition.targetInstanceIds.every((unitId) => {
        const target = state.units.find((unit) => unit.id === unitId);
        return target ? !target.alive : false;
      });
    }
    if (condition.type === "survive") {
      return state.turn > condition.turns;
    }
    if (condition.type === "seize") {
      return livingUnits(state, "ally").some((unit) => isAllowedUnit(unit, condition.unitDefIds) && unit.pos.x === condition.x && unit.pos.y === condition.y);
    }
    if (condition.type === "escape") {
      return condition.unitDefIds.every((unitDefId) => livingUnits(state, "ally").some((unit) => unit.defId === unitDefId && unit.pos.x === condition.x && unit.pos.y === condition.y));
    }
    if (condition.type === "all") {
      return condition.conditions.every((nested) => isVictoryConditionMet(state, nested));
    }
    return condition.conditions.some((nested) => isVictoryConditionMet(state, nested));
  }
  function isDefeatConditionMet(state, condition) {
    if (condition.type === "protectUnit") {
      return protectedUnits(state, condition).some((unit) => !unit?.alive);
    }
    return false;
  }
  function protectedUnits(state, condition) {
    const byInstance = condition.instanceIds?.map((id) => state.units.find((unit) => unit.id === id)) ?? [];
    const byDef = condition.unitDefIds?.map((id) => state.units.find((unit) => unit.defId === id && unit.team === "ally")) ?? [];
    return [...byInstance, ...byDef];
  }
  function isAllowedUnit(unit, unitDefIds) {
    return !unitDefIds || unitDefIds.includes(unit.defId);
  }
  function victoryConditionText(condition) {
    if (condition.type === "rout") {
      return "\u654C\u519B\u5D29\u6E83\uFF0C\u76EE\u6807\u8FBE\u6210\u3002";
    }
    if (condition.type === "defeatBoss") {
      return "\u5173\u952E\u76EE\u6807\u64A4\u9000\uFF0C\u76EE\u6807\u8FBE\u6210\u3002";
    }
    if (condition.type === "survive") {
      return `\u575A\u5B88 ${condition.turns} \u56DE\u5408\uFF0C\u76EE\u6807\u8FBE\u6210\u3002`;
    }
    if (condition.type === "seize") {
      return "\u76EE\u6807\u5730\u70B9\u5DF2\u5360\u9886\u3002";
    }
    if (condition.type === "escape") {
      return "\u6307\u5B9A\u5355\u4F4D\u62B5\u8FBE\u64A4\u79BB\u70B9\u3002";
    }
    return "\u590D\u5408\u76EE\u6807\u8FBE\u6210\u3002";
  }
  function defeatConditionText(state, condition) {
    if (condition.type === "protectUnit") {
      const name = protectedUnits(state, condition).find((unit) => !unit?.alive);
      return `${name ? getUnitDef(name.defId).name : "\u4FDD\u62A4\u76EE\u6807"} \u5012\u4E0B\uFF0C\u76EE\u6807\u5931\u8D25\u3002`;
    }
    return "\u76EE\u6807\u5931\u8D25\u3002";
  }

  // src/services/campaign.ts
  var SAVE_KEY = "rift-expedition.save.v1";
  var SAVE_VERSION = 1;
  function createNewCampaign(mode = "classic") {
    return {
      version: SAVE_VERSION,
      currentChapterId: "ch01",
      completedChapterIds: [],
      roster: ["aldric", "valentin", "mirelle", "cecilia", "rowan", "seren"].map((unitId) => createRosterEntry(unitId)),
      fallen: [],
      gold: ECONOMY.startingGold,
      convoy: { iron_sword: 1, iron_lance: 1, short_bow: 1, fire: 1, heal_staff: 1 },
      bonds: {},
      taint: { aldric: 0, elara: 0 },
      flags: {},
      mode,
      seed: 1592639710,
      savedAt: Date.now()
    };
  }
  function loadCampaign(storage) {
    if (!storage) {
      return createNewCampaign();
    }
    const raw = storage.getItem(SAVE_KEY);
    if (!raw) {
      return createNewCampaign();
    }
    try {
      return migrateCampaign(JSON.parse(raw));
    } catch {
      return createNewCampaign();
    }
  }
  function saveCampaign(storage, campaign) {
    if (!storage) {
      return;
    }
    storage.setItem(SAVE_KEY, JSON.stringify({ ...campaign, savedAt: Date.now() }));
  }
  function clearCampaign(storage) {
    storage?.removeItem(SAVE_KEY);
  }
  function completeCurrentChapter(campaign) {
    const chapter = getChapter(campaign.currentChapterId);
    const completed = campaign.completedChapterIds.includes(chapter.id) ? campaign.completedChapterIds : [...campaign.completedChapterIds, chapter.id];
    const nextChapterId = chapter.nextChapterId;
    if (!nextChapterId) {
      const ending = chooseEnding(campaign);
      return { ...campaign, completedChapterIds: completed, endingId: ending.id, savedAt: Date.now() };
    }
    return { ...campaign, completedChapterIds: completed, currentChapterId: nextChapterId, savedAt: Date.now() };
  }
  function applyStoryChoice(campaign, choice, optionIndex) {
    const option = choice.options[optionIndex];
    if (!option) {
      throw new Error(`Invalid option ${optionIndex} for choice ${choice.id}`);
    }
    return {
      ...campaign,
      flags: { ...campaign.flags, [option.flag]: option.value },
      savedAt: Date.now()
    };
  }
  function ensureChapterRoster(campaign, chapterId = campaign.currentChapterId) {
    const chapter = getChapter(chapterId);
    const known = new Set(campaign.roster.map((entry) => entry.unitDefId));
    const recruits = chapter.deployments.filter((deployment) => deployment.team === "ally" && !known.has(deployment.unitDefId) && !campaign.fallen.includes(deployment.unitDefId)).map((deployment) => createRosterEntry(deployment.unitDefId, deployment.weaponId));
    if (recruits.length === 0) {
      return campaign;
    }
    return { ...campaign, roster: [...campaign.roster.map(cloneRosterEntry2), ...recruits], savedAt: Date.now() };
  }
  function mergeBattleIntoCampaign(campaign, state) {
    const roster = campaign.roster.map(cloneRosterEntry2);
    const fallen = new Set(campaign.fallen);
    const rewards = battleRewards(state.flags);
    for (const unit of state.units) {
      if (unit.team !== "ally") {
        continue;
      }
      const unitDef = getUnitDef(unit.defId);
      if (campaign.mode === "classic" && !unit.alive && unitDef.defeatBehavior !== "retreat") {
        fallen.add(unit.defId);
        continue;
      }
      upsertRosterEntry(roster, unit);
    }
    return {
      ...campaign,
      roster,
      fallen: [...fallen],
      gold: campaign.gold + rewards.gold,
      convoy: mergeConvoy(campaign.convoy, rewards.convoy),
      bonds: { ...campaign.bonds, ...state.bonds },
      taint: {
        ...campaign.taint,
        aldric: Number(state.flags["dragonTaint:aldric"] ?? campaign.taint.aldric ?? 0),
        elara: Number(state.flags["dragonTaint:elara"] ?? campaign.taint.elara ?? 0)
      },
      flags: { ...campaign.flags, ...persistentBattleFlags(state.flags) },
      seed: state.rngState,
      savedAt: Date.now()
    };
  }
  function chooseEnding(campaign) {
    const endingChoice = campaign.flags.endingChoice;
    const totalTaint = Object.values(campaign.taint).reduce((sum, value) => sum + value, 0);
    if (totalTaint >= 6) {
      return endingCatalog.find((ending) => ending.id === "dragonfall") ?? endingCatalog[3];
    }
    if (endingChoice === 1 && !campaign.fallen.includes("aldric")) {
      return endingCatalog.find((ending) => ending.id === "sacrifice_aldric") ?? endingCatalog[0];
    }
    if (endingChoice === 2 && !campaign.fallen.includes("elara")) {
      return endingCatalog.find((ending) => ending.id === "sacrifice_elara") ?? endingCatalog[1];
    }
    if (endingChoice === 3 && (campaign.bonds["aldric:elara"] ?? 0) >= 180) {
      return endingCatalog.find((ending) => ending.id === "defy_god") ?? endingCatalog[2];
    }
    return endingCatalog.find((ending) => ending.id === "sacrifice_aldric") ?? endingCatalog[0];
  }
  function migrateCampaign(raw) {
    const fresh = createNewCampaign();
    const currentChapterId = typeof raw.currentChapterId === "string" && chapterCatalog.some((chapter) => chapter.id === raw.currentChapterId) ? raw.currentChapterId : fresh.currentChapterId;
    return {
      ...fresh,
      ...raw,
      version: SAVE_VERSION,
      currentChapterId,
      completedChapterIds: Array.isArray(raw.completedChapterIds) ? raw.completedChapterIds.filter((id) => typeof id === "string") : [],
      roster: migrateRoster(raw.roster, fresh.roster),
      fallen: Array.isArray(raw.fallen) ? raw.fallen.filter((id) => typeof id === "string") : [],
      gold: typeof raw.gold === "number" ? raw.gold : fresh.gold,
      convoy: isNumberRecord(raw.convoy) ? raw.convoy : fresh.convoy,
      bonds: isRecord(raw.bonds) ? raw.bonds : {},
      taint: isRecord(raw.taint) ? raw.taint : fresh.taint,
      flags: isRecord(raw.flags) ? raw.flags : {},
      mode: raw.mode === "casual" ? "casual" : "classic",
      seed: typeof raw.seed === "number" ? raw.seed : fresh.seed,
      savedAt: typeof raw.savedAt === "number" ? raw.savedAt : Date.now(),
      ...typeof raw.endingId === "string" ? { endingId: raw.endingId } : {}
    };
  }
  function isRecord(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
  }
  function migrateRoster(raw, fallback) {
    if (!Array.isArray(raw)) {
      return fallback.map(cloneRosterEntry2);
    }
    const roster = [];
    for (const item of raw) {
      const entry = migrateRosterEntry(item);
      if (entry) {
        roster.push(entry);
      }
    }
    return roster.length > 0 ? roster : fallback.map(cloneRosterEntry2);
  }
  function migrateRosterEntry(raw) {
    if (typeof raw === "string") {
      return safeRosterEntry(raw);
    }
    if (!isObject(raw) || typeof raw.unitDefId !== "string") {
      return void 0;
    }
    const base = safeRosterEntry(raw.unitDefId);
    if (!base) {
      return void 0;
    }
    const weaponIds = Array.isArray(raw.weaponIds) ? raw.weaponIds.filter((id) => typeof id === "string") : base.weaponIds;
    const carriedWeaponIds = typeof raw.weaponId === "string" && !weaponIds.includes(raw.weaponId) ? [...weaponIds, raw.weaponId] : weaponIds;
    return {
      unitDefId: base.unitDefId,
      classId: typeof raw.classId === "string" && isKnownClassId(raw.classId) ? raw.classId : base.classId,
      level: typeof raw.level === "number" ? raw.level : base.level,
      exp: typeof raw.exp === "number" ? raw.exp : base.exp,
      stats: isStats(raw.stats) ? raw.stats : base.stats,
      weaponId: typeof raw.weaponId === "string" ? raw.weaponId : base.weaponId,
      weaponIds: carriedWeaponIds,
      weaponUses: normalizeWeaponUses(carriedWeaponIds, isNumberRecord(raw.weaponUses) ? raw.weaponUses : base.weaponUses),
      weaponForge: normalizeWeaponForge(carriedWeaponIds, isNumberRecord(raw.weaponForge) ? raw.weaponForge : base.weaponForge),
      skillIds: Array.isArray(raw.skillIds) ? raw.skillIds.filter((id) => typeof id === "string") : base.skillIds,
      deployed: typeof raw.deployed === "boolean" ? raw.deployed : base.deployed
    };
  }
  function safeRosterEntry(unitDefId) {
    try {
      return createRosterEntry(unitDefId);
    } catch {
      return void 0;
    }
  }
  function upsertRosterEntry(roster, unit) {
    const previous = roster.find((entry) => entry.unitDefId === unit.defId);
    const previousWeaponIds = previous?.weaponIds ?? Object.keys(unit.weaponUses);
    const weaponIds = previousWeaponIds.includes(unit.weaponId) ? previousWeaponIds : [...previousWeaponIds, unit.weaponId];
    const next = {
      unitDefId: unit.defId,
      classId: isKnownClassId(unit.classId) ? unit.classId : previous?.classId ?? baseClassId(unit.defId),
      level: unit.level,
      exp: unit.exp,
      stats: { ...unit.stats },
      weaponId: unit.weaponId,
      weaponIds: [...weaponIds],
      weaponUses: normalizeWeaponUses(weaponIds, unit.weaponUses),
      weaponForge: normalizeWeaponForge(weaponIds, unit.weaponForge),
      skillIds: [...unit.skillIds],
      deployed: previous?.deployed ?? true
    };
    const index = roster.findIndex((entry) => entry.unitDefId === unit.defId);
    if (index === -1) {
      roster.push(next);
    } else {
      roster[index] = next;
    }
  }
  function persistentBattleFlags(flags) {
    return Object.fromEntries(Object.entries(flags).filter(([key]) => !isRuntimeBattleFlag(key)));
  }
  function battleRewards(flags) {
    const convoy = {};
    for (const [key, value] of Object.entries(flags)) {
      if (key === "battleReward:gold") {
        continue;
      }
      if (key.startsWith("battleReward:item:") && typeof value === "number") {
        const weaponId = key.slice("battleReward:item:".length);
        convoy[weaponId] = (convoy[weaponId] ?? 0) + value;
      }
    }
    return { gold: Number(flags["battleReward:gold"] ?? 0), convoy };
  }
  function mergeConvoy(base, rewards) {
    const next = { ...base };
    for (const [weaponId, count] of Object.entries(rewards)) {
      next[weaponId] = (next[weaponId] ?? 0) + count;
    }
    return next;
  }
  function isRuntimeBattleFlag(key) {
    return key.startsWith("chapterEvent:") || key.startsWith("chapterVisit:") || key.startsWith("battleReward:");
  }
  function cloneRosterEntry2(entry) {
    return {
      ...entry,
      stats: { ...entry.stats },
      weaponIds: [...entry.weaponIds],
      weaponUses: { ...entry.weaponUses },
      weaponForge: { ...entry.weaponForge },
      skillIds: [...entry.skillIds]
    };
  }
  function isObject(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
  }
  function isStats(value) {
    if (!isObject(value)) {
      return false;
    }
    return ["hp", "str", "mag", "skill", "spd", "luck", "def", "res", "move", "con"].every((key) => typeof value[key] === "number");
  }
  function isNumberRecord(value) {
    if (!isObject(value)) {
      return false;
    }
    return Object.values(value).every((count) => typeof count === "number");
  }

  // src/services/loadout.ts
  function setRosterDeployment(campaign, unitDefId, deployed, requiredUnitIds) {
    const entry = findRosterEntry(campaign, unitDefId);
    if (!deployed && deployedRoster(campaign, requiredUnitIds).filter((candidate) => candidate.unitDefId !== unitDefId).length === 0) {
      throw new Error("\u81F3\u5C11\u9700\u8981\u4E00\u540D\u5355\u4F4D\u51FA\u6218\u3002");
    }
    return {
      ...campaign,
      roster: campaign.roster.map(
        (candidate) => candidate.unitDefId === entry.unitDefId ? { ...cloneRosterEntry3(candidate), deployed } : cloneRosterEntry3(candidate)
      ),
      savedAt: Date.now()
    };
  }
  function cycleRosterWeapon(campaign, unitDefId, step = 1) {
    const entry = findRosterEntry(campaign, unitDefId);
    if (entry.weaponIds.length <= 1) {
      return campaign;
    }
    const currentIndex = Math.max(0, entry.weaponIds.indexOf(entry.weaponId));
    const nextIndex = (currentIndex + step + entry.weaponIds.length) % entry.weaponIds.length;
    return setRosterWeapon(campaign, unitDefId, entry.weaponIds[nextIndex]);
  }
  function buyWeapon(campaign, weaponId, count = 1) {
    const weapon = getWeapon(weaponId);
    const totalCost = weapon.cost * count;
    if (count <= 0) {
      throw new Error("\u8D2D\u4E70\u6570\u91CF\u5FC5\u987B\u5927\u4E8E 0\u3002");
    }
    if (campaign.gold < totalCost) {
      throw new Error("\u91D1\u5E01\u4E0D\u8DB3\u3002");
    }
    const owned = campaign.convoy[weaponId] ?? 0;
    if (owned + count > ECONOMY.convoyCapacityPerWeapon) {
      throw new Error("\u4ED3\u5E93\u5DF2\u6EE1\u3002");
    }
    return {
      ...campaign,
      gold: campaign.gold - totalCost,
      convoy: { ...campaign.convoy, [weaponId]: owned + count },
      savedAt: Date.now()
    };
  }
  function assignConvoyWeapon(campaign, unitDefId, weaponId) {
    const entry = findRosterEntry(campaign, unitDefId);
    if ((campaign.convoy[weaponId] ?? 0) <= 0) {
      throw new Error("\u4ED3\u5E93\u6CA1\u6709\u8FD9\u4EF6\u6B66\u5668\u3002");
    }
    if (!canRosterUseWeapon(entry, weaponId)) {
      throw new Error("\u8BE5\u5355\u4F4D\u65E0\u6CD5\u88C5\u5907\u8FD9\u7C7B\u6B66\u5668\u3002");
    }
    if (entry.weaponIds.includes(weaponId)) {
      return setRosterWeapon(campaign, unitDefId, weaponId);
    }
    if (entry.weaponIds.length >= ECONOMY.rosterWeaponCapacity) {
      throw new Error("\u6B66\u5668\u680F\u5DF2\u6EE1\u3002");
    }
    return {
      ...campaign,
      convoy: { ...campaign.convoy, [weaponId]: (campaign.convoy[weaponId] ?? 0) - 1 },
      roster: campaign.roster.map(
        (candidate) => candidate.unitDefId === entry.unitDefId ? {
          ...cloneRosterEntry3(candidate),
          weaponId,
          weaponIds: [...candidate.weaponIds, weaponId],
          weaponUses: { ...candidate.weaponUses, [weaponId]: getWeapon(weaponId).durability },
          weaponForge: { ...candidate.weaponForge, [weaponId]: 0 }
        } : cloneRosterEntry3(candidate)
      ),
      savedAt: Date.now()
    };
  }
  function repairRosterWeapon(campaign, unitDefId, weaponId) {
    const entry = findRosterEntry(campaign, unitDefId);
    const targetWeaponId = weaponId ?? entry.weaponId;
    if (!entry.weaponIds.includes(targetWeaponId)) {
      throw new Error("\u8BE5\u5355\u4F4D\u672A\u643A\u5E26\u8FD9\u4EF6\u6B66\u5668\u3002");
    }
    const cost = repairWeaponCost(entry, targetWeaponId);
    if (cost <= 0) {
      return campaign;
    }
    if (campaign.gold < cost) {
      throw new Error("\u91D1\u5E01\u4E0D\u8DB3\u3002");
    }
    const weapon = getWeapon(targetWeaponId);
    return {
      ...campaign,
      gold: campaign.gold - cost,
      roster: campaign.roster.map(
        (candidate) => candidate.unitDefId === entry.unitDefId ? { ...cloneRosterEntry3(candidate), weaponUses: { ...candidate.weaponUses, [targetWeaponId]: weapon.durability } } : cloneRosterEntry3(candidate)
      ),
      savedAt: Date.now()
    };
  }
  function forgeRosterWeapon(campaign, unitDefId, weaponId) {
    const entry = findRosterEntry(campaign, unitDefId);
    const targetWeaponId = weaponId ?? entry.weaponId;
    if (!entry.weaponIds.includes(targetWeaponId)) {
      throw new Error("\u8BE5\u5355\u4F4D\u672A\u643A\u5E26\u8FD9\u4EF6\u6B66\u5668\u3002");
    }
    const cost = forgeWeaponCost(entry, targetWeaponId);
    if (cost <= 0) {
      throw new Error("\u953B\u9020\u5DF2\u6EE1\u3002");
    }
    if (campaign.gold < cost) {
      throw new Error("\u91D1\u5E01\u4E0D\u8DB3\u3002");
    }
    return {
      ...campaign,
      gold: campaign.gold - cost,
      roster: campaign.roster.map(
        (candidate) => candidate.unitDefId === entry.unitDefId ? { ...cloneRosterEntry3(candidate), weaponForge: { ...candidate.weaponForge, [targetWeaponId]: (candidate.weaponForge[targetWeaponId] ?? 0) + 1 } } : cloneRosterEntry3(candidate)
      ),
      savedAt: Date.now()
    };
  }
  function setRosterWeapon(campaign, unitDefId, weaponId) {
    const entry = findRosterEntry(campaign, unitDefId);
    if (!entry.weaponIds.includes(weaponId)) {
      throw new Error("\u8BE5\u5355\u4F4D\u672A\u643A\u5E26\u8FD9\u4EF6\u6B66\u5668\u3002");
    }
    if (!canRosterUseWeapon(entry, weaponId)) {
      throw new Error("\u8BE5\u5355\u4F4D\u65E0\u6CD5\u88C5\u5907\u8FD9\u7C7B\u6B66\u5668\u3002");
    }
    return {
      ...campaign,
      roster: campaign.roster.map(
        (candidate) => candidate.unitDefId === entry.unitDefId ? { ...cloneRosterEntry3(candidate), weaponId } : cloneRosterEntry3(candidate)
      ),
      savedAt: Date.now()
    };
  }
  function deployedRoster(campaign, unitIds) {
    const required = unitIds ? new Set(unitIds) : void 0;
    return campaign.roster.filter((entry) => entry.deployed && !campaign.fallen.includes(entry.unitDefId) && (!required || required.has(entry.unitDefId)));
  }
  function findRosterEntry(campaign, unitDefId) {
    const entry = campaign.roster.find((candidate) => candidate.unitDefId === unitDefId);
    if (!entry) {
      throw new Error(`Unknown roster unit: ${unitDefId}`);
    }
    return entry;
  }
  function cloneRosterEntry3(entry) {
    return {
      ...entry,
      stats: { ...entry.stats },
      weaponIds: [...entry.weaponIds],
      // ponytail: keyed by weapon id until the convoy becomes true item instances.
      weaponUses: normalizeWeaponUses(entry.weaponIds, entry.weaponUses),
      weaponForge: normalizeWeaponForge(entry.weaponIds, entry.weaponForge),
      skillIds: [...entry.skillIds]
    };
  }

  // src/services/status.ts
  function hasStatus(unit, id) {
    return unit.statuses.some((status) => status.id === id && status.turns > 0);
  }
  function addStatus(unit, effect) {
    const current = unit.statuses.find((status) => status.id === effect.id);
    if (current) {
      current.turns = Math.max(current.turns, effect.turns);
      if (effect.sourceId) {
        current.sourceId = effect.sourceId;
      }
      if (effect.value != null) {
        current.value = effect.value;
      }
      return;
    }
    unit.statuses.push({ ...effect });
  }
  function tickStatuses(unit) {
    unit.statuses = unit.statuses.map((status) => ({ ...status, turns: status.turns - 1 })).filter((status) => status.turns > 0);
  }
  function effectiveStats(unit) {
    const stats = { ...unit.stats };
    if (hasStatus(unit, "stigma_awaken")) {
      stats.str += 5;
      stats.mag += 5;
      stats.skill += 5;
      stats.spd += 5;
      stats.def += 5;
      stats.res += 5;
    }
    if (hasStatus(unit, "sprint")) {
      stats.move += 3;
    }
    if (hasStatus(unit, "rally_defense")) {
      stats.def += 2;
    }
    if (hasStatus(unit, "rally_speed")) {
      stats.spd += 2;
    }
    if (hasStatus(unit, "barrier")) {
      stats.res += 5;
    }
    if (hasStatus(unit, "frozen")) {
      stats.spd = Math.max(0, stats.spd - 2);
      stats.move = Math.max(0, stats.move - 2);
    }
    return stats;
  }

  // src/services/movement.ts
  function cellKey2(cell) {
    return `${cell.x},${cell.y}`;
  }
  function distance2(a, b) {
    return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
  }
  function inBounds2(state, cell) {
    return cell.y >= 0 && cell.y < state.grid.length && cell.x >= 0 && cell.x < (state.grid[0]?.length ?? 0);
  }
  function terrainAt(state, cell) {
    const terrainId = state.grid[cell.y]?.[cell.x];
    if (!terrainId) {
      throw new Error(`Out of bounds terrain lookup at ${cell.x},${cell.y}`);
    }
    return getTerrain(terrainId);
  }
  function movementCost(state, unit, cell) {
    if (!inBounds2(state, cell)) {
      return null;
    }
    const classDef = classForUnit(unit);
    const terrain = terrainAt(state, cell);
    const baseCost = terrain.moveCost[classDef.moveKind];
    if (baseCost == null) {
      return null;
    }
    if (ignoresTerrainSlow(unit, terrain)) {
      return 1;
    }
    return baseCost;
  }
  function reachableCells(state, unit) {
    const start = unit.pos;
    const best = /* @__PURE__ */ new Map();
    const frontier = [{ cell: start, cost: 0 }];
    best.set(cellKey2(start), { cell: start, cost: 0 });
    while (frontier.length > 0) {
      frontier.sort((a, b) => a.cost - b.cost);
      const current = frontier.shift();
      if (!current) {
        break;
      }
      for (const next of neighbors(current.cell)) {
        const cost = movementCost(state, unit, next);
        if (cost == null) {
          continue;
        }
        const occupant = unitAt(state, next.x, next.y);
        if (occupant && occupant.id !== unit.id && !canMoveThrough(unit, occupant)) {
          continue;
        }
        const nextCost = current.cost + cost;
        if (nextCost > effectiveStats(unit).move) {
          continue;
        }
        const key = cellKey2(next);
        const known = best.get(key);
        if (!known || nextCost < known.cost) {
          best.set(key, { cell: next, cost: nextCost });
          frontier.push({ cell: next, cost: nextCost });
        }
      }
    }
    return best;
  }
  function canOccupy(state, unit, cell) {
    const reachable = reachableCells(state, unit);
    const occupant = unitAt(state, cell.x, cell.y);
    return reachable.has(cellKey2(cell)) && (!occupant || occupant.id === unit.id);
  }
  function moveUnit(state, unit, cell) {
    if (!canOccupy(state, unit, cell)) {
      return false;
    }
    const moved = unit.pos.x !== cell.x || unit.pos.y !== cell.y;
    unit.pos = { ...cell };
    if (moved) {
      unit.moved = true;
    }
    return true;
  }
  function neighbors(cell) {
    return [
      { x: cell.x + 1, y: cell.y },
      { x: cell.x - 1, y: cell.y },
      { x: cell.x, y: cell.y + 1 },
      { x: cell.x, y: cell.y - 1 }
    ];
  }
  function canMoveThrough(unit, occupant) {
    return occupant.team === unit.team && hasSkill(occupant, "trailblazer");
  }

  // src/services/supports.ts
  var rankOrder = ["C", "B", "A", "S"];
  function bondKey(left, right) {
    return [left, right].sort().join(":");
  }
  function supportConversationKey(pairId, rank) {
    return `support:${pairId}:${rank}`;
  }
  function availableSupportConversations(campaign) {
    const roster = new Set(campaign.roster.map((entry) => entry.unitDefId));
    const fallen = new Set(campaign.fallen);
    const available = [];
    for (const pair of supportPairCatalog) {
      if (!pair.units.every((unitId) => roster.has(unitId) && !fallen.has(unitId))) {
        continue;
      }
      const value = campaign.bonds[bondKey(pair.units[0], pair.units[1])] ?? 0;
      for (const rank of pair.ranks) {
        if (value < BOND[rank]) {
          continue;
        }
        const key = supportConversationKey(pair.id, rank);
        available.push({ pair, rank, viewed: campaign.flags[key] === true, key });
      }
    }
    return available.sort((left, right) => {
      if (left.viewed !== right.viewed) {
        return left.viewed ? 1 : -1;
      }
      return supportLabel(left).localeCompare(supportLabel(right), "zh-Hans-CN");
    });
  }
  function firstUnviewedSupportConversation(campaign) {
    return availableSupportConversations(campaign).find((conversation) => !conversation.viewed);
  }
  function supportLabel(conversation) {
    return `${conversation.pair.id} ${conversation.rank}`;
  }
  function viewSupportConversation(campaign, pairId, rank) {
    const pair = supportPairCatalog.find((candidate) => candidate.id === pairId);
    if (!pair || !pair.ranks.includes(rank) || !pair.conversations.some((conversation) => conversation.rank === rank)) {
      throw new Error(`Unknown support conversation: ${pairId}:${rank}`);
    }
    if ((campaign.bonds[bondKey(pair.units[0], pair.units[1])] ?? 0) < BOND[rank]) {
      throw new Error(`Support conversation is locked: ${pairId}:${rank}`);
    }
    const shouldUnlockSkill = rankOrder.indexOf(rank) >= rankOrder.indexOf(pair.unlockRank);
    return {
      ...campaign,
      roster: campaign.roster.map((entry) => {
        if (!shouldUnlockSkill || !pair.units.includes(entry.unitDefId) || entry.skillIds.includes(pair.unlockSkillId)) {
          return cloneRosterEntry4(entry);
        }
        return { ...cloneRosterEntry4(entry), skillIds: [...entry.skillIds, pair.unlockSkillId] };
      }),
      flags: { ...campaign.flags, [supportConversationKey(pair.id, rank)]: true },
      savedAt: Date.now()
    };
  }
  function cloneRosterEntry4(entry) {
    return {
      ...entry,
      stats: { ...entry.stats },
      weaponIds: [...entry.weaponIds],
      weaponUses: { ...entry.weaponUses },
      weaponForge: { ...entry.weaponForge },
      skillIds: [...entry.skillIds]
    };
  }

  // src/services/rng.ts
  function createRng(seed) {
    let state = seed >>> 0;
    return {
      get state() {
        return state >>> 0;
      },
      next() {
        state = state + 1831565813 >>> 0;
        let t = state;
        t = Math.imul(t ^ t >>> 15, t | 1);
        t ^= t + Math.imul(t ^ t >>> 7, t | 61);
        return ((t ^ t >>> 14) >>> 0) / 4294967296;
      }
    };
  }
  function rollPercent(rng, displayedPercent, doubleRng) {
    const clamped = Math.max(0, Math.min(100, displayedPercent));
    const roll = doubleRng ? (rng.next() + rng.next()) / 2 * 100 : rng.next() * 100;
    return roll < clamped;
  }

  // src/services/progression.ts
  var growthStats = ["hp", "str", "mag", "skill", "spd", "luck", "def", "res"];
  function nextExpForLevel(level) {
    return Math.max(1, Math.floor(GROWTH.baseNextExp * level ** GROWTH.nextExpExponent));
  }
  function awardCombatExperience(state, rng, events) {
    const awards = /* @__PURE__ */ new Map();
    for (const event of events) {
      if (event.type === "hit") {
        addAward(awards, event.sourceId, GROWTH.hitExp);
      } else if (event.type === "defeat") {
        const source = state.units.find((unit) => unit.id === event.sourceId);
        const target = state.units.find((unit) => unit.id === event.targetId);
        if (source && target) {
          const levelGap = Math.max(1, target.level - source.level);
          addAward(awards, source.id, GROWTH.killBaseExp + levelGap * GROWTH.killLevelBonus);
        }
      }
    }
    const logs = [];
    for (const [unitId, amount] of awards) {
      const unit = state.units.find((candidate) => candidate.id === unitId);
      if (unit) {
        logs.push(...gainExperience(state, rng, unit, amount));
      }
    }
    return logs;
  }
  function gainExperience(state, rng, unit, amount) {
    if (unit.team !== "ally" || !unit.alive || amount <= 0 || unit.level >= GROWTH.levelCap) {
      return [];
    }
    const unitDef = getUnitDef(unit.defId);
    const logs = [];
    unit.exp += Math.floor(amount);
    while (unit.level < GROWTH.levelCap && unit.exp >= nextExpForLevel(unit.level)) {
      unit.exp -= nextExpForLevel(unit.level);
      unit.level += 1;
      const gains = rollLevelGrowth(unit.stats, unitDef.growths, rng);
      if (gains.includes("hp")) {
        unit.hp += 1;
      }
      logs.push(`${unitDef.name} \u5347\u5230 Lv.${unit.level}\uFF1A${formatGains(gains)}\u3002`);
    }
    return logs;
  }
  function addAward(awards, unitId, amount) {
    awards.set(unitId, (awards.get(unitId) ?? 0) + amount);
  }
  function rollLevelGrowth(stats, growths, rng) {
    const gains = [];
    for (const stat of growthStats) {
      if (rollPercent(rng, growths[stat], false)) {
        stats[stat] += 1;
        gains.push(stat);
      }
    }
    if (gains.length === 0) {
      const fallback = growthStats.reduce((best, stat) => growths[stat] > growths[best] ? stat : best, "hp");
      stats[fallback] += 1;
      gains.push(fallback);
    }
    return gains;
  }
  function formatGains(gains) {
    const names = {
      hp: "HP",
      str: "\u529B",
      mag: "\u9B54",
      skill: "\u6280",
      spd: "\u901F",
      luck: "\u8FD0",
      def: "\u9632",
      res: "\u9B54\u9632"
    };
    return gains.map((gain) => `${names[gain]}+1`).join(" ");
  }

  // src/services/combat.ts
  function attackSpeed(unit, weapon) {
    const stats = effectiveStats(unit);
    return stats.spd - Math.max(0, weapon.weight - stats.con);
  }
  function triangleValue(attackerWeapon, defenderWeapon) {
    if (isPhysicalTriangleKind(attackerWeapon.kind) && isPhysicalTriangleKind(defenderWeapon.kind)) {
      return weaponTriangle[attackerWeapon.kind][defenderWeapon.kind];
    }
    if (isMagicTriangleKind(attackerWeapon.kind) && isMagicTriangleKind(defenderWeapon.kind)) {
      return magicTriangle[attackerWeapon.kind][defenderWeapon.kind];
    }
    return 0;
  }
  function effectiveMultiplier(weapon, defender) {
    const tags = classForUnit(defender).tags;
    return weapon.effectiveTags?.some((tag) => tags.includes(tag)) ? COMBAT.effMultiplier : 1;
  }
  function forecastCombat(state, attackerId, defenderId) {
    const attacker = findUnit(state, attackerId);
    const defender = findUnit(state, defenderId);
    const attackerWeapon = getWeapon(attacker.weaponId);
    const defenderWeapon = getWeapon(defender.weaponId);
    const attackerStats = effectiveStats(attacker);
    const defenderStats = effectiveStats(defender);
    const attackerCanUseWeapon = remainingWeaponUses(attacker) > 0;
    const defenderCanUseWeapon = remainingWeaponUses(defender) > 0;
    const cells = distance2(attacker.pos, defender.pos);
    const defenderTerrainId = state.grid[defender.pos.y]?.[defender.pos.x];
    if (!defenderTerrainId) {
      throw new Error(`Defender is outside map: ${defender.id}`);
    }
    const defenderTerrain = getTerrain(defenderTerrainId);
    const triangle = triangleValue(attackerWeapon, defenderWeapon);
    const multiplier = effectiveMultiplier(attackerWeapon, defender);
    const terrainDefense = attackerWeapon.damageKind === "magical" ? 0 : defenderTerrain.defense;
    const rawDefense = attackerWeapon.damageKind === "magical" ? defenderStats.res : defenderStats.def;
    const defense = Math.max(
      0,
      Math.floor((armorBreaks(attacker, attackerWeapon) ? rawDefense * 0.5 : rawDefense) + terrainDefense + defenseBonus(state, defender, defenderTerrain, attackerWeapon.damageKind === "magical"))
    );
    const forgedMight = weaponMight(attacker, attackerWeapon);
    const basePower = attackerWeapon.damageKind === "magical" ? attackerStats.mag + forgedMight + damageBonus(state, attacker, defender, attackerWeapon) : (attackerStats.str + forgedMight + damageBonus(state, attacker, defender, attackerWeapon)) * multiplier;
    const damage = attackerCanUseWeapon ? Math.max(COMBAT.minDamage, Math.floor(basePower + triangle * COMBAT.counterMight - defense)) : 0;
    const terrainAvoid = ignoresTerrainAvoid(attacker, attackerWeapon) ? 0 : defenderTerrain.avoid;
    const hit = attackerCanUseWeapon ? foresightReady(attacker, defender) ? 0 : hitFloor(
      attacker,
      attackerWeapon.hit + attackerStats.skill * 2 + triangle * COMBAT.counterHit + hitBonus(state, attacker) - rangeHitPenalty(attacker, attackerWeapon, cells) - (defenderStats.spd * 2 + defenderStats.luck + terrainAvoid + avoidBonus(state, defender, attackerWeapon))
    ) : 0;
    const rawCrit = critMultiplier(state, attacker) === 100 ? 100 : (attackerWeapon.crit + Math.floor(attackerStats.skill * COMBAT.critFromSkill)) * critMultiplier(state, attacker);
    const crit = attackerCanUseWeapon ? clampPercent(rawCrit - defenderStats.luck - critAvoidBonus(defender)) : 0;
    const followUp = attackerCanUseWeapon && attackSpeed(attacker, attackerWeapon) - attackSpeed(defender, defenderWeapon) >= followUpThreshold(attacker, attackerWeapon);
    return {
      attackerId,
      defenderId,
      distance: cells,
      damage,
      hit,
      crit,
      followUp,
      defenderCanCounter: defenderCanUseWeapon && canUnitAttackAtDistance(defender, defenderWeapon, cells) && defenderWeapon.damageKind !== "healing",
      triangle,
      effectiveMultiplier: multiplier
    };
  }
  function resolveCombat(state, attackerId, defenderId) {
    const attacker = findUnit(state, attackerId);
    const intendedDefender = findUnit(state, defenderId);
    const attackerWeapon = getWeapon(attacker.weaponId);
    if (!canUnitAttackAtDistance(attacker, attackerWeapon, distance2(attacker.pos, intendedDefender.pos)) || attackerWeapon.damageKind === "healing") {
      throw new Error(`${attacker.id} cannot attack ${intendedDefender.id}`);
    }
    if (remainingWeaponUses(attacker) <= 0) {
      throw new Error(`${attacker.id} \u7684 ${attackerWeapon.name} \u8010\u4E45\u8017\u5C3D\u3002`);
    }
    const defender = sisterGuardTarget(state, attacker, intendedDefender) ?? intendedDefender;
    if (defender.id !== intendedDefender.id) {
      defender.skillUses.sister_guard = (defender.skillUses.sister_guard ?? 0) + 1;
    }
    const forecast = forecastCombat(state, attackerId, defender.id);
    const defenderWeapon = getWeapon(defender.weaponId);
    const rng = createRng(state.rngState);
    const events = [];
    const reactionLogs = defender.id === intendedDefender.id ? [] : [`${unitName(state, defender.id)} \u62A4\u4F4F ${unitName(state, intendedDefender.id)}\u3002`];
    strike(state, rng, events, attacker, defender);
    if (defender.alive && attacker.alive && hasSkill(attacker, "adept") && rollPercent(rng, effectiveStats(attacker).skill, false)) {
      strike(state, rng, events, attacker, defender);
    }
    if (defender.alive && attacker.alive) {
      const counterUnit = forecast.defenderCanCounter ? defender : guardLungeCounter(state, defender, attacker);
      if (counterUnit) {
        if (counterUnit.id !== defender.id) {
          counterUnit.skillUses.guard_lunge = (counterUnit.skillUses.guard_lunge ?? 0) + 1;
          reactionLogs.push(`${unitName(state, counterUnit.id)} \u63F4\u62A4 ${unitName(state, defender.id)} \u53CD\u51FB\u3002`);
        }
        strike(state, rng, events, counterUnit, attacker);
      }
    }
    if (defender.alive && attacker.alive && forecast.followUp) {
      strike(state, rng, events, attacker, defender);
    }
    if (defender.alive && attacker.alive && attackSpeed(defender, defenderWeapon) - attackSpeed(attacker, attackerWeapon) >= followUpThreshold(defender, defenderWeapon)) {
      strike(state, rng, events, defender, attacker);
    }
    const movementLogs = rangerSkirmishStepBack(state, attacker, defender);
    const expLogs = awardCombatExperience(state, rng, events);
    state.rngState = rng.state;
    state.log.unshift(...reactionLogs, ...eventsToLog(state, events), ...movementLogs, ...expLogs);
    return { forecast, events };
  }
  function strike(state, rng, events, source, target) {
    const sourceWeapon = getWeapon(source.weaponId);
    if (remainingWeaponUses(source) <= 0) {
      return;
    }
    const forecast = forecastCombat(state, source.id, target.id);
    const remainingUses = spendWeaponUse(source);
    if (foresightReady(source, target)) {
      target.skillUses.foresight = (target.skillUses.foresight ?? 0) + 1;
      events.push({ type: "miss", sourceId: source.id, targetId: target.id });
      if (remainingUses === 0) {
        events.push({ type: "weaponBreak", sourceId: source.id, weaponId: sourceWeapon.id });
      }
      return;
    }
    const hit = rollPercent(rng, forecast.hit, COMBAT.doubleRNG);
    if (!hit) {
      events.push({ type: "miss", sourceId: source.id, targetId: target.id });
      if (remainingUses === 0) {
        events.push({ type: "weaponBreak", sourceId: source.id, weaponId: sourceWeapon.id });
      }
      return;
    }
    const critical = rollPercent(rng, forecast.crit, false);
    const rawDamage = critical ? forecast.damage * 3 : forecast.damage;
    const damage = hasStatus(target, "aegis") ? Math.max(COMBAT.minDamage, Math.floor(rawDamage / 2)) : rawDamage;
    const targetDef = getUnitDef(target.defId);
    const mercy = hasSkill(source, "mercy") && targetDef.defeatBehavior === "retreat" && target.hp <= damage;
    const dealt = mercy ? Math.max(0, target.hp - 1) : damage;
    target.hp = mercy ? 1 : Math.max(0, target.hp - damage);
    events.push({ type: "hit", sourceId: source.id, targetId: target.id, damage: dealt, critical, remainingHp: target.hp });
    if (hasStatus(source, "poison_blade")) {
      addStatus(target, { id: "poison", turns: 3 });
    }
    if (!mercy && target.hp === 0) {
      target.alive = false;
      target.acted = true;
      primeBloodMemory(state, target);
      events.push({ type: "defeat", sourceId: source.id, targetId: target.id, retreat: targetDef.defeatBehavior === "retreat" });
    }
    if (remainingUses === 0) {
      events.push({ type: "weaponBreak", sourceId: source.id, weaponId: sourceWeapon.id });
    }
  }
  function eventsToLog(state, events) {
    return events.map((event) => {
      const sourceName = unitName(state, event.sourceId);
      if (event.type === "miss") {
        const targetName = unitName(state, event.targetId);
        return `${sourceName} \u7684\u653B\u51FB\u843D\u7A7A\u3002`;
      }
      if (event.type === "defeat") {
        const targetName = unitName(state, event.targetId);
        return event.retreat ? `${targetName} \u64A4\u9000\u3002` : `${targetName} \u5012\u4E0B\u3002`;
      }
      if (event.type === "weaponBreak") {
        return `${sourceName} \u7684${getWeapon(event.weaponId).name}\u635F\u574F\u3002`;
      }
      return `${sourceName} \u9020\u6210 ${event.damage} \u70B9\u4F24\u5BB3${event.critical ? "\uFF01" : "\u3002"}`;
    });
  }
  function unitName(state, instanceId) {
    const unit = state.units.find((candidate) => candidate.id === instanceId);
    return unit ? getUnitDef(unit.defId).name : instanceId;
  }
  function sisterGuardTarget(state, attacker, defender) {
    const weapon = getWeapon(attacker.weaponId);
    return state.units.find(
      (candidate) => candidate.alive && candidate.team === defender.team && candidate.id !== defender.id && hasSkill(candidate, "sister_guard") && (candidate.skillUses.sister_guard ?? 0) === 0 && distance2(candidate.pos, defender.pos) <= 1 && canUnitAttackAtDistance(attacker, weapon, distance2(attacker.pos, candidate.pos))
    );
  }
  function guardLungeCounter(state, defender, attacker) {
    return state.units.find((candidate) => {
      if (!candidate.alive || candidate.team !== defender.team || candidate.id === defender.id || !hasSkill(candidate, "guard_lunge") || (candidate.skillUses.guard_lunge ?? 0) > 0 || distance2(candidate.pos, defender.pos) > 1) {
        return false;
      }
      const weapon = getWeapon(candidate.weaponId);
      return remainingWeaponUses(candidate) > 0 && weapon.damageKind !== "healing" && canUnitAttackAtDistance(candidate, weapon, distance2(candidate.pos, attacker.pos));
    });
  }
  function rangerSkirmishStepBack(state, attacker, defender) {
    if (!attacker.alive || !hasSkill(attacker, "ranger_skirmish")) {
      return [];
    }
    const currentDistance = distance2(attacker.pos, defender.pos);
    const destination = neighbors(attacker.pos).filter(
      (cell) => distance2(cell, defender.pos) > currentDistance && !unitAt(state, cell.x, cell.y) && movementCost(state, attacker, cell) != null
    ).sort((left, right) => distance2(right, defender.pos) - distance2(left, defender.pos))[0];
    if (!destination) {
      return [];
    }
    attacker.pos = destination;
    attacker.moved = true;
    return [`${unitName(state, attacker.id)} \u6E38\u51FB\u540E\u64A4\u3002`];
  }
  function clampPercent(value) {
    return Math.max(0, Math.min(100, Math.floor(value)));
  }
  function hitFloor(attacker, value) {
    const hit = clampPercent(value);
    return hasSkill(attacker, "steady_hand") ? Math.max(60, hit) : hit;
  }

  // src/services/skills.ts
  function activeSkills2(unit) {
    if (hasStatus(unit, "silence")) {
      return [];
    }
    return unit.skillIds.map((id) => getSkill(id)).filter((skill) => skill.kind === "active" || skill.kind === "stigma" || skill.kind === "class" && skill.trigger === "manual");
  }
  function skillRequiresTarget(skillId) {
    return !["aegis", "charge", "fortify", "poison_blade", "rally_defense", "rally_speed", "sprint", "stigma_awaken", "stigma_roar", "stigma_seal"].includes(skillId);
  }
  function activateSkill(state, unitId, skillId, targetId) {
    const unit = findUnit(state, unitId);
    if (!unit.alive || unit.acted) {
      return { ok: false, message: "\u8BE5\u5355\u4F4D\u5DF2\u7ECF\u65E0\u6CD5\u884C\u52A8\u3002" };
    }
    if (!unit.skillIds.includes(skillId)) {
      return { ok: false, message: "\u8BE5\u5355\u4F4D\u4E0D\u4F1A\u8FD9\u4E2A\u6280\u80FD\u3002" };
    }
    if (hasStatus(unit, "silence")) {
      return { ok: false, message: "\u8BE5\u5355\u4F4D\u88AB\u5C01\u6280\uFF0C\u65E0\u6CD5\u4F7F\u7528\u4E3B\u52A8\u6280\u80FD\u3002" };
    }
    if ((unit.skillUses[skillUseKey(state, skillId)] ?? 0) >= useLimit(skillId)) {
      return { ok: false, message: "\u672C\u6218\u6B21\u6570\u5DF2\u7528\u5B8C\u3002" };
    }
    if (skillId === "healing_wave") {
      return activateHealingWave(state, unit, targetId);
    }
    if (skillId === "stigma_awaken") {
      return activateStigma(state, unit);
    }
    if (skillId === "aegis") {
      addStatus(unit, { id: "aegis", turns: 1 });
      spendSkill(state, unit, skillId);
      unit.acted = true;
      return pushResult(state, true, `${unitName2(unit)} \u5C55\u5F00\u5723\u76FE\uFF0C\u672C\u56DE\u5408\u53D7\u4F24\u51CF\u534A\u3002`);
    }
    if (skillId === "sprint") {
      addStatus(unit, { id: "sprint", turns: 1 });
      spendSkill(state, unit, skillId);
      return pushResult(state, true, `${unitName2(unit)} \u75BE\u8D70\uFF0C\u672C\u56DE\u5408\u79FB\u52A8 +3\u3002`);
    }
    if (skillId === "charge") {
      return activateCharge(state, unit);
    }
    if (skillId === "poison_blade") {
      return activatePoisonBlade(state, unit);
    }
    if (skillId === "rally_defense" || skillId === "rally_speed") {
      return activateRally(state, unit, skillId);
    }
    if (skillId === "barrier") {
      return activateBarrier(state, unit, targetId);
    }
    if (skillId === "fortify") {
      return activateFortify(state, unit);
    }
    if (skillId === "mark_target" || skillId === "silence" || skillId === "taunt") {
      return activateDebuff(state, unit, targetId, skillId);
    }
    if (skillId === "freeze_field") {
      return activateFreezeField(state, unit, targetId);
    }
    if (skillId === "swap") {
      return activateSwap(state, unit, targetId);
    }
    if (skillId === "shove" || skillId === "smite") {
      return activatePush(state, unit, targetId, skillId === "smite" ? 2 : 1);
    }
    if (skillId === "rescue_pull") {
      return activateRescuePull(state, unit, targetId);
    }
    if (skillId === "falcon_mercy") {
      return activateFalconMercy(state, unit, targetId);
    }
    if (skillId === "gale_cross") {
      return activateGaleCross(state, unit, targetId);
    }
    if (skillId === "piercing_shot") {
      return activatePiercingShot(state, unit, targetId);
    }
    if (skillId === "meteor") {
      return activateMeteor(state, unit, targetId);
    }
    if (skillId === "resurrection") {
      return activateResurrection(state, unit, targetId);
    }
    if (skillId === "saint_refresh") {
      return activateSaintRefresh(state, unit, targetId);
    }
    if (skillId === "stigma_seal") {
      return activateStigmaSeal(state, unit);
    }
    if (skillId === "stigma_roar") {
      return activateStigmaRoar(state, unit);
    }
    return { ok: false, message: "\u8FD9\u4E2A\u6280\u80FD\u5C1A\u672A\u63A5\u5165\u5B9E\u88C5\u6548\u679C\u3002" };
  }
  function refreshRound(state) {
    for (const unit of livingUnits(state)) {
      applyStatusEffects(state, unit);
      tickStatuses(unit);
      applyTerrainEffects(state, unit);
      if (unit.team === "ally") {
        accrueAdjacentBonds(state, unit);
      }
    }
    for (const unit of state.units) {
      unit.moved = false;
      unit.cantoMoveLeft = 0;
    }
  }
  function applyStatusEffects(state, unit) {
    if (hasStatus(unit, "poison")) {
      const damage = Math.max(1, Math.floor(unit.stats.hp * 0.1));
      unit.hp = Math.max(0, unit.hp - damage);
      state.log.unshift(`${unitName2(unit)} \u6BD2\u53D1 ${damage} \u70B9\u3002`);
      if (unit.hp === 0) {
        unit.alive = false;
        unit.acted = true;
        primeBloodMemory(state, unit);
        state.log.unshift(`${unitName2(unit)} \u6BD2\u53D1\u5012\u4E0B\u3002`);
      }
    }
  }
  function applyTerrainEffects(state, unit) {
    const terrain = terrainAt(state, unit.pos);
    if (terrain.effects.includes("regen10") || terrain.effects.includes("bossRegen")) {
      const amount = Math.max(1, Math.floor(unit.stats.hp * 0.1));
      const before = unit.hp;
      unit.hp = Math.min(unit.stats.hp, unit.hp + amount);
      if (unit.hp > before) {
        state.log.unshift(`${unitName2(unit)} \u501F\u52A9${terrain.name}\u6062\u590D ${unit.hp - before} \u70B9\u3002`);
      }
    }
    if (terrain.effects.includes("poison")) {
      const damage = Math.max(1, Math.floor(unit.stats.hp * 0.1));
      unit.hp = Math.max(0, unit.hp - damage);
      state.log.unshift(`${unitName2(unit)} \u88AB${terrain.name}\u4FB5\u8680 ${damage} \u70B9\u3002`);
      if (unit.hp === 0) {
        unit.alive = false;
        unit.acted = true;
        primeBloodMemory(state, unit);
        state.log.unshift(`${unitName2(unit)} \u5012\u5728${terrain.name}\u4E2D\u3002`);
      }
    }
  }
  function activateHealingWave(state, unit, targetId) {
    if (!targetId) {
      return { ok: false, message: "\u8BF7\u9009\u62E9\u6CBB\u7597\u76EE\u6807\u3002" };
    }
    const target = findUnit(state, targetId);
    if (target.team !== unit.team || !target.alive) {
      return { ok: false, message: "\u53EA\u80FD\u6CBB\u7597\u5B58\u6D3B\u53CB\u519B\u3002" };
    }
    if (distance2(unit.pos, target.pos) > 1) {
      return { ok: false, message: "\u6CBB\u7597\u8DDD\u79BB\u4E0D\u8DB3\u3002" };
    }
    const weapon = getWeapon(unit.weaponId);
    const amount = healingAmount(state, unit, Math.max(1, weapon.might + unit.stats.mag));
    const before = target.hp;
    target.hp = Math.min(target.stats.hp, target.hp + amount);
    spendSkill(state, unit, "healing_wave");
    unit.acted = true;
    addBond(state, unit.defId, target.defId, 5);
    const rng = createRng(state.rngState);
    const expLogs = gainExperience(state, rng, unit, GROWTH.supportExp);
    state.rngState = rng.state;
    state.log.unshift(...expLogs);
    return pushResult(state, true, `${unitName2(unit)} \u6CBB\u7597 ${unitName2(target)} ${target.hp - before} \u70B9\u3002`);
  }
  function activateStigma(state, unit) {
    const classDef = classForUnit(unit);
    if (!classDef.tags.includes("dragon")) {
      return { ok: false, message: "\u53EA\u6709\u9F99\u88D4\u80FD\u89C9\u9192\u9F99\u75D5\u3002" };
    }
    if (hasStatus(unit, "stigma_awaken")) {
      return { ok: false, message: "\u9F99\u75D5\u5DF2\u7ECF\u89C9\u9192\u3002" };
    }
    const empowered = consumeBloodMemory(unit);
    addStatus(unit, { id: "stigma_awaken", turns: empowered ? 4 : 3 });
    spendSkill(state, unit, "stigma_awaken");
    unit.acted = true;
    const taintKey = `dragonTaint:${unit.defId}`;
    const taintGain = stigmaTaintGain(state, unit, 1);
    const nextTaint = Number(state.flags[taintKey] ?? 0) + taintGain;
    state.flags[taintKey] = nextTaint;
    return pushResult(state, true, `${unitName2(unit)} \u89E3\u653E\u9F99\u75D5\uFF0C${empowered ? "\u8840\u5FC6\u5EF6\u957F\u89C9\u9192\uFF0C" : ""}\u9F99\u5316\u503C ${taintGain > 0 ? `+${taintGain}` : "\u672A\u589E\u52A0"}\u3002`);
  }
  function activateCharge(state, unit) {
    if (!classForUnit(unit).tags.includes("cavalry")) {
      return { ok: false, message: "\u53EA\u6709\u9A91\u5175\u80FD\u53D1\u52A8\u51B2\u950B\u3002" };
    }
    const bonus = Math.max(1, Math.floor(effectiveStats(unit).move / 2));
    addStatus(unit, { id: "charge", turns: 1, value: bonus });
    spendSkill(state, unit, "charge");
    return pushResult(state, true, `${unitName2(unit)} \u67B6\u67AA\u51B2\u950B\uFF0C\u4E0B\u6B21\u653B\u51FB\u5A01\u529B +${bonus}\u3002`);
  }
  function activatePoisonBlade(state, unit) {
    if (!classForUnit(unit).tags.includes("scout")) {
      return { ok: false, message: "\u53EA\u6709\u65A5\u5019\u7CFB\u80FD\u6DEC\u6BD2\u3002" };
    }
    addStatus(unit, { id: "poison_blade", turns: 1 });
    spendSkill(state, unit, "poison_blade");
    return pushResult(state, true, `${unitName2(unit)} \u4E3A\u6B66\u5668\u6DEC\u6BD2\uFF0C\u4E0B\u6B21\u547D\u4E2D\u65BD\u52A0\u4E2D\u6BD2\u3002`);
  }
  function activateRally(state, unit, skillId) {
    const targets = adjacentUnits(state, unit).filter((target) => target.team === unit.team);
    if (targets.length === 0) {
      return { ok: false, message: "\u5468\u56F4\u6CA1\u6709\u53EF\u53F7\u4EE4\u7684\u53CB\u519B\u3002" };
    }
    const statusId = skillId === "rally_defense" ? "rally_defense" : "rally_speed";
    for (const target of targets) {
      addStatus(target, { id: statusId, turns: 2 });
    }
    spendSkill(state, unit, skillId);
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u53D1\u51FA\u53F7\u4EE4\uFF0C\u5F3A\u5316 ${targets.length} \u540D\u53CB\u519B\u3002`);
  }
  function activateBarrier(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target) {
      return { ok: false, message: "\u8BF7\u9009\u62E9\u5C4F\u969C\u76EE\u6807\u3002" };
    }
    if (target.team !== unit.team || !target.alive || distance2(unit.pos, target.pos) > 2) {
      return { ok: false, message: "\u5C4F\u969C\u53EA\u80FD\u8D4B\u4E88\u8FD1\u5904\u53CB\u519B\u3002" };
    }
    addStatus(target, { id: "barrier", turns: 2 });
    spendSkill(state, unit, "barrier");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u4E3A ${unitName2(target)} \u5C55\u5F00\u9B54\u9632\u5C4F\u969C\u3002`);
  }
  function activateFortify(state, unit) {
    const targets = adjacentUnits(state, unit).filter((target) => target.team === unit.team && target.hp < target.stats.hp);
    if (targets.length === 0) {
      return { ok: false, message: "\u5468\u56F4\u6CA1\u6709\u53D7\u4F24\u53CB\u519B\u3002" };
    }
    const amount = healingAmount(state, unit, Math.max(1, Math.floor(effectiveStats(unit).mag / 2) + 8));
    for (const target of targets) {
      target.hp = Math.min(target.stats.hp, target.hp + amount);
      addBond(state, unit.defId, target.defId, 3);
    }
    spendSkill(state, unit, "fortify");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u65BD\u653E\u7FA4\u4F53\u6CBB\u7597\uFF0C\u6062\u590D ${targets.length} \u540D\u53CB\u519B\u3002`);
  }
  function activateDebuff(state, unit, targetId, skillId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team === unit.team || !target.alive) {
      return { ok: false, message: "\u8BF7\u9009\u62E9\u654C\u65B9\u76EE\u6807\u3002" };
    }
    const maxRange = skillId === "taunt" ? 1 : 3;
    if (distance2(unit.pos, target.pos) > maxRange) {
      return { ok: false, message: "\u6280\u80FD\u8DDD\u79BB\u4E0D\u8DB3\u3002" };
    }
    if (skillId === "mark_target") {
      addStatus(target, { id: "marked", turns: 2 });
    } else if (skillId === "silence") {
      addStatus(target, { id: "silence", turns: 1 });
    } else {
      addStatus(target, { id: "taunted", turns: 1, sourceId: unit.id });
    }
    spendSkill(state, unit, skillId);
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u5BF9 ${unitName2(target)} \u53D1\u52A8${getSkill(skillId).name}\u3002`);
  }
  function activateFreezeField(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team === unit.team || !target.alive || distance2(unit.pos, target.pos) > 3) {
      return { ok: false, message: "\u8BF7\u9009\u62E9 3 \u683C\u5185\u654C\u65B9\u76EE\u6807\u3002" };
    }
    const targets = livingUnits(state, target.team).filter((enemy) => distance2(enemy.pos, target.pos) <= 1);
    for (const enemy of targets) {
      addStatus(enemy, { id: "frozen", turns: 2 });
    }
    spendSkill(state, unit, "freeze_field");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u51BB\u7ED3\u533A\u57DF\uFF0C\u51CF\u901F ${targets.length} \u540D\u654C\u4EBA\u3002`);
  }
  function activateSwap(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team !== unit.team || !target.alive || distance2(unit.pos, target.pos) !== 1) {
      return { ok: false, message: "\u53EA\u80FD\u4E0E\u76F8\u90BB\u53CB\u519B\u6362\u4F4D\u3002" };
    }
    const unitPos = unit.pos;
    unit.pos = target.pos;
    target.pos = unitPos;
    spendSkill(state, unit, "swap");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u4E0E ${unitName2(target)} \u6362\u4F4D\u3002`);
  }
  function activatePush(state, unit, targetId, steps) {
    const target = targetedUnit(state, targetId);
    if (!target || !target.alive || distance2(unit.pos, target.pos) !== 1) {
      return { ok: false, message: "\u53EA\u80FD\u63A8\u52A8\u76F8\u90BB\u5355\u4F4D\u3002" };
    }
    const dx = Math.sign(target.pos.x - unit.pos.x);
    const dy = Math.sign(target.pos.y - unit.pos.y);
    if (!moveForced(state, target, { x: dx, y: dy }, steps)) {
      return { ok: false, message: "\u63A8\u52A8\u8DEF\u5F84\u88AB\u963B\u6321\u3002" };
    }
    spendSkill(state, unit, steps === 2 ? "smite" : "shove");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u63A8\u5F00 ${unitName2(target)}\u3002`);
  }
  function activateRescuePull(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team !== unit.team || !target.alive || target.id === unit.id || distance2(unit.pos, target.pos) > 2) {
      return { ok: false, message: "\u8BF7\u9009\u62E9 2 \u683C\u5185\u53CB\u519B\u3002" };
    }
    const destination = neighbors(unit.pos).filter((cell) => canEnterForced(state, target, cell)).sort((a, b) => distance2(a, target.pos) - distance2(b, target.pos))[0];
    if (!destination) {
      return { ok: false, message: "\u8EAB\u8FB9\u6CA1\u6709\u53EF\u62C9\u5165\u7684\u7A7A\u683C\u3002" };
    }
    target.pos = destination;
    spendSkill(state, unit, "rescue_pull");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u5C06 ${unitName2(target)} \u62C9\u56DE\u8EAB\u8FB9\u3002`);
  }
  function activateFalconMercy(state, unit, targetId) {
    if (classForUnit(unit).id !== "falcon_knight") {
      return { ok: false, message: "\u53EA\u6709\u96BC\u9A91\u80FD\u53D1\u52A8\u6551\u62A4\u3002" };
    }
    const target = targetedUnit(state, targetId);
    if (!target || target.team !== unit.team || !target.alive || target.id === unit.id || distance2(unit.pos, target.pos) !== 1) {
      return { ok: false, message: "\u53EA\u80FD\u6551\u62A4\u76F8\u90BB\u53CB\u519B\u3002" };
    }
    const destination = neighbors(unit.pos).filter((cell) => canEnterForced(state, target, cell)).sort((a, b) => compareCarryDestinations(state, target, a, b))[0];
    if (!destination) {
      return { ok: false, message: "\u8EAB\u8FB9\u6CA1\u6709\u53EF\u653E\u4E0B\u7684\u7A7A\u683C\u3002" };
    }
    target.pos = destination;
    spendSkill(state, unit, "falcon_mercy");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u5E26\u79BB ${unitName2(target)}\u3002`);
  }
  function activateGaleCross(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    const weapon = getWeapon(unit.weaponId);
    if (!target || target.team === unit.team || !target.alive || !canUnitAttackAtDistance(unit, weapon, distance2(unit.pos, target.pos))) {
      return { ok: false, message: "\u8BF7\u9009\u62E9\u5C04\u7A0B\u5185\u654C\u4EBA\u3002" };
    }
    const targets = livingUnits(state, target.team).filter((enemy) => distance2(enemy.pos, target.pos) <= 1);
    const damage = targets.reduce((sum, enemy) => sum + dealSkillDamage(state, unit, enemy, weapon.damageKind === "magical"), 0);
    spendSkill(state, unit, "gale_cross");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u65BD\u5C55\u75BE\u98CE\u8FDE\u65A9\uFF0C\u9020\u6210\u5408\u8BA1 ${damage} \u70B9\u3002`);
  }
  function activatePiercingShot(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team === unit.team || !target.alive || getWeapon(unit.weaponId).kind !== "bow" || !sameLine(unit.pos, target.pos) || distance2(unit.pos, target.pos) > 4) {
      return { ok: false, message: "\u8D2F\u901A\u5C04\u51FB\u9700\u8981 4 \u683C\u5185\u76F4\u7EBF\u654C\u4EBA\u3002" };
    }
    const targets = livingUnits(state, target.team).filter((enemy) => sameRay(unit.pos, target.pos, enemy.pos) && distance2(unit.pos, enemy.pos) <= distance2(unit.pos, target.pos));
    const damage = targets.reduce((sum, enemy) => sum + dealSkillDamage(state, unit, enemy, false), 0);
    spendSkill(state, unit, "piercing_shot");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u8D2F\u901A\u5C04\u51FB\u547D\u4E2D ${targets.length} \u540D\u654C\u4EBA\uFF0C\u5408\u8BA1 ${damage} \u70B9\u3002`);
  }
  function activateMeteor(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team === unit.team || !target.alive || distance2(unit.pos, target.pos) > 4) {
      return { ok: false, message: "\u8BF7\u9009\u62E9 4 \u683C\u5185\u654C\u4EBA\u3002" };
    }
    const damage = dealSkillDamage(state, unit, target, true, 8);
    spendSkill(state, unit, "meteor");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u53EC\u4E0B\u9668\u661F\uFF0C\u9020\u6210 ${damage} \u70B9\u3002`);
  }
  function activateResurrection(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team !== unit.team || target.alive || distance2(unit.pos, target.pos) > 1 || unitAt(state, target.pos.x, target.pos.y)) {
      return { ok: false, message: "\u53EA\u80FD\u590D\u6D3B\u76F8\u90BB\u5012\u4E0B\u53CB\u519B\u3002" };
    }
    target.alive = true;
    target.acted = true;
    target.hp = Math.max(1, Math.floor(target.stats.hp / 2));
    target.statuses = [];
    spendSkill(state, unit, "resurrection");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u590D\u6D3B ${unitName2(target)}\u3002`);
  }
  function activateSaintRefresh(state, unit, targetId) {
    const target = targetedUnit(state, targetId);
    if (!target || target.team !== unit.team || !target.alive || target.id === unit.id || distance2(unit.pos, target.pos) > 1 || !target.acted) {
      return { ok: false, message: "\u53EA\u80FD\u9F13\u821E\u76F8\u90BB\u4E14\u5DF2\u884C\u52A8\u53CB\u519B\u3002" };
    }
    target.acted = false;
    spendSkill(state, unit, "saint_refresh");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u9F13\u821E ${unitName2(target)} \u518D\u6B21\u884C\u52A8\u3002`);
  }
  function activateStigmaSeal(state, unit) {
    const key = `dragonTaint:${unit.defId}`;
    const taint = Number(state.flags[key] ?? 0);
    if (taint <= 0 || unit.hp <= 5) {
      return { ok: false, message: "\u9F99\u5316\u503C\u6216\u751F\u547D\u4E0D\u8DB3\uFF0C\u65E0\u6CD5\u5C01\u5370\u3002" };
    }
    unit.hp -= 5;
    state.flags[key] = taint - 1;
    spendSkill(state, unit, "stigma_seal");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u4EE5\u751F\u547D\u5C01\u5370\u9F99\u75D5\uFF0C\u9F99\u5316\u503C -1\u3002`);
  }
  function activateStigmaRoar(state, unit) {
    if (!classForUnit(unit).tags.includes("dragon")) {
      return { ok: false, message: "\u53EA\u6709\u9F99\u88D4\u80FD\u53D1\u52A8\u9F99\u543C\u3002" };
    }
    const targets = livingUnits(state, unit.team === "ally" ? "enemy" : "ally").filter((enemy) => distance2(unit.pos, enemy.pos) <= 2);
    if (targets.length === 0) {
      return { ok: false, message: "\u5468\u56F4\u6CA1\u6709\u53EF\u9707\u6151\u76EE\u6807\u3002" };
    }
    const empowered = consumeBloodMemory(unit);
    for (const target of targets) {
      addStatus(target, { id: "frozen", turns: empowered ? 2 : 1 });
      const dx = Math.sign(target.pos.x - unit.pos.x);
      const dy = Math.sign(target.pos.y - unit.pos.y);
      moveForced(state, target, { x: dx, y: dy }, 1);
    }
    const key = `dragonTaint:${unit.defId}`;
    const taintGain = stigmaTaintGain(state, unit, 1);
    state.flags[key] = Number(state.flags[key] ?? 0) + taintGain;
    spendSkill(state, unit, "stigma_roar");
    unit.acted = true;
    return pushResult(state, true, `${unitName2(unit)} \u53D1\u51FA\u9F99\u543C\uFF0C\u9707\u6151 ${targets.length} \u540D\u654C\u4EBA\uFF0C\u9F99\u5316\u503C ${taintGain > 0 ? `+${taintGain}` : "\u672A\u589E\u52A0"}\u3002`);
  }
  function accrueAdjacentBonds(state, unit) {
    for (const other of livingUnits(state, "ally")) {
      if (unit.id >= other.id || distance2(unit.pos, other.pos) > 1) {
        continue;
      }
      addBond(state, unit.defId, other.defId, 3);
    }
  }
  function addBond(state, left, right, amount) {
    if (left === right) {
      return;
    }
    const key = bondKey(left, right);
    state.bonds[key] = Math.min(BOND.S, (state.bonds[key] ?? 0) + amount);
  }
  function adjacentUnits(state, unit) {
    return livingUnits(state).filter((target) => target.id !== unit.id && distance2(unit.pos, target.pos) <= 1);
  }
  function healingAmount(state, unit, baseAmount) {
    if (!hasSkill(unit, "holy_focus")) {
      return baseAmount;
    }
    const rng = createRng(state.rngState);
    const focused = rollPercent(rng, effectiveStats(unit).skill, false);
    state.rngState = rng.state;
    return focused ? baseAmount + Math.max(1, Math.floor(baseAmount / 2)) : baseAmount;
  }
  function stigmaTaintGain(state, unit, baseGain) {
    if (baseGain <= 0 || !hasSkill(unit, "forbidden_vow")) {
      return baseGain;
    }
    return adjacentUnits(state, unit).some((target) => target.team === unit.team) ? baseGain - 1 : baseGain;
  }
  function targetedUnit(state, targetId) {
    return targetId ? findUnit(state, targetId) : void 0;
  }
  function moveForced(state, target, delta, steps) {
    if (hasSkill(target, "bulwark")) {
      return false;
    }
    const start = { ...target.pos };
    for (let step = 0; step < steps; step += 1) {
      const next = { x: target.pos.x + delta.x, y: target.pos.y + delta.y };
      if (!canEnterForced(state, target, next)) {
        target.pos = start;
        return false;
      }
      target.pos = next;
    }
    return true;
  }
  function canEnterForced(state, target, cell) {
    return inBounds2(state, cell) && !unitAt(state, cell.x, cell.y) && movementCost(state, target, cell) != null;
  }
  function compareCarryDestinations(state, target, a, b) {
    const safetyA = nearestEnemyDistance(state, target, a);
    const safetyB = nearestEnemyDistance(state, target, b);
    if (safetyA !== safetyB) {
      return safetyB - safetyA;
    }
    const carryA = distance2(a, target.pos);
    const carryB = distance2(b, target.pos);
    if (carryA !== carryB) {
      return carryB - carryA;
    }
    return a.x - b.x || a.y - b.y;
  }
  function nearestEnemyDistance(state, target, cell) {
    const enemies = livingUnits(state, target.team === "ally" ? "enemy" : "ally");
    if (enemies.length === 0) {
      return Number.POSITIVE_INFINITY;
    }
    return Math.min(...enemies.map((enemy) => distance2(cell, enemy.pos)));
  }
  function dealSkillDamage(state, source, target, magical, bonus = 0) {
    const sourceStats = effectiveStats(source);
    const targetStats = effectiveStats(target);
    const weapon = getWeapon(source.weaponId);
    const attack = (magical ? sourceStats.mag : sourceStats.str) + (weapon.damageKind === "healing" ? 0 : weapon.might) + bonus;
    const defense = magical ? targetStats.res : targetStats.def;
    const damage = Math.max(1, attack - defense);
    target.hp = Math.max(0, target.hp - damage);
    if (target.hp === 0) {
      target.alive = false;
      target.acted = true;
    }
    return damage;
  }
  function sameLine(left, right) {
    return left.x === right.x || left.y === right.y;
  }
  function sameRay(origin, target, candidate) {
    if (origin.x === target.x) {
      return candidate.x === origin.x && Math.sign(candidate.y - origin.y) === Math.sign(target.y - origin.y);
    }
    if (origin.y === target.y) {
      return candidate.y === origin.y && Math.sign(candidate.x - origin.x) === Math.sign(target.x - origin.x);
    }
    return false;
  }
  function spendSkill(state, unit, skillId) {
    const key = skillUseKey(state, skillId);
    unit.skillUses[key] = (unit.skillUses[key] ?? 0) + 1;
  }
  function useLimit(skillId) {
    if (skillId === "healing_wave") {
      return 99;
    }
    if (skillId === "swap" || skillId === "shove" || skillId === "mark_target") {
      return 99;
    }
    if (skillId === "aegis" || skillId === "barrier" || skillId === "rally_defense" || skillId === "rally_speed") {
      return 2;
    }
    return 1;
  }
  function skillUseKey(state, skillId) {
    return skillId === "charge" ? `${skillId}:turn:${state.turn}` : skillId;
  }
  function pushResult(state, ok, message) {
    state.log.unshift(message);
    return { ok, message };
  }
  function unitName2(unit) {
    return getUnitDef(unit.defId).name;
  }

  // src/services/ai.ts
  function chooseEnemyAction(state, enemy) {
    const tauntSourceId = enemy.statuses.find((status) => status.id === "taunted" && status.turns > 0)?.sourceId;
    const tauntTarget = tauntSourceId ? state.units.find((unit) => unit.id === tauntSourceId && unit.alive) : void 0;
    if (tauntTarget) {
      const forced = bestAttackAction(state, enemy, [tauntTarget]);
      if (forced) {
        return forced.action;
      }
    }
    const best = bestAttackAction(state, enemy, livingUnits(state, "ally"));
    if (best) {
      return best.action;
    }
    const closest = livingUnits(state, "ally").sort((a, b) => distance2(enemy.pos, a.pos) - distance2(enemy.pos, b.pos))[0];
    if (!closest) {
      return { unitId: enemy.id, moveTo: enemy.pos };
    }
    const moveTo = [...reachableCells(state, enemy).values()].filter(({ cell }) => !unitAt(state, cell.x, cell.y) || cellKey2(cell) === cellKey2(enemy.pos)).sort((a, b) => distance2(a.cell, closest.pos) - distance2(b.cell, closest.pos))[0]?.cell ?? enemy.pos;
    return { unitId: enemy.id, moveTo };
  }
  function bestAttackAction(state, enemy, targets) {
    const reachable = reachableCells(state, enemy);
    let best;
    for (const { cell } of reachable.values()) {
      for (const target of targets) {
        const cells = distance2(cell, target.pos);
        const weapon = getWeapon(enemy.weaponId);
        if (remainingWeaponUses(enemy) <= 0 || !canUnitAttackAtDistance(enemy, weapon, cells) || weapon.damageKind === "healing") {
          continue;
        }
        const original = enemy.pos;
        enemy.pos = cell;
        const forecast = forecastCombat(state, enemy.id, target.id);
        enemy.pos = original;
        const killBonus = forecast.damage >= target.hp ? 100 : 0;
        const score = killBonus + forecast.damage * 4 + forecast.hit + forecast.effectiveMultiplier * 10 - target.hp;
        if (!best || score > best.score) {
          best = { action: { unitId: enemy.id, moveTo: cell, attackTargetId: target.id }, score };
        }
      }
    }
    return best;
  }
  function runEnemyTurn(state) {
    state.phase = "enemy";
    processChapterEvents(state, "enemyStart");
    for (const enemy of livingUnits(state, "enemy")) {
      if (isTerminalPhase(state.phase)) {
        break;
      }
      if (enemy.acted) {
        continue;
      }
      const action = chooseEnemyAction(state, enemy);
      executeAiAction(state, action);
      enemy.acted = true;
      updateOutcome(state);
    }
    if (!isTerminalPhase(state.phase)) {
      state.turn += 1;
      for (const unit of state.units) {
        unit.acted = false;
      }
      refreshRound(state);
      state.phase = "player";
      state.log.unshift(`\u7B2C ${state.turn} \u56DE\u5408\u3002`);
      processChapterEvents(state, "playerStart");
      updateOutcome(state);
    }
  }
  function isTerminalPhase(phase) {
    return phase === "victory" || phase === "defeat";
  }
  function executeAiAction(state, action) {
    const unit = findUnit(state, action.unitId);
    moveUnit(state, unit, action.moveTo);
    if (action.attackTargetId) {
      const target = findUnit(state, action.attackTargetId);
      if (target.alive) {
        resolveCombat(state, unit.id, target.id);
      }
    }
  }

  // src/services/chapterVisits.ts
  function visitAt(state, cell) {
    return (getChapter(state.chapterId).visits ?? []).find((visit) => visit.x === cell.x && visit.y === cell.y);
  }
  function canVisit(state, unit) {
    return state.phase === "player" && unit.team === "ally" && unit.alive && !unit.acted && visitForUnit(state, unit) != null;
  }
  function visitChapterSite(state, unitId) {
    const unit = findUnit(state, unitId);
    const visit = visitForUnit(state, unit);
    if (!visit || unit.team !== "ally" || unit.acted || !unit.alive || state.phase !== "player") {
      return { ok: false, message: "\u5F53\u524D\u4F4D\u7F6E\u6CA1\u6709\u53EF\u8BBF\u95EE\u76EE\u6807\u3002" };
    }
    applyVisitReward(state, visit);
    unit.acted = true;
    state.flags[visitFlag(state, visit)] = true;
    state.log.unshift(visit.message);
    return { ok: true, message: visit.message };
  }
  function visitSummary(state, cell) {
    const visit = visitAt(state, cell);
    if (!visit) {
      return void 0;
    }
    return isVisited(state, visit) ? `${visit.label}\uFF08\u5DF2\u8BBF\u95EE\uFF09` : `\u8BBF\u95EE\uFF1A${visit.label}`;
  }
  function visitForUnit(state, unit) {
    const visit = visitAt(state, unit.pos);
    if (!visit || isVisited(state, visit) || !isVisitTerrain(state, unit.pos)) {
      return void 0;
    }
    return visit;
  }
  function applyVisitReward(state, visit) {
    if (visit.gold) {
      state.flags["battleReward:gold"] = Number(state.flags["battleReward:gold"] ?? 0) + visit.gold;
    }
    if (visit.weaponId) {
      const key = `battleReward:item:${visit.weaponId}`;
      state.flags[key] = Number(state.flags[key] ?? 0) + (visit.weaponCount ?? 1);
    }
    if (visit.flag) {
      state.flags[visit.flag] = visit.value ?? true;
    }
  }
  function isVisitTerrain(state, cell) {
    const terrainId = state.grid[cell.y]?.[cell.x];
    return terrainId ? getTerrain(terrainId).effects.includes("visit") : false;
  }
  function isVisited(state, visit) {
    return state.flags[visitFlag(state, visit)] === true;
  }
  function visitFlag(state, visit) {
    return `chapterVisit:${state.chapterId}:${visit.id}`;
  }

  // src/viewmodels/BattleViewModel.ts
  var BattleViewModel = class {
    state;
    selectedUnitId;
    selectedSkillId;
    hoverCell;
    constructor(state) {
      this.state = state;
    }
    get selectedUnit() {
      return this.selectedUnitId ? this.state.units.find((unit) => unit.id === this.selectedUnitId && unit.alive) : void 0;
    }
    get selectedReachable() {
      const unit = this.selectedUnit;
      if (!unit || unit.team !== "ally" || this.state.phase !== "player") {
        return /* @__PURE__ */ new Set();
      }
      if (unit.acted) {
        if ((unit.cantoMoveLeft ?? 0) <= 0) {
          return /* @__PURE__ */ new Set();
        }
        const reachable = [...reachableCells(this.state, unit).values()].filter(({ cost }) => cost <= (unit.cantoMoveLeft ?? 0));
        return new Set(reachable.map(({ cell }) => cellKey2(cell)));
      }
      if (unit.moved) {
        return /* @__PURE__ */ new Set();
      }
      return new Set(reachableCells(this.state, unit).keys());
    }
    get selectedAttackable() {
      const unit = this.selectedUnit;
      if (!this.canAct(unit)) {
        return /* @__PURE__ */ new Set();
      }
      const cells = /* @__PURE__ */ new Set();
      for (const target of this.state.units.filter((candidate) => candidate.alive && candidate.team !== unit.team)) {
        if (this.attackPositionFor(unit, target)) {
          cells.add(cellKey2(target.pos));
        }
      }
      return cells;
    }
    get preview() {
      const unit = this.selectedUnit;
      if (!unit || !this.hoverCell) {
        return void 0;
      }
      const target = unitAt(this.state, this.hoverCell.x, this.hoverCell.y);
      if (!target || target.team === unit.team) {
        return void 0;
      }
      const attackPosition = this.attackPositionFor(unit, target);
      if (remainingWeaponUses(unit) <= 0 || !attackPosition) {
        return void 0;
      }
      const original = unit.pos;
      unit.pos = attackPosition.cell;
      const forecast = forecastCombat(this.state, unit.id, target.id);
      unit.pos = original;
      return forecast;
    }
    selectCell(cell) {
      if (this.state.phase !== "player") {
        return;
      }
      const occupant = unitAt(this.state, cell.x, cell.y);
      const selected = this.selectedUnit;
      if (selected && this.selectedSkillId) {
        this.activateSelectedSkillAt(cell);
        return;
      }
      if (occupant?.team === "ally" && occupant.alive) {
        this.selectedUnitId = occupant.id;
        this.selectedSkillId = void 0;
        this.hoverCell = cell;
        return;
      }
      if (!selected) {
        this.hoverCell = occupant?.alive ? cell : void 0;
        return;
      }
      if (occupant?.team === "enemy") {
        this.attackSelected(occupant);
        return;
      }
      const destination = this.moveDestinationFor(selected, cell);
      if (destination) {
        if (selected.acted) {
          const moved = selected.pos.x !== cell.x || selected.pos.y !== cell.y;
          selected.pos = { ...cell };
          selected.cantoMoveLeft = 0;
          if (moved) {
            selected.moved = true;
          }
          this.selectedUnitId = void 0;
        } else {
          const moved = selected.pos.x !== cell.x || selected.pos.y !== cell.y;
          if (!moveUnit(this.state, selected, cell)) {
            return;
          }
          selected.cantoMoveLeft = hasSkill(selected, "paladin_canto") ? Math.max(0, effectiveStats(selected).move - destination.cost) : 0;
          if (!moved) {
            return;
          }
        }
        this.state.log.unshift(`${unitLabel(selected)} \u79FB\u52A8\u81F3 (${cell.x + 1},${cell.y + 1})\u3002`);
        this.selectedSkillId = void 0;
        updateOutcome(this.state);
        this.autoEndIfDone();
      }
    }
    attackSelected(target) {
      const attacker = this.selectedUnit;
      if (!this.canAct(attacker) || target.team === "ally") {
        return;
      }
      const weapon = getWeapon(attacker.weaponId);
      if (remainingWeaponUses(attacker) <= 0) {
        this.state.log.unshift(`${weapon.name} \u5DF2\u635F\u574F\u3002`);
        return;
      }
      const movedBeforeAction = attacker.moved === true;
      const attackPosition = this.attackPositionFor(attacker, target);
      if (!attackPosition || weapon.damageKind === "healing") {
        this.state.log.unshift("\u5C04\u7A0B\u4E0D\u7B26\u3002");
        return;
      }
      if (!moveUnit(this.state, attacker, attackPosition.cell)) {
        this.state.log.unshift("\u653B\u51FB\u4F4D\u7F6E\u88AB\u963B\u6321\u3002");
        return;
      }
      resolveCombat(this.state, attacker.id, target.id);
      attacker.acted = true;
      this.selectedSkillId = void 0;
      updateOutcome(this.state);
      if (this.primeCanto(attacker, attackPosition.cost, movedBeforeAction)) {
        this.selectedUnitId = attacker.id;
        this.state.log.unshift(`${unitLabel(attacker)} \u53EF\u518D\u79FB\u52A8 ${attacker.cantoMoveLeft} \u683C\u3002`);
        return;
      }
      this.selectedUnitId = void 0;
      this.autoEndIfDone();
    }
    selectSkill(skillId) {
      const unit = this.selectedUnit;
      if (!this.canAct(unit)) {
        return;
      }
      if (this.selectedSkillId === skillId && skillRequiresTarget(skillId)) {
        this.cancelSelectedSkill();
        return;
      }
      if (!skillRequiresTarget(skillId)) {
        const result = activateSkill(this.state, unit.id, skillId, unit.id);
        if (!result.ok) {
          this.state.log.unshift(result.message);
        }
        this.selectedUnitId = void 0;
        this.selectedSkillId = void 0;
        updateOutcome(this.state);
        this.autoEndIfDone();
        return;
      }
      this.selectedSkillId = skillId;
      this.state.log.unshift("\u8BF7\u9009\u62E9\u6280\u80FD\u76EE\u6807\u3002");
    }
    cancelSelectedSkill() {
      if (this.selectedSkillId) {
        this.selectedSkillId = void 0;
        this.state.log.unshift("\u5DF2\u53D6\u6D88\u6280\u80FD\u76EE\u6807\u3002");
      }
    }
    activeSkillList(unit) {
      if (!this.canAct(unit)) {
        return [];
      }
      return activeSkills2(unit);
    }
    canSelectedAct() {
      return this.canAct(this.selectedUnit);
    }
    canVisitSelected() {
      const unit = this.selectedUnit;
      return unit ? canVisit(this.state, unit) : false;
    }
    visitSelected() {
      const unit = this.selectedUnit;
      if (!unit) {
        return;
      }
      const result = visitChapterSite(this.state, unit.id);
      if (!result.ok) {
        this.state.log.unshift(result.message);
        return;
      }
      this.selectedUnitId = void 0;
      this.selectedSkillId = void 0;
      updateOutcome(this.state);
      this.autoEndIfDone();
    }
    waitSelected() {
      const unit = this.selectedUnit;
      if (!unit || unit.team !== "ally" || unit.acted && (unit.cantoMoveLeft ?? 0) <= 0) {
        return;
      }
      unit.acted = true;
      unit.cantoMoveLeft = 0;
      this.state.log.unshift(`${unitLabel(unit)} \u5F85\u673A\u3002`);
      this.selectedUnitId = void 0;
      this.selectedSkillId = void 0;
      this.autoEndIfDone();
    }
    endPlayerTurn() {
      if (this.state.phase !== "player") {
        return;
      }
      this.selectedUnitId = void 0;
      this.selectedSkillId = void 0;
      for (const unit of this.state.units) {
        if (unit.team === "ally") {
          unit.acted = true;
          unit.cantoMoveLeft = 0;
        }
      }
      this.state.log.unshift("\u654C\u65B9\u56DE\u5408\u3002");
      runEnemyTurn(this.state);
    }
    beginBattle() {
      if (this.state.phase !== "deploy") {
        return;
      }
      this.state.phase = "player";
      this.state.log.unshift("\u90E8\u7F72\u5B8C\u6210\uFF0C\u6218\u6597\u5F00\u59CB\u3002");
    }
    setHover(cell) {
      this.hoverCell = cell;
    }
    terrainText(cell) {
      if (!cell) {
        return "";
      }
      const terrain = terrainAt(this.state, cell);
      return `${terrain.name} \u9632${terrain.defense} \u907F${terrain.avoid}`;
    }
    objectText(cell) {
      const summary = visitSummary(this.state, cell);
      return summary ?? (terrainAt(this.state, cell).effects.join(" / ") || " ");
    }
    unitText(unit) {
      if (!unit) {
        return "";
      }
      const unitDef = getUnitDef(unit.defId);
      const classDef = classForUnit(unit);
      const weapon = getWeapon(unit.weaponId);
      const uses = remainingWeaponUses(unit);
      const forge = weaponForgeLevel(unit);
      const statuses = unit.statuses.map((status) => `${status.id}:${status.turns}`).join(" ");
      return `${unitDef.name} Lv.${unit.level} E${unit.exp}
${classDef.name} HP ${unit.hp}/${unit.stats.hp}  ${weapon.name}${forge ? `+${forge}` : ""} ${uses}/${weapon.durability}
\u529B${unit.stats.str} \u9B54${unit.stats.mag} \u6280${unit.stats.skill} \u901F${unit.stats.spd}
\u9632${unit.stats.def} \u9B54\u9632${unit.stats.res} \u79FB${unit.stats.move}${statuses ? `
${statuses}` : ""}`;
    }
    objectiveText() {
      return getChapter(this.state.chapterId).objective;
    }
    chapterTitle() {
      return getChapter(this.state.chapterId).title;
    }
    autoEndIfDone() {
      if (this.state.phase !== "player") {
        return;
      }
      const anyReady = this.state.units.some((unit) => unit.alive && unit.team === "ally" && (!unit.acted || (unit.cantoMoveLeft ?? 0) > 0));
      if (!anyReady) {
        this.endPlayerTurn();
      }
    }
    attackPositionFor(attacker, target) {
      const weapon = getWeapon(attacker.weaponId);
      if (remainingWeaponUses(attacker) <= 0 || weapon.damageKind === "healing") {
        return void 0;
      }
      if (attacker.moved) {
        return canUnitAttackAtDistance(attacker, weapon, distance2(attacker.pos, target.pos)) ? { cell: attacker.pos, cost: 0 } : void 0;
      }
      return [...reachableCells(this.state, attacker).values()].filter(({ cell }) => {
        const occupant = unitAt(this.state, cell.x, cell.y);
        return (!occupant || occupant.id === attacker.id) && canUnitAttackAtDistance(attacker, weapon, distance2(cell, target.pos));
      }).sort((a, b) => a.cost - b.cost || a.cell.x - b.cell.x || a.cell.y - b.cell.y)[0];
    }
    primeCanto(unit, moveCost, movedBeforeAction) {
      if (!unit.alive || this.state.phase !== "player" || !hasSkill(unit, "paladin_canto")) {
        unit.cantoMoveLeft = 0;
        return false;
      }
      unit.cantoMoveLeft = movedBeforeAction ? unit.cantoMoveLeft ?? 0 : Math.max(0, effectiveStats(unit).move - moveCost);
      return unit.cantoMoveLeft > 0;
    }
    canAct(unit) {
      return Boolean(unit && !unit.acted && unit.team === "ally" && this.state.phase === "player");
    }
    moveDestinationFor(unit, cell) {
      if (unit.acted) {
        if ((unit.cantoMoveLeft ?? 0) <= 0) {
          return void 0;
        }
        const destination = reachableCells(this.state, unit).get(cellKey2(cell));
        return destination && destination.cost <= (unit.cantoMoveLeft ?? 0) ? destination : void 0;
      }
      if (unit.moved) {
        return void 0;
      }
      return reachableCells(this.state, unit).get(cellKey2(cell));
    }
    activateSelectedSkillAt(cell) {
      const unit = this.selectedUnit;
      const skillId = this.selectedSkillId;
      if (!unit || !skillId) {
        return;
      }
      const target = this.state.units.find((candidate) => candidate.pos.x === cell.x && candidate.pos.y === cell.y && (candidate.alive || skillId === "resurrection"));
      const result = activateSkill(this.state, unit.id, skillId, target?.id);
      if (!result.ok) {
        this.state.log.unshift(result.message);
        return;
      }
      this.selectedUnitId = void 0;
      this.selectedSkillId = void 0;
      updateOutcome(this.state);
      this.autoEndIfDone();
    }
  };
  function unitLabel(unit) {
    return getUnitDef(unit.defId).name;
  }

  // src/ui/layout.ts
  function pageSlice(items, page, pageSize) {
    if (pageSize <= 0) {
      throw new Error("pageSize must be positive");
    }
    const totalPages = Math.max(1, Math.ceil(items.length / pageSize));
    const safePage = clamp(Math.trunc(page), 0, totalPages - 1);
    const start = safePage * pageSize;
    const end = Math.min(items.length, start + pageSize);
    return {
      page: safePage,
      totalPages,
      start,
      end,
      items: items.slice(start, end)
    };
  }
  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  // src/ui/BattleScene.ts
  var TILE = 32;
  var COLS = 14;
  var ROWS = 10;
  var WIDTH = COLS * TILE;
  var HEIGHT = ROWS * TILE;
  var SHOP_WEAPON_IDS = ["iron_sword", "iron_lance", "short_bow", "fire", "heal_staff"];
  var DEPLOY_PAGE_SIZE = 5;
  var BattleScene = class extends Phaser.Scene {
    campaign = createNewCampaign();
    vm;
    board;
    overlay;
    uiObjects = [];
    uiHitboxes = [];
    activeSupport;
    deployPage = 0;
    constructor() {
      super("BattleScene");
    }
    create() {
      this.campaign = loadCampaign(globalThis.localStorage);
      this.startChapter(this.campaign.currentChapterId);
      this.board = this.add.graphics();
      this.overlay = this.add.graphics();
      this.input.on("pointermove", (pointer) => {
        const hover = this.isSystemScreenOpen() || this.pointerHitsUi(pointer.x, pointer.y) ? void 0 : screenToCell(pointer.x, pointer.y);
        if (!sameCell(this.vm.hoverCell, hover)) {
          this.vm.setHover(hover);
          this.render();
        }
      });
      this.input.on("pointerdown", (pointer) => {
        if (this.isSystemScreenOpen() || this.pointerHitsUi(pointer.x, pointer.y)) {
          return;
        }
        const cell = screenToCell(pointer.x, pointer.y);
        if (cell) {
          this.vm.selectCell(cell);
          this.render();
        }
      });
      this.input.keyboard?.on("keydown-E", () => {
        this.vm.endPlayerTurn();
        this.render();
      });
      this.input.keyboard?.on("keydown-SPACE", () => {
        this.vm.waitSelected();
        this.render();
      });
      this.render();
    }
    update() {
    }
    render() {
      this.clearUiObjects();
      this.uiHitboxes = [];
      this.drawTerrain();
      this.drawHighlights();
      this.drawUnits();
      this.drawHud();
    }
    drawTerrain() {
      this.board.clear();
      for (let y = 0; y < ROWS; y += 1) {
        for (let x = 0; x < COLS; x += 1) {
          const terrain = getTerrain(this.vm.state.grid[y]?.[x] ?? "plains");
          this.board.fillStyle(terrainColor(terrain), 1);
          this.board.fillRect(x * TILE, y * TILE, TILE, TILE);
          this.board.lineStyle(1, 1842467, 0.55);
          this.board.strokeRect(x * TILE, y * TILE, TILE, TILE);
        }
      }
    }
    drawHighlights() {
      this.overlay.clear();
      const reachable = this.vm.selectedReachable;
      const attackable = this.vm.selectedAttackable;
      for (const key of reachable) {
        const { x, y } = parseCellKey(key);
        this.overlay.fillStyle(3113197, 0.26);
        this.overlay.fillRect(x * TILE + 2, y * TILE + 2, TILE - 4, TILE - 4);
      }
      for (const key of attackable) {
        const { x, y } = parseCellKey(key);
        this.overlay.fillStyle(14042437, 0.34);
        this.overlay.fillRect(x * TILE + 5, y * TILE + 5, TILE - 10, TILE - 10);
      }
      for (const cell of objectiveCells(getChapter(this.vm.state.chapterId).victoryCondition)) {
        this.overlay.lineStyle(2, 15780202, 0.95);
        this.overlay.strokeRect(cell.x * TILE + 4, cell.y * TILE + 4, TILE - 8, TILE - 8);
      }
      if (this.vm.hoverCell && inBounds2(this.vm.state, this.vm.hoverCell)) {
        this.overlay.lineStyle(2, 15986660, 0.95);
        this.overlay.strokeRect(this.vm.hoverCell.x * TILE + 1, this.vm.hoverCell.y * TILE + 1, TILE - 2, TILE - 2);
      }
    }
    drawUnits() {
      for (const unit of this.vm.state.units) {
        if (!unit.alive) {
          continue;
        }
        const classDef = classForUnit(unit);
        const x = unit.pos.x * TILE;
        const y = unit.pos.y * TILE;
        const fill = unit.team === "ally" ? 15780202 : 7780328;
        const border = classDef.tags.includes("dragon") ? 10167357 : unit.team === "ally" ? 16773560 : 14151935;
        this.overlay.fillStyle(fill, unit.acted ? 0.55 : 1);
        this.overlay.fillRoundedRect(x + 5, y + 4, TILE - 10, TILE - 8, 4);
        this.overlay.lineStyle(2, border, 1);
        this.overlay.strokeRoundedRect(x + 5, y + 4, TILE - 10, TILE - 8, 4);
        this.addText(x + 9, y + 8, unitGlyph(unit), { fontSize: "13px", color: "#17130d", fontStyle: "700" });
        this.overlay.fillStyle(1052692, 0.8);
        this.overlay.fillRect(x + 5, y + TILE - 8, TILE - 10, 4);
        this.overlay.fillStyle(unit.team === "ally" ? 4177791 : 14371402, 1);
        this.overlay.fillRect(x + 5, y + TILE - 8, Math.max(1, (TILE - 10) * unit.hp / unit.stats.hp), 4);
      }
    }
    drawHud() {
      if (this.campaign.endingId) {
        this.drawEnding();
        return;
      }
      const phaseText = phaseLabel(this.vm.state.phase);
      this.panel(0, 0, WIDTH, 25, 1052692, 0.82);
      this.addText(8, 5, `${phaseText}  \u7B2C ${this.vm.state.turn} \u56DE\u5408`, { fontSize: "12px", color: "#f3efe4" });
      if (this.vm.state.phase === "deploy") {
        this.drawDeployPanel();
        if (this.activeSupport) {
          this.drawSupportPanel();
        }
        return;
      }
      this.endTurnButton();
      const hoverUnit = this.vm.hoverCell ? unitAt(this.vm.state, this.vm.hoverCell.x, this.vm.hoverCell.y) : void 0;
      const selected = this.vm.selectedUnit;
      const infoUnit = hoverUnit ?? selected;
      if (infoUnit) {
        this.panel(4, HEIGHT - 82, 152, 78, 1120288, 0.88);
        this.addText(10, HEIGHT - 76, this.vm.unitText(infoUnit), { fontSize: "10px", color: "#f3efe4", lineSpacing: 2 });
      }
      this.drawActionMenu();
      if (this.vm.hoverCell && inBounds2(this.vm.state, this.vm.hoverCell)) {
        this.panel(WIDTH - 138, HEIGHT - 50, 134, 46, 1578e3, 0.88);
        this.addText(WIDTH - 132, HEIGHT - 43, this.vm.terrainText(this.vm.hoverCell), { fontSize: "10px", color: "#f3efe4" });
        this.addText(WIDTH - 132, HEIGHT - 27, this.objectAt(this.vm.hoverCell), { fontSize: "10px", color: "#d8c596" });
      }
      const preview = this.previewAtHover();
      if (preview) {
        this.panel(164, 94, 120, 58, 2167057, 0.9);
        this.addText(170, 100, `\u4F24\u5BB3 ${preview.damage}${preview.followUp ? " x2" : ""}`, { fontSize: "11px", color: "#ffd5d5" });
        this.addText(170, 117, `\u547D\u4E2D ${preview.hit}%  \u66B4 ${preview.crit}%`, { fontSize: "10px", color: "#f3efe4" });
        this.addText(170, 133, `${counterText(preview.triangle)} ${preview.defenderCanCounter ? "\u53EF\u53CD\u51FB" : "\u4E0D\u53EF\u53CD\u51FB"}`, { fontSize: "10px", color: "#f3efe4" });
      }
      this.panel(WIDTH - 188, 29, 184, 64, 1052692, 0.72);
      this.addText(WIDTH - 181, 35, `${this.vm.chapterTitle()}
${this.vm.objectiveText()}`, { fontSize: "10px", color: "#f3efe4", wordWrap: { width: 172 } });
      this.panel(164, 29, 116, 58, 1052692, 0.68);
      this.addText(170, 35, this.vm.state.log.slice(0, 3).join("\n"), { fontSize: "9px", color: "#f3efe4", lineSpacing: 2, wordWrap: { width: 105 } });
      if (this.vm.state.phase === "victory") {
        this.drawVictoryPanel();
      } else if (this.vm.state.phase === "defeat") {
        this.drawDefeatPanel();
      }
      if (this.activeSupport) {
        this.drawSupportPanel();
      }
    }
    endTurnButton() {
      const x = WIDTH - 67;
      const y = 3;
      this.button(x, y, 60, 19, "\u7ED3\u675F", () => {
        this.vm.endPlayerTurn();
        this.render();
      });
    }
    drawActionMenu() {
      const unit = this.vm.selectedUnit;
      if (!unit || unit.team !== "ally" || this.vm.state.phase !== "player") {
        this.button(6, 28, 58, 18, "\u65B0\u6218\u5F79", () => {
          clearCampaign(globalThis.localStorage);
          this.campaign = createNewCampaign();
          this.activeSupport = void 0;
          this.startChapter(this.campaign.currentChapterId);
          this.render();
        });
        const support = firstUnviewedSupportConversation(this.campaign);
        if (support && this.vm.state.phase === "player") {
          this.button(68, 28, 58, 18, `\u652F\u63F4${support.rank}`, () => {
            this.activeSupport = support;
            this.render();
          });
        }
        return;
      }
      if (!this.vm.canSelectedAct()) {
        return;
      }
      const x = 160;
      let y = HEIGHT - 28;
      this.button(x, y, 46, 18, "\u5F85\u673A", () => {
        this.vm.waitSelected();
        this.render();
      });
      let offset = 50;
      if (this.vm.canVisitSelected()) {
        this.button(x + offset, y, 46, 18, "\u8BBF\u95EE", () => {
          this.vm.visitSelected();
          this.render();
        });
        offset += 50;
      }
      for (const skill of this.vm.activeSkillList(unit).slice(0, 3)) {
        this.button(x + offset, y, 58, 18, skill.name, () => {
          this.vm.selectSkill(skill.id);
          this.render();
        });
        offset += 62;
      }
      if (this.vm.selectedSkillId) {
        y -= 20;
        this.panel(x, y, 186, 18, 2824730, 0.88);
        this.addText(x + 6, y + 4, `\u6280\u80FD\u76EE\u6807\uFF1A${getSkill(this.vm.selectedSkillId).name}`, { fontSize: "10px", color: "#ffd5d5" });
        this.button(x + 140, y, 42, 18, "\u53D6\u6D88", () => {
          this.vm.cancelSelectedSkill();
          this.render();
        });
      }
    }
    panel(x, y, width, height, color, alpha) {
      this.addHitbox(x, y, width, height);
      this.overlay.fillStyle(color, alpha);
      this.overlay.fillRoundedRect(x, y, width, height, 4);
      this.overlay.lineStyle(1, 3814192, alpha);
      this.overlay.strokeRoundedRect(x, y, width, height, 4);
    }
    previewAtHover() {
      return this.vm.preview;
    }
    objectAt(cell) {
      const unit = unitAt(this.vm.state, cell.x, cell.y);
      if (unit) {
        return getUnitDef(unit.defId).name;
      }
      return this.vm.objectText(cell);
    }
    addText(x, y, text, style) {
      const created = this.add.text(x, y, text, { fontFamily: "system-ui, sans-serif", ...style });
      created.setResolution(2);
      this.uiObjects.push(created);
      return created;
    }
    startChapter(chapterId, resetDeployPage = true) {
      if (resetDeployPage) {
        this.deployPage = 0;
      }
      this.campaign = ensureChapterRoster(this.campaign, chapterId);
      saveCampaign(globalThis.localStorage, this.campaign);
      const state = createInitialBattleState(chapterId, this.campaign);
      this.vm = new BattleViewModel(state);
    }
    drawDeployPanel() {
      const chapter = getChapter(this.vm.state.chapterId);
      const deployableIds = this.deployableUnitIds();
      const deployable = this.campaign.roster.filter((entry) => deployableIds.includes(entry.unitDefId) && !this.campaign.fallen.includes(entry.unitDefId));
      const page = pageSlice(deployable, this.deployPage, DEPLOY_PAGE_SIZE);
      const deployedCount = deployable.filter((entry) => entry.deployed).length;
      this.deployPage = page.page;
      this.panel(6, 28, WIDTH - 12, HEIGHT - 34, 1052692, 0.96);
      this.addText(16, 38, "\u6218\u524D\u90E8\u7F72", { fontSize: "15px", color: "#f7e7b1", fontStyle: "700" });
      const support = firstUnviewedSupportConversation(this.campaign);
      if (support) {
        this.button(WIDTH - 134, 38, 56, 20, `\u652F\u63F4${support.rank}`, () => {
          this.activeSupport = support;
          this.render();
        });
      }
      this.button(WIDTH - 72, 38, 56, 20, "\u5F00\u6218", () => {
        this.vm.beginBattle();
        this.render();
      });
      this.addText(16, 61, chapter.objective, { fontSize: "10px", color: "#f3efe4", wordWrap: { width: 260 }, lineSpacing: 2 });
      this.addText(16, 87, `\u51FA\u51FB ${deployedCount}/${deployable.length}  \u91D1 ${this.campaign.gold}  \u4ED3 ${this.convoySummary()}`, {
        fontSize: "10px",
        color: "#d8c596",
        wordWrap: { width: 260 }
      });
      this.addText(296, 42, "\u4FA6\u5BDF\u5730\u56FE", { fontSize: "10px", color: "#e0c27a" });
      this.drawScoutMap(296, 58, 10);
      SHOP_WEAPON_IDS.forEach((weaponId, index) => {
        this.button(16 + index * 55, 108, 52, 18, `\u4E70${getWeapon(weaponId).name}`, () => {
          this.applyCampaignChange(() => buyWeapon(this.campaign, weaponId));
        });
      });
      page.items.forEach((entry, index) => {
        const y = 136 + index * 29;
        const unitDef = getUnitDef(entry.unitDefId);
        this.addText(16, y, `${unitDef.name} ${classForRoster(entry).name} ${entry.deployed ? "\u51FA" : "\u5F85"}
${this.rosterWeaponText(entry)}`, { fontSize: "9px", color: "#f3efe4", lineSpacing: 1 });
        this.button(142, y + 1, 42, 18, entry.deployed ? "\u5F85\u547D" : "\u51FA\u6218", () => {
          this.applyCampaignChange(() => setRosterDeployment(this.campaign, entry.unitDefId, !entry.deployed, deployableIds));
        });
        this.button(188, y + 1, 30, 18, "\u6362", () => {
          this.applyCampaignChange(() => cycleRosterWeapon(this.campaign, entry.unitDefId));
        });
        const convoyWeaponId = this.firstUsableConvoyWeapon(entry);
        if (convoyWeaponId) {
          this.button(222, y + 1, 30, 18, "\u53D6", () => {
            this.applyCampaignChange(() => assignConvoyWeapon(this.campaign, entry.unitDefId, convoyWeaponId));
          });
        }
        if (repairWeaponCost(entry) > 0) {
          this.button(256, y + 1, 30, 18, "\u4FEE", () => {
            this.applyCampaignChange(() => repairRosterWeapon(this.campaign, entry.unitDefId));
          });
        }
        if (forgeWeaponCost(entry) > 0) {
          this.button(290, y + 1, 30, 18, "\u953B", () => {
            this.applyCampaignChange(() => forgeRosterWeapon(this.campaign, entry.unitDefId));
          });
        }
        promotionTargets(entry).slice(0, 3).forEach((classId, targetIndex) => {
          this.button(324 + targetIndex * 34, y + 1, 32, 18, getClass(classId).name.slice(0, 2), () => {
            this.applyCampaignChange(() => promoteRosterUnit(this.campaign, entry.unitDefId, classId));
          });
        });
      });
      if (page.totalPages > 1) {
        this.button(16, 292, 54, 20, "\u4E0A\u4E00\u9875", () => {
          this.deployPage -= 1;
          this.render();
        });
        this.button(378, 292, 54, 20, "\u4E0B\u4E00\u9875", () => {
          this.deployPage += 1;
          this.render();
        });
      }
      this.addText(188, 296, `\u7B2C ${page.page + 1}/${page.totalPages} \u9875  ${page.start + 1}-${page.end}/${deployable.length}`, {
        fontSize: "10px",
        color: "#8fa1b2"
      });
    }
    drawScoutMap(x, y, scale) {
      this.overlay.lineStyle(1, 3814192, 1);
      this.overlay.strokeRect(x - 1, y - 1, COLS * scale + 2, ROWS * scale + 2);
      for (let row = 0; row < ROWS; row += 1) {
        for (let col = 0; col < COLS; col += 1) {
          const terrain = getTerrain(this.vm.state.grid[row]?.[col] ?? "plains");
          this.overlay.fillStyle(terrainColor(terrain), 0.92);
          this.overlay.fillRect(x + col * scale, y + row * scale, scale - 1, scale - 1);
        }
      }
      for (const unit of this.vm.state.units) {
        if (!unit.alive) {
          continue;
        }
        this.overlay.fillStyle(unit.team === "ally" ? 15780202 : 14371402, 1);
        this.overlay.fillRect(x + unit.pos.x * scale + 2, y + unit.pos.y * scale + 2, scale - 4, scale - 4);
      }
    }
    drawSupportPanel() {
      const support = this.activeSupport;
      if (!support) {
        return;
      }
      const conversation = support.pair.conversations.find((candidate) => candidate.rank === support.rank);
      if (!conversation) {
        return;
      }
      this.drawSystemBackdrop();
      const names = support.pair.units.map((unitId) => getUnitDef(unitId).name).join(" \xD7 ");
      this.panel(36, 48, 376, 222, 1052692, 0.97);
      this.addText(54, 64, `${names} \xB7 ${support.rank}`, { fontSize: "16px", color: "#f7e7b1", fontStyle: "700" });
      this.addText(54, 92, `${conversation.lines.join("\n")}
\u2014\u2014${conversation.effect}`, {
        fontSize: "11px",
        color: "#f3efe4",
        lineSpacing: 5,
        wordWrap: { width: 340 }
      });
      this.button(144, 238, 160, 20, "\u786E\u8BA4", () => {
        this.campaign = viewSupportConversation(this.campaign, support.pair.id, support.rank);
        this.syncRosterSkillsToBattle();
        saveCampaign(globalThis.localStorage, this.campaign);
        this.activeSupport = void 0;
        this.render();
      });
    }
    drawVictoryPanel() {
      const chapter = getChapter(this.vm.state.chapterId);
      this.drawSystemBackdrop();
      this.panel(58, 76, 332, 172, 1120288, 0.94);
      this.addText(70, 88, `${chapter.title} \u5B8C\u6210`, { fontSize: "16px", color: "#f7e7b1", fontStyle: "700" });
      this.addText(70, 112, (chapter.victoryText ?? ["\u6218\u6597\u7ED3\u675F\u3002"]).join("\n"), { fontSize: "11px", color: "#f3efe4", wordWrap: { width: 306 }, lineSpacing: 4 });
      if (chapter.choice && this.campaign.flags[chapter.choice.options[0]?.flag ?? ""] == null) {
        this.addText(70, 154, chapter.choice.prompt, { fontSize: "11px", color: "#e0c27a", wordWrap: { width: 306 } });
        chapter.choice.options.forEach((option, index) => {
          this.button(72, 174 + index * 22, 300, 18, option.text, () => this.advanceAfterChoice(index));
        });
        return;
      }
      this.button(144, 216, 160, 20, chapter.nextChapterId ? "\u8FDB\u5165\u4E0B\u4E00\u7AE0" : "\u67E5\u770B\u7ED3\u5C40", () => this.advanceCampaign());
    }
    drawDefeatPanel() {
      this.drawSystemBackdrop();
      this.panel(86, 100, 276, 100, 2101264, 0.94);
      this.addText(112, 116, "\u8D25\u5317", { fontSize: "18px", color: "#ffd5d5", fontStyle: "700" });
      this.addText(112, 143, "\u6218\u7EBF\u5D29\u6E83\u3002\u91CD\u65B0\u5F00\u59CB\u672C\u7AE0\u3002", { fontSize: "11px", color: "#f3efe4" });
      this.button(144, 169, 160, 20, "\u91CD\u8BD5", () => this.startChapter(this.campaign.currentChapterId));
    }
    drawEnding() {
      if (!this.campaign.endingId) {
        return;
      }
      const ending = getEnding(this.campaign.endingId);
      this.drawSystemBackdrop();
      this.panel(38, 52, 372, 210, 1052692, 0.96);
      this.addText(58, 70, ending.title, { fontSize: "20px", color: "#f7e7b1", fontStyle: "700" });
      this.addText(58, 100, `${ending.tone}
${ending.text.join("\n")}`, { fontSize: "12px", color: "#f3efe4", wordWrap: { width: 332 }, lineSpacing: 5 });
      this.addText(58, 176, `\u89E6\u53D1\u6761\u4EF6\uFF1A${ending.condition}`, { fontSize: "10px", color: "#d8c596", wordWrap: { width: 332 } });
      this.button(142, 224, 164, 22, "\u65B0\u6218\u5F79", () => {
        clearCampaign(globalThis.localStorage);
        this.campaign = createNewCampaign();
        this.startChapter(this.campaign.currentChapterId);
      });
      this.addText(112, 252, `${endingCatalog.length} \u4E2A\u7ED3\u5C40\u5DF2\u63A5\u5165`, { fontSize: "10px", color: "#8fa1b2" });
    }
    advanceAfterChoice(optionIndex) {
      const chapter = getChapter(this.vm.state.chapterId);
      if (chapter.choice) {
        this.campaign = applyStoryChoice(this.campaign, chapter.choice, optionIndex);
      }
      this.advanceCampaign();
    }
    advanceCampaign() {
      this.campaign = mergeBattleIntoCampaign(this.campaign, this.vm.state);
      this.campaign = completeCurrentChapter(this.campaign);
      saveCampaign(globalThis.localStorage, this.campaign);
      if (!this.campaign.endingId) {
        this.startChapter(this.campaign.currentChapterId);
      }
      this.render();
    }
    syncRosterSkillsToBattle() {
      const rosterByUnit = new Map(this.campaign.roster.map((entry) => [entry.unitDefId, entry]));
      for (const unit of this.vm.state.units) {
        const entry = rosterByUnit.get(unit.defId);
        if (unit.team === "ally" && entry) {
          unit.classId = entry.classId;
          unit.skillIds = [...entry.skillIds];
        }
      }
    }
    applyCampaignChange(update) {
      try {
        this.campaign = update();
        saveCampaign(globalThis.localStorage, this.campaign);
        this.startChapter(this.campaign.currentChapterId, false);
      } catch (error) {
        this.vm.state.log.unshift(error instanceof Error ? error.message : "\u64CD\u4F5C\u5931\u8D25\u3002");
      }
      this.render();
    }
    deployableUnitIds() {
      const ids = getChapter(this.vm.state.chapterId).deployments.filter((deployment) => deployment.team === "ally").map((deployment) => deployment.unitDefId);
      return [...new Set(ids)];
    }
    convoySummary() {
      const entries = Object.entries(this.campaign.convoy).filter(([, count]) => count > 0);
      if (entries.length === 0) {
        return "\u7A7A";
      }
      return entries.slice(0, 2).map(([weaponId, count]) => `${getWeapon(weaponId).name}${count}`).join(" ");
    }
    firstUsableConvoyWeapon(entry) {
      return Object.entries(this.campaign.convoy).find(([weaponId, count]) => count > 0 && !entry.weaponIds.includes(weaponId) && canRosterUseWeapon(entry, weaponId))?.[0];
    }
    rosterWeaponText(entry) {
      const weapon = getWeapon(entry.weaponId);
      const uses = entry.weaponUses[entry.weaponId] ?? weapon.durability;
      const forge = entry.weaponForge[entry.weaponId] ?? 0;
      return `${weapon.name}${forge ? `+${forge}` : ""} ${uses}/${weapon.durability}`;
    }
    drawSystemBackdrop() {
      this.addHitbox(0, 0, WIDTH, HEIGHT);
      this.overlay.fillStyle(329226, 0.76);
      this.overlay.fillRect(0, 25, WIDTH, HEIGHT - 25);
      const blocker = this.add.zone(0, 0, WIDTH, HEIGHT).setOrigin(0, 0).setInteractive();
      blocker.on("pointerdown", (_pointer, _localX, _localY, event) => {
        event?.stopPropagation?.();
      });
      this.uiObjects.push(blocker);
    }
    button(x, y, width, height, label, onClick) {
      this.addHitbox(x, y, width, height);
      this.overlay.fillStyle(4929584, 0.95);
      this.overlay.fillRoundedRect(x, y, width, height, 3);
      this.overlay.lineStyle(1, 14729850, 1);
      this.overlay.strokeRoundedRect(x, y, width, height, 3);
      this.addText(x + 8, y + 4, label, { fontSize: "10px", color: "#f7e7b1" });
      const zone = this.add.zone(x, y, width, height).setOrigin(0, 0).setInteractive({ useHandCursor: true });
      zone.on("pointerdown", (_pointer, _localX, _localY, event) => {
        event?.stopPropagation?.();
        onClick();
      });
      this.uiObjects.push(zone);
    }
    addHitbox(x, y, width, height) {
      this.uiHitboxes.push({ x, y, width, height });
    }
    pointerHitsUi(x, y) {
      return this.uiHitboxes.some((box) => x >= box.x && x <= box.x + box.width && y >= box.y && y <= box.y + box.height);
    }
    isSystemScreenOpen() {
      return Boolean(this.campaign.endingId || this.activeSupport || this.vm.state.phase === "deploy" || this.vm.state.phase === "victory" || this.vm.state.phase === "defeat");
    }
    clearUiObjects() {
      for (const object of this.uiObjects) {
        object.destroy();
      }
      this.uiObjects = [];
    }
  };
  function screenToCell(x, y) {
    const cell = { x: Math.floor(x / TILE), y: Math.floor(y / TILE) };
    if (cell.x < 0 || cell.x >= COLS || cell.y < 0 || cell.y >= ROWS) {
      return void 0;
    }
    return cell;
  }
  function parseCellKey(key) {
    const [xText, yText] = key.split(",");
    const x = Number(xText);
    const y = Number(yText);
    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      throw new Error(`Invalid cell key: ${key}`);
    }
    return { x, y };
  }
  function sameCell(left, right) {
    return left?.x === right?.x && left?.y === right?.y;
  }
  function terrainColor(terrain) {
    const colors = {
      plains: 7315282,
      road: 11836009,
      forest: 3107653,
      deep_forest: 2050612,
      mountain: 8485227,
      river: 3569589,
      bridge: 9071173,
      village: 13151605,
      altar: 7160173
    };
    return colors[terrain.id] ?? 6252623;
  }
  function unitGlyph(unit) {
    const classDef = classForUnit(unit);
    if (classDef.tags.includes("flying")) {
      return "F";
    }
    if (classDef.tags.includes("armored")) {
      return "A";
    }
    if (classDef.tags.includes("mage")) {
      return "M";
    }
    if (classDef.tags.includes("archer")) {
      return "B";
    }
    if (classDef.tags.includes("healer")) {
      return "H";
    }
    return unit.team === "ally" ? "S" : "N";
  }
  function counterText(value) {
    if (value > 0) {
      return "\u76F8\u514B \u25B2";
    }
    if (value < 0) {
      return "\u76F8\u514B \u25BC";
    }
    return "\u76F8\u514B -";
  }
  function phaseLabel(phase) {
    const labels = {
      deploy: "\u90E8\u7F72",
      player: "\u6211\u65B9",
      enemy: "\u654C\u65B9",
      victory: "\u80DC\u5229",
      defeat: "\u8D25\u5317"
    };
    return labels[phase] ?? phase;
  }
  function objectiveCells(condition) {
    if (!condition) {
      return [];
    }
    if (condition.type === "seize" || condition.type === "escape") {
      return [{ x: condition.x, y: condition.y }];
    }
    if (condition.type === "all" || condition.type === "any") {
      return condition.conditions.flatMap(objectiveCells);
    }
    return [];
  }

  // src/entrypoints/main.ts
  var config = {
    type: Phaser.AUTO,
    parent: "game",
    width: 448,
    height: 320,
    backgroundColor: "#101014",
    pixelArt: true,
    roundPixels: true,
    antialias: false,
    scale: {
      mode: Phaser.Scale.FIT,
      autoCenter: Phaser.Scale.CENTER_BOTH
    },
    scene: [BattleScene]
  };
  new Phaser.Game(config);
})();
//# sourceMappingURL=main.js.map
