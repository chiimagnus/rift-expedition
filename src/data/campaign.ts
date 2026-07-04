import { chapter01 } from "./chapter01";
import type { ChapterDef, EndingDef } from "../models/types";

const legend = chapter01.terrainLegend;

const maps = {
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
    "PPPPPPPPPPPFMM",
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
    "PPPPPPPPPPPFMM",
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
    "PPPPPPPPPPPFMM",
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
    "PPPPPPPPPPPFMM",
  ],
};

const soreinAllies: ChapterDef["deployments"] = [
  { unitDefId: "aldric", instanceId: "aldric", team: "ally", x: 3, y: 8, weaponId: "iron_lance" },
  { unitDefId: "valentin", instanceId: "valentin", team: "ally", x: 2, y: 8, weaponId: "iron_lance" },
  { unitDefId: "mirelle", instanceId: "mirelle", team: "ally", x: 4, y: 9, weaponId: "fire" },
  { unitDefId: "cecilia", instanceId: "cecilia", team: "ally", x: 1, y: 8, weaponId: "iron_sword" },
  { unitDefId: "rowan", instanceId: "rowan", team: "ally", x: 2, y: 9, weaponId: "short_bow" },
  { unitDefId: "seren", instanceId: "seren", team: "ally", x: 0, y: 9, weaponId: "heal_staff" },
];

const nordheimAllies: ChapterDef["deployments"] = [
  { unitDefId: "elara", instanceId: "elara", team: "ally", x: 3, y: 8, weaponId: "thunder" },
  { unitDefId: "sigrun", instanceId: "sigrun", team: "ally", x: 2, y: 8, weaponId: "iron_lance" },
  { unitDefId: "bjorn", instanceId: "bjorn", team: "ally", x: 4, y: 9, weaponId: "iron_axe" },
  { unitDefId: "nord_scout", instanceId: "scout_ally", team: "ally", x: 1, y: 8, weaponId: "iron_sword" },
  { unitDefId: "ice_mage", instanceId: "ice_mage_ally", team: "ally", x: 2, y: 9, weaponId: "ice" },
];

const nordheimEnemies: ChapterDef["deployments"] = [
  { unitDefId: "elara", instanceId: "elara", team: "enemy", x: 11, y: 1, weaponId: "thunder" },
  { unitDefId: "sigrun", instanceId: "sigrun", team: "enemy", x: 12, y: 2, weaponId: "iron_lance" },
  { unitDefId: "bjorn", instanceId: "bjorn", team: "enemy", x: 10, y: 3, weaponId: "iron_axe" },
  { unitDefId: "nord_raider", instanceId: "raider_a", team: "enemy", x: 9, y: 2, weaponId: "iron_axe" },
  { unitDefId: "nord_scout", instanceId: "scout_a", team: "enemy", x: 12, y: 5, weaponId: "iron_sword" },
  { unitDefId: "ice_mage", instanceId: "ice_mage_a", team: "enemy", x: 9, y: 5, weaponId: "ice" },
];

const soreinEnemies: ChapterDef["deployments"] = [
  { unitDefId: "aldric", instanceId: "aldric_enemy", team: "enemy", x: 11, y: 1, weaponId: "iron_lance" },
  { unitDefId: "valentin", instanceId: "valentin_enemy", team: "enemy", x: 10, y: 2, weaponId: "iron_lance" },
  { unitDefId: "mirelle", instanceId: "mirelle_enemy", team: "enemy", x: 9, y: 4, weaponId: "fire" },
  { unitDefId: "cecilia", instanceId: "cecilia_enemy", team: "enemy", x: 12, y: 3, weaponId: "iron_sword" },
  { unitDefId: "rowan", instanceId: "rowan_enemy", team: "enemy", x: 12, y: 5, weaponId: "short_bow" },
];

const churchEnemies: ChapterDef["deployments"] = [
  { unitDefId: "cecilia", instanceId: "cecilia_boss", team: "enemy", x: 11, y: 1, weaponId: "iron_sword" },
  { unitDefId: "valentin", instanceId: "templar_a", team: "enemy", x: 10, y: 2, weaponId: "iron_lance" },
  { unitDefId: "mirelle", instanceId: "court_mage_a", team: "enemy", x: 9, y: 4, weaponId: "fire" },
  { unitDefId: "rowan", instanceId: "bow_guard_a", team: "enemy", x: 12, y: 5, weaponId: "short_bow" },
  { unitDefId: "nord_raider", instanceId: "zealot_a", team: "enemy", x: 10, y: 5, weaponId: "hammer" },
  { unitDefId: "ice_mage", instanceId: "oracle_a", team: "enemy", x: 12, y: 2, weaponId: "thunder" },
];

const joinedAllies = [...soreinAllies, ...nordheimAllies.slice(0, 3)];

const outlines: Array<{
  id: string;
  title: string;
  act: string;
    objective: string;
    victoryCondition: NonNullable<ChapterDef["victoryCondition"]>;
    defeatConditions?: ChapterDef["defeatConditions"];
    map: keyof typeof maps;
  side: "sorein" | "nordheim" | "joined" | "church";
  opening: string[];
  victoryText: string[];
}> = [
    { id: "ch02", title: "02 焦土村庄", act: "第一幕：相遇与背叛", objective: "护送难民穿过村庄，击退教会审判队。", victoryCondition: { type: "escape", x: 13, y: 8, unitDefIds: ["aldric"] }, map: "village", side: "sorein", opening: ["审判官的火把照亮村口，瓦伦丁命令所有人先救人。"], victoryText: ["幸存者低声说，纵火者穿着圣光教会的白袍。"] },
    { id: "ch03", title: "03 断桥阻击", act: "第一幕：相遇与背叛", objective: "守住桥口 3 回合并击退北境追兵。", victoryCondition: { type: "all", conditions: [{ type: "survive", turns: 3 }, { type: "rout" }] }, map: "bridge", side: "sorein", opening: ["断桥只剩一线通路，骑兵无法展开，森林成了真正的敌人。"], victoryText: ["瓦伦丁负伤，他掌心里攥着一枚教会纹章。"] },
    { id: "ch04", title: "04 双线并行", act: "第一幕：相遇与背叛", objective: "切换到艾拉菈视角，救出被南军围捕的族人。", victoryCondition: { type: "seize", x: 2, y: 2, unitDefIds: ["elara"] }, map: "snow", side: "nordheim", opening: ["北境的雪盖不住血迹。艾拉菈第一次让玩家看见战争的另一面。"], victoryText: ["南方人的骑士道，在雪地里显得和谎言一样苍白。"] },
    { id: "ch05", title: "05 雪夜奇袭", act: "第一幕：相遇与背叛", objective: "兄妹阵营正面交锋，任一主角撤退即可过关。", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["elara"] }, map: "snow", side: "sorein", opening: ["雪夜里，两枚龙痕隔着战场隐隐发烫。"], victoryText: ["没人知道为什么最后一击偏了半寸。"] },
    { id: "ch06", title: "06 血色黎明", act: "第一幕：相遇与背叛", objective: "保护瓦伦丁撤离，击破追击者。", victoryCondition: { type: "rout" }, defeatConditions: [{ type: "protectUnit", unitDefIds: ["valentin"] }], map: "village", side: "sorein", opening: ["黎明像血一样漫过麦田。瓦伦丁说，别相信每一道圣光。"], victoryText: ["瓦伦丁战死，凶器上带着教会纹章。"] },
    { id: "ch07", title: "07 俱虏与对话", act: "第一幕：相遇与背叛", objective: "兄妹被囚，同场越过守卫控制区并会合。", victoryCondition: { type: "escape", x: 7, y: 4, unitDefIds: ["aldric", "elara"] }, map: "bridge", side: "joined", opening: ["同一个战俘营里，奥德里克和艾拉菈终于交换了名字。"], victoryText: ["敌人的脸变得具体，仇恨第一次迟疑。"] },
    { id: "ch08", title: "08 逃亡之约", act: "第一幕：相遇与背叛", objective: "合力越狱，占领出口。", victoryCondition: { type: "seize", x: 6, y: 4 }, map: "altar", side: "joined", opening: ["越狱不是同盟，只是同一条路上暂时不能互相杀死。"], victoryText: ["篝火旁，双生动机第一次合在一起。"] },
    { id: "ch09", title: "09 龙痕共鸣", act: "第二幕：真相与撑裂", objective: "调查龙痕祭坛，击退被吸引来的教会军。", victoryCondition: { type: "seize", x: 6, y: 4, unitDefIds: ["aldric", "elara"] }, map: "altar", side: "joined", opening: ["祭坛回应两人的血，石缝里亮起猩红纹路。"], victoryText: ["两枚圣痕同时灼痛，封印真相露出第一道裂缝。"] },
    { id: "ch10", title: "10 圣都疑云", act: "第二幕：真相与撑裂", objective: "潜入档案馆，夺取双生记录。", victoryCondition: { type: "seize", x: 5, y: 0 }, map: "village", side: "joined", opening: ["圣都的钟声太整齐，整齐得像审判。"], victoryText: ["档案写着：双生子出生当夜即被分离。"] },
    { id: "ch11", title: "11 弑父真相", act: "第二幕：真相与撑裂", objective: "突破教会封锁，揭开弑父命令。", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "bridge", side: "joined", opening: ["真相不是钥匙，是刀。它会先割开握住它的人。"], victoryText: ["养父曾奉教会之命杀死两人的生父。"] },
    { id: "ch12", title: "12 禁忌之心", act: "第二幕：真相与撑裂", objective: "护送双生离开伏击圈，保持二人存活。", victoryCondition: { type: "escape", x: 13, y: 8, unitDefIds: ["aldric", "elara"] }, defeatConditions: [{ type: "protectUnit", unitDefIds: ["aldric", "elara"] }], map: "snow", side: "joined", opening: ["血缘与心意同时落下，任何答案都像背叛。"], victoryText: ["他们没有说出口，但战场已经替他们回答。"] },
    { id: "ch13", title: "13 叛国抉择", act: "第二幕：真相与撑裂", objective: "击退两国追兵，并选择倒向南、北或中立。", victoryCondition: { type: "rout" }, map: "bridge", side: "joined", opening: ["没有中立的旗帜，只有愿意为中立流的血。"], victoryText: ["选择被写入世界状态，盟友开始计算离队与留下的代价。"] },
    { id: "ch14", title: "14 旧友为敌", act: "第二幕：真相与撑裂", objective: "击败被洗脑的塞西莉亚，可触发劝降伏笔。", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "village", side: "joined", opening: ["塞西莉亚举剑时，眼神像被擦掉了一半。"], victoryText: ["旧友没有醒来，但她听见了自己的名字。"] },
    { id: "ch15", title: "15 织命低语", act: "第二幕：真相与撑裂", objective: "在神殿中撑过宗座的三阶段压迫。", victoryCondition: { type: "survive", turns: 3 }, map: "altar", side: "joined", opening: ["宗座说：从头到尾，都是我的棋局。"], victoryText: ["神不是答案，神是幕后黑手。"] },
    { id: "ch16", title: "16 众叛亲离", act: "第二幕：真相与撑裂", objective: "在队伍重组中守住撤离点。", victoryCondition: { type: "escape", x: 0, y: 9, unitDefIds: ["aldric"] }, map: "snow", side: "joined", opening: ["选择开始收账。有人离队，有人留下，也有人沉默。"], victoryText: ["队伍变小了，但每一步都更像自己的意志。"] },
    { id: "ch17", title: "17 龙脊远征", act: "第二幕：真相与撑裂", objective: "穿越龙脊山脉，占领祭坛入口。", victoryCondition: { type: "seize", x: 6, y: 4 }, map: "snow", side: "joined", opening: ["龙脊山脉像一条死去的神横在大陆中央。"], victoryText: ["山风里传来古龙低鸣，像在召回自己的血。"] },
    { id: "ch18", title: "18 觉醒代价", act: "第二幕：真相与撑裂", objective: "使用或压制龙痕觉醒，阻止失控。", victoryCondition: { type: "survive", turns: 3 }, defeatConditions: [{ type: "protectUnit", unitDefIds: ["aldric", "elara"] }], map: "altar", side: "joined", opening: ["力量给出捷径，也在终点索要灵魂。"], victoryText: ["龙化值成为结局的债。"] },
    { id: "ch19", title: "19 圣都决战", act: "第三幕：献祭与改命", objective: "攻入圣都，击败织命宗座的代行者。", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "village", side: "joined", opening: ["圣都的大门为战争敞开，也为谎言敞开。"], victoryText: ["宗座倒下前笑了，因为封印仍然需要牺牲。"] },
    { id: "ch20", title: "20 封印真相", act: "第三幕：献祭与改命", objective: "守住封印核心，读取古龙记忆。", victoryCondition: { type: "survive", turns: 3 }, map: "altar", side: "joined", opening: ["真相终于完整：封印需要一名龙痕者作为楔子。"], victoryText: ["活下去与拯救世界，不再能同时成立。"] },
    { id: "ch21", title: "21 最后的支援", act: "第三幕：献祭与改命", objective: "全员支援会话收束，抵御最后围剿。", victoryCondition: { type: "rout" }, map: "bridge", side: "joined", opening: ["每个人都在黎明前说出最像遗言的话。"], victoryText: ["羁绊不是奖励，是选择时手上的重量。"] },
    { id: "ch22", title: "22 神殿之门", act: "第三幕：献祭与改命", objective: "突入龙神封印核心，击破门前守卫。", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "altar", side: "joined", opening: ["神殿之门没有锁，因为它一直在等钥匙长大。"], victoryText: ["门开了，世界安静得像屏住呼吸。"] },
    { id: "ch23", title: "23 双生之择", act: "第三幕：献祭与改命", objective: "真正互斥的结局分支：献祭兄、献祭妹或弑神改命。", victoryCondition: { type: "seize", x: 6, y: 4, unitDefIds: ["aldric", "elara"] }, map: "altar", side: "joined", opening: ["宿命把三条路摆在面前，每一条都要留下些什么。"], victoryText: ["选择落下，结局开始。"] },
    { id: "ch24", title: "24 终幕", act: "第三幕：献祭与改命", objective: "按第 23 章抉择进入对应结局，击破最后形态。", victoryCondition: { type: "defeatBoss", targetInstanceIds: ["cecilia_boss"] }, map: "altar", side: "joined", opening: ["最后的战斗不是为了证明谁更强，而是证明命运并非唯一作者。"], victoryText: ["双生的故事在血与光之间收束。"] },
  ];

export const endingCatalog: EndingDef[] = [
  { id: "sacrifice_aldric", title: "牺牲兄", condition: "第23章选择献祭兄且奥德里克存活", tone: "悲壮，妹背负", text: ["奥德里克成为新的封印楔子。艾拉菈带着他的枪离开圣都。"] },
  { id: "sacrifice_elara", title: "牺牲妹", condition: "第23章选择献祭妹且艾拉菈存活", tone: "悲壮，兄背负", text: ["艾拉菈在龙痕光中消失。奥德里克第一次违抗神，却没能违抗失去。"] },
  { id: "defy_god", title: "弑神改命", condition: "全龙痕觉醒线达成，龙化值受控，关键羁绊达 S", tone: "反抗宿命，惨胜", text: ["双生没有献祭彼此。他们把剑指向织命神，赢下一条有代价的自由。"] },
  { id: "dragonfall", title: "双双龙化", condition: "龙化值超阈值", tone: "隐藏坏结局", text: ["两枚圣痕一起碎裂。龙神醒来，世界终于没有了战争，也没有了人。"] },
];

// ponytail: M1 uses a few encounter templates across 24 chapters; replace each with bespoke maps/waves during M3-M5 content pass.
export const storyChapters: ChapterDef[] = outlines.map((outline, index) => {
  const nextChapterId = index === outlines.length - 1 ? undefined : outlines[index + 1]!.id;
  const choice = choiceFor(outline.id);
  const events = eventsFor(outline.id);
  const visits = visitsFor(outline.id);
  return {
    id: outline.id,
    title: outline.title,
    act: outline.act,
      objective: outline.objective,
      victoryCondition: outline.victoryCondition,
      ...(outline.defeatConditions ? { defeatConditions: outline.defeatConditions } : {}),
      victoryText: outline.victoryText,
    terrainLegend: legend,
    map: maps[outline.map],
    deployments: deploymentsFor(outline.side),
    ...(events.length > 0 ? { events } : {}),
    ...(visits.length > 0 ? { visits } : {}),
    opening: outline.opening,
    ...(nextChapterId ? { nextChapterId } : {}),
    ...(choice ? { choice } : {}),
  };
});

export const fullChapterCatalog = [chapter01, ...storyChapters] satisfies ChapterDef[];

function deploymentsFor(side: "sorein" | "nordheim" | "joined" | "church"): ChapterDef["deployments"] {
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

function choiceFor(chapterId: string): ChapterDef["choice"] {
  if (chapterId === "ch13") {
    return {
      id: "allegiance",
      prompt: "第13章叛国抉择：倒向哪一边？",
      options: [
        { text: "倒向索雷因，保住南境民众", flag: "allegiance", value: 1 },
        { text: "倒向诺德海姆，守护古龙信仰", flag: "allegiance", value: 2 },
        { text: "中立逃亡，谁都不献祭", flag: "allegiance", value: 3 },
      ],
    };
  }
  if (chapterId === "ch23") {
    return {
      id: "ending_choice",
      prompt: "第23章双生之择：封印需要代价。",
      options: [
        { text: "献祭奥德里克", flag: "endingChoice", value: 1 },
        { text: "献祭艾拉菈", flag: "endingChoice", value: 2 },
        { text: "拒绝献祭，弑神改命", flag: "endingChoice", value: 3 },
      ],
    };
  }
  return undefined;
}

function eventsFor(chapterId: string): NonNullable<ChapterDef["events"]> {
  if (chapterId === "ch03") {
    return [
      {
        id: "north_bridge_wave",
        type: "reinforcement",
        turn: 2,
        phase: "enemyStart",
        ambush: true,
        telegraph: "林线外响起号角，北境援军下回合会从西北山道压上。",
        message: "北境援军从西北山道杀出。",
        deployments: [
          { unitDefId: "nord_raider", instanceId: "ch03_wave_raider", team: "enemy", x: 0, y: 1, weaponId: "iron_axe" },
          { unitDefId: "nord_scout", instanceId: "ch03_wave_scout", team: "enemy", x: 1, y: 1, weaponId: "iron_sword" },
        ],
      },
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
        telegraph: "雪雾里传来圣钟回声，教会伏兵下回合会从东北包抄。",
        message: "教会伏兵撕开雪雾，截断退路。",
        deployments: [
          { unitDefId: "nord_raider", instanceId: "ch12_zealot_wave", team: "enemy", x: 13, y: 0, weaponId: "hammer" },
          { unitDefId: "ice_mage", instanceId: "ch12_oracle_wave", team: "enemy", x: 12, y: 0, weaponId: "thunder" },
        ],
      },
    ];
  }
  if (chapterId === "ch15") {
    return [
      {
        id: "pontiff_second_phase",
        type: "reinforcement",
        turn: 2,
        phase: "enemyStart",
        telegraph: "祭坛纹路转为白金色，下回合宗座会召来第二阶段守卫。",
        message: "织命守卫响应祭坛，战线升级。",
        deployments: [
          { unitDefId: "valentin", instanceId: "ch15_templar_phase2", team: "enemy", x: 8, y: 4, weaponId: "iron_lance" },
          { unitDefId: "ice_mage", instanceId: "ch15_oracle_phase2", team: "enemy", x: 9, y: 5, weaponId: "thunder" },
        ],
      },
      {
        id: "pontiff_third_phase",
        type: "reinforcement",
        turn: 3,
        phase: "enemyStart",
        telegraph: "祭坛裂缝喷出龙痕光，下回合宗座会压入最终阶段。",
        message: "龙痕光暴涨，最终守卫逼近祭坛。",
        deployments: [
          { unitDefId: "mirelle", instanceId: "ch15_mage_phase3", team: "enemy", x: 5, y: 6, weaponId: "fire" },
          { unitDefId: "rowan", instanceId: "ch15_bow_phase3", team: "enemy", x: 8, y: 6, weaponId: "short_bow" },
        ],
      },
    ];
  }
  if (chapterId === "ch20") {
    return [
      {
        id: "seal_core_guard",
        type: "reinforcement",
        turn: 3,
        phase: "enemyStart",
        telegraph: "封印核心开始逆转，下回合古龙记忆会唤醒守卫。",
        message: "古龙记忆化作守卫，逼迫队伍守住核心。",
        deployments: [
          { unitDefId: "lost_dragonkin", instanceId: "ch20_memory_dragon", team: "enemy", x: 6, y: 4, weaponId: "wyrmslayer" },
          { unitDefId: "dragon_elder", instanceId: "ch20_memory_elder", team: "enemy", x: 7, y: 5, weaponId: "fire" },
        ],
      },
    ];
  }
  return [];
}

function visitsFor(chapterId: string): NonNullable<ChapterDef["visits"]> {
  if (chapterId === "ch02") {
    return [
      {
        id: "refugee_cellar",
        x: 2,
        y: 2,
        label: "焦土村地窖",
        message: "难民从地窖递出钱袋：拿去修武器，别让下一个村子也烧起来。",
        gold: 300,
        flag: "savedRefugeeCellar",
        value: true,
      },
    ];
  }
  if (chapterId === "ch10") {
    return [
      {
        id: "archive_contact",
        x: 5,
        y: 0,
        label: "档案馆密室",
        message: "档案管理员留下短弓和密语：教会在记录双生，也在抹掉证人。",
        weaponId: "short_bow",
        weaponCount: 1,
        flag: "archiveContactHelped",
        value: true,
      },
    ];
  }
  if (chapterId === "ch14") {
    return [
      {
        id: "cecilia_memory",
        x: 2,
        y: 2,
        label: "旧友民居",
        message: "屋内还挂着塞西莉亚旧日的誓词。奥德里克记住了能唤醒她的话。",
        gold: 200,
        flag: "ceciliaMemoryFound",
        value: true,
      },
    ];
  }
  return [];
}
