import type { ClassDef, Growths, SkillDef, SupportPairDef, UnitDef } from "../models/types";

const infantry: Growths = { hp: 70, str: 45, mag: 5, skill: 55, spd: 55, luck: 40, def: 30, res: 20 };
const cavalry: Growths = { hp: 75, str: 50, mag: 5, skill: 45, spd: 45, luck: 35, def: 35, res: 15 };
const flying: Growths = { hp: 60, str: 40, mag: 10, skill: 55, spd: 60, luck: 45, def: 20, res: 30 };
const armor: Growths = { hp: 90, str: 55, mag: 0, skill: 35, spd: 20, luck: 25, def: 55, res: 15 };
const mage: Growths = { hp: 55, str: 5, mag: 55, skill: 45, spd: 45, luck: 30, def: 15, res: 40 };
const archer: Growths = { hp: 60, str: 45, mag: 5, skill: 55, spd: 50, luck: 35, def: 25, res: 20 };
const healer: Growths = { hp: 55, str: 5, mag: 45, skill: 40, spd: 45, luck: 45, def: 15, res: 40 };
const dragon: Growths = { hp: 80, str: 55, mag: 45, skill: 55, spd: 55, luck: 45, def: 40, res: 40 };

export const extraClassCatalog: ClassDef[] = [
  { id: "wyvern_lord", name: "龙骑将", moveKind: "fly", tags: ["flying", "cavalry"], weaponKinds: ["lance", "axe"], skillIds: ["dive"] },
  { id: "sky_knight", name: "天空骑士", moveKind: "fly", tags: ["flying"], weaponKinds: ["lance"] },
  { id: "falcon_knight", name: "隼骑", moveKind: "fly", tags: ["flying"], weaponKinds: ["sword", "lance"], skillIds: ["falcon_mercy"] },
  { id: "temple_guard", name: "圣殿卫", moveKind: "foot", tags: ["armored"], weaponKinds: ["lance", "staff"], skillIds: ["shield_wall"] },
  { id: "archmage", name: "大法师", moveKind: "foot", tags: ["mage"], weaponKinds: ["fire", "ice", "thunder"], skillIds: ["archmage_focus"] },
  { id: "ranger", name: "游侠", moveKind: "foot", tags: ["archer", "scout"], weaponKinds: ["bow", "sword"], skillIds: ["ranger_skirmish"] },
  { id: "saint", name: "圣女", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"], skillIds: ["saint_refresh"] },
  { id: "thief", name: "神偷", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword", "bow"], skillIds: ["trailblazer"] },
  { id: "assassin", name: "刺客", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword"], skillIds: ["assassin_lethality"] },
  { id: "wyvern_rider", name: "龙骑兵", moveKind: "fly", tags: ["flying", "cavalry"], weaponKinds: ["lance"] },
  { id: "warrior", name: "勇士", moveKind: "foot", tags: ["infantry"], weaponKinds: ["axe", "bow"] },
  { id: "war_cleric", name: "战斗修士", moveKind: "foot", tags: ["healer", "infantry"], weaponKinds: ["staff", "axe"] },
  { id: "dancer", name: "战鼓舞者", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"] },
  { id: "ballista", name: "魔导炮", moveKind: "foot", tags: ["siege", "archer"], weaponKinds: ["bow", "thunder"], skillIds: ["ballista_lockon"] },
  { id: "valkyrie", name: "女武神", moveKind: "fly", tags: ["flying", "mage"], weaponKinds: ["lance", "ice", "thunder"] },
  { id: "black_knight", name: "黑骑士", moveKind: "horse", tags: ["cavalry", "armored"], weaponKinds: ["sword", "lance"], skillIds: ["black_knight_dread"] },
];

const passiveSkills: SkillDef[] = [
  { id: "forest_guard", name: "森卫", kind: "passive", trigger: "onDefend", effect: ["terrainForest:def+2"], condition: "森林", description: "在森林中额外获得防御。" },
  { id: "anti_arrow_stance", name: "避矢姿态", kind: "passive", trigger: "onDefend", effect: ["avoidVsBow:+20"], description: "受到弓攻击时回避提升。" },
  { id: "linebreaker", name: "破阵", kind: "passive", trigger: "onAttack", effect: ["bonusVsArmored:+3"], description: "对重甲额外造成伤害。" },
  { id: "mercy", name: "慈悲", kind: "passive", trigger: "onAttack", effect: ["nonlethal"], description: "击倒可劝降单位时保留撤退。" },
  { id: "snowstep", name: "雪行", kind: "passive", trigger: "onMove", effect: ["ignoreSnowSlow"], description: "雪地和山地移动惩罚降低。" },
  { id: "battle_prayer", name: "战祷", kind: "passive", trigger: "onTurnStart", effect: ["adjacentHit:+5"], description: "相邻友军命中小幅提升。" },
  { id: "watchful", name: "警戒", kind: "passive", trigger: "onEnemyPhase", effect: ["cannotBeAmbushed"], description: "不会被伏击增援取得先手。" },
  { id: "dragon_resonance", name: "龙脉共振", kind: "passive", trigger: "onStigma", effect: ["bondGain:+2"], condition: "龙裔", description: "龙痕相关行动提高羁绊收益。" },
  { id: "steady_hand", name: "稳手", kind: "passive", trigger: "onAttack", effect: ["hitFloor:60"], description: "主动攻击显示命中不低于 60%。" },
  { id: "last_stand", name: "背水", kind: "passive", trigger: "onDefend", effect: ["defRes:+3"], condition: "HP<30%", description: "低血量时防御与魔防提升。" },
  { id: "quickdraw", name: "速射", kind: "passive", trigger: "onAttack", effect: ["bowFollowupThreshold:-1"], condition: "弓", description: "弓兵更容易追击。" },
  { id: "mage_slayer", name: "破法", kind: "passive", trigger: "onAttack", effect: ["bonusVsMage:+3"], description: "对法师额外造成伤害。" },
  { id: "shield_wall", name: "盾墙", kind: "passive", trigger: "bondAdjacent", effect: ["adjacentDef:+2"], condition: "重甲", description: "相邻友军获得防御。" },
  { id: "trailblazer", name: "开路", kind: "passive", trigger: "onMove", effect: ["allyMoveThrough"], description: "友军可穿过自己所在格。" },
  { id: "holy_focus", name: "圣定", kind: "passive", trigger: "onHeal", effect: ["healCrit"], description: "治疗时有概率额外回复。" },
  { id: "blood_memory", name: "血忆", kind: "passive", trigger: "onDefeatAlly", effect: ["taintToPower"], condition: "龙裔", description: "友军倒下会强化下一次龙痕行动。" },
];

const activeSkills: SkillDef[] = [
  { id: "rally_defense", name: "防御号令", kind: "active", trigger: "manual", effect: ["area:adjacent", "def:+2"], cost: "每战2次", description: "提升邻近友军防御。" },
  { id: "rally_speed", name: "疾速号令", kind: "active", trigger: "manual", effect: ["area:adjacent", "spd:+2"], cost: "每战2次", description: "提升邻近友军速度。" },
  { id: "rescue_pull", name: "救援牵引", kind: "active", trigger: "manual", effect: ["forceMove:allyPull"], cost: "每战1次", description: "把友军拉到身边。" },
  { id: "swap", name: "换位", kind: "active", trigger: "manual", effect: ["swapPosition"], description: "与相邻友军交换位置。" },
  { id: "shove", name: "推击", kind: "active", trigger: "manual", effect: ["forceMove:push"], description: "推动目标一格。" },
  { id: "smite", name: "猛推", kind: "active", trigger: "manual", effect: ["forceMove:push2"], cost: "每战1次", description: "推动目标两格。" },
  { id: "mark_target", name: "标记目标", kind: "active", trigger: "manual", effect: ["targetDebuff:avoid-15"], description: "降低目标回避，方便集火。" },
  { id: "silence", name: "封技", kind: "active", trigger: "manual", effect: ["status:silence"], cost: "每战1次", description: "封锁目标主动技能一回合。" },
  { id: "barrier", name: "魔防屏障", kind: "active", trigger: "manual", effect: ["res:+5"], cost: "每战2次", description: "提高友军魔防。" },
  { id: "fortify", name: "群体治疗", kind: "active", trigger: "manual", effect: ["heal:allAdjacent"], cost: "每战1次", description: "治疗相邻友军。" },
  { id: "piercing_shot", name: "贯通射击", kind: "active", trigger: "manual", effect: ["lineDamage"], cost: "每战1次", description: "沿直线射击多个敌人。" },
  { id: "meteor", name: "陨星", kind: "active", trigger: "manual", effect: ["range:4", "fireDamage"], cost: "每战1次", description: "远距离火焰打击。" },
  { id: "freeze_field", name: "冰封阵", kind: "active", trigger: "manual", effect: ["area:slow"], cost: "每战1次", description: "降低范围内敌人移动。" },
];

const classSkills: SkillDef[] = [
  { id: "paladin_canto", name: "圣骑·再移动", kind: "class", trigger: "afterAction", effect: ["moveRemaining"], condition: "圣骑士", description: "行动后可使用剩余移动力。" },
  { id: "hero_dual_wield", name: "勇者·双持", kind: "class", trigger: "always", effect: ["equip:sword,axe"], condition: "勇者", description: "剑斧双持并降低换武器成本。" },
  { id: "falcon_mercy", name: "隼骑·救护", kind: "class", trigger: "manual", effect: ["carryAlly"], condition: "隼骑", description: "可带离相邻友军。" },
  { id: "archmage_focus", name: "大法师·聚焦", kind: "class", trigger: "onAttack", effect: ["singleSchoolMight:+3"], condition: "大法师", description: "单系魔法威力提高。" },
  { id: "ranger_skirmish", name: "游侠·游击", kind: "class", trigger: "afterAttack", effect: ["stepBack"], condition: "游侠", description: "攻击后后撤一格。" },
  { id: "saint_refresh", name: "圣女·鼓舞", kind: "class", trigger: "manual", effect: ["refreshAlly"], condition: "圣女", description: "让相邻友军再次行动一次。" },
  { id: "assassin_lethality", name: "刺客·必杀", kind: "class", trigger: "onCrit", effect: ["lethality"], condition: "刺客", description: "暴击有概率直接击倒目标。" },
  { id: "ballista_lockon", name: "魔导炮·锁定", kind: "class", trigger: "onAttack", effect: ["ignoreRangePenalty"], condition: "魔导炮", description: "超远程攻击不吃距离惩罚。" },
  { id: "black_knight_dread", name: "黑骑·威压", kind: "class", trigger: "aura", effect: ["enemyHit:-10"], condition: "黑骑士", description: "降低周围敌人命中。" },
];

const bondSkills: SkillDef[] = [
  { id: "feint_snare", name: "佯攻牵制", kind: "bond", trigger: "bondAdjacent", effect: ["targetAvoid:-10"], condition: "比约恩×卢卡 B", description: "喜剧搭档牵制敌人。" },
  { id: "absolution_light", name: "忏悔之光", kind: "bond", trigger: "bondAdjacent", effect: ["recruitCecilia"], condition: "塞西莉亚×奥德里克 A", description: "推动旧友劝赎线。" },
  { id: "sister_guard", name: "雪誓护卫", kind: "bond", trigger: "allyDefended", effect: ["guardElara"], condition: "艾拉菈×希格露恩 B", description: "替艾拉菈承受一次攻击。" },
  { id: "forbidden_vow", name: "禁誓共鸣", kind: "bond", trigger: "bondAdjacent", effect: ["stigmaCostDown"], condition: "双生 S", description: "真结局路线降低龙痕代价。" },
];

const stigmaSkills: SkillDef[] = [
  { id: "stigma_seal", name: "龙痕封印", kind: "stigma", trigger: "manual", effect: ["taint:-1", "selfDamage"], cost: "牺牲 HP", condition: "圣痕使", description: "以生命压低龙化值。" },
  { id: "stigma_roar", name: "龙吼", kind: "stigma", trigger: "manual", effect: ["areaFear"], cost: "龙化值 +1", condition: "龙王", description: "震慑范围敌人并推开。" },
];

export const extraSkillCatalog: SkillDef[] = [...passiveSkills, ...activeSkills, ...classSkills, ...bondSkills, ...stigmaSkills];

export const extraUnitCatalog: UnitDef[] = [
  { id: "temple_captain", name: "圣殿卫队长", faction: "sorein", classId: "temple_guard", level: 4, baseStats: { hp: 29, str: 10, mag: 6, skill: 9, spd: 6, luck: 6, def: 12, res: 8, move: 4, con: 11 }, growths: armor, weaponIds: ["iron_lance", "heal_staff"], skillIds: ["shield_wall"] },
  { id: "lucian", name: "双子骑士·卢修安", faction: "sorein", classId: "lance_cavalier", level: 2, baseStats: { hp: 24, str: 9, mag: 1, skill: 8, spd: 9, luck: 6, def: 7, res: 2, move: 7, con: 8 }, growths: cavalry, weaponIds: ["iron_lance"], skillIds: ["charge"] },
  { id: "livia", name: "双子骑士·莉薇娅", faction: "sorein", classId: "lance_cavalier", level: 2, baseStats: { hp: 23, str: 8, mag: 2, skill: 10, spd: 10, luck: 8, def: 6, res: 3, move: 7, con: 7 }, growths: cavalry, weaponIds: ["iron_sword"], skillIds: ["rally_speed"] },
  { id: "penitent_knight", name: "忏悔骑士", faction: "sorein", classId: "paladin", level: 6, baseStats: { hp: 31, str: 12, mag: 3, skill: 11, spd: 10, luck: 4, def: 10, res: 5, move: 8, con: 9 }, growths: cavalry, weaponIds: ["iron_lance", "wyrmslayer"], skillIds: ["paladin_canto"] },
  { id: "court_mage", name: "宫廷法师", faction: "sorein", classId: "mage", level: 3, baseStats: { hp: 20, str: 1, mag: 11, skill: 10, spd: 7, luck: 5, def: 3, res: 9, move: 5, con: 5 }, growths: mage, weaponIds: ["fire", "thunder"], skillIds: ["meteor"] },
  { id: "old_bishop", name: "老主教", faction: "sorein", classId: "bishop", level: 7, baseStats: { hp: 24, str: 2, mag: 12, skill: 10, spd: 7, luck: 10, def: 4, res: 13, move: 5, con: 6 }, growths: healer, weaponIds: ["heal_staff", "fire"], skillIds: ["barrier"] },
  { id: "retired_sniper", name: "退役狙击手", faction: "sorein", classId: "sniper", level: 6, baseStats: { hp: 26, str: 11, mag: 1, skill: 15, spd: 10, luck: 7, def: 6, res: 3, move: 5, con: 7 }, growths: archer, weaponIds: ["short_bow"], skillIds: ["cloud_piercer"] },
  { id: "wanderer_sword", name: "流浪剑客", faction: "sorein", classId: "swordmaster", level: 5, baseStats: { hp: 25, str: 10, mag: 1, skill: 14, spd: 15, luck: 8, def: 5, res: 4, move: 6, con: 7 }, growths: infantry, weaponIds: ["iron_sword"], skillIds: ["iaijutsu"] },
  { id: "frost_shaman", name: "雷系萨满", faction: "nordheim", classId: "mage", level: 3, baseStats: { hp: 20, str: 1, mag: 12, skill: 9, spd: 9, luck: 5, def: 3, res: 9, move: 5, con: 5 }, growths: mage, weaponIds: ["thunder"], skillIds: ["freeze_field"] },
  { id: "eagle_rider", name: "驯鹰飞兵", faction: "nordheim", classId: "pegasus", level: 2, baseStats: { hp: 22, str: 8, mag: 3, skill: 11, spd: 13, luck: 7, def: 4, res: 7, move: 7, con: 6 }, growths: flying, weaponIds: ["iron_lance"], skillIds: ["anti_arrow_stance"] },
  { id: "tribal_warrior", name: "部族勇士", faction: "nordheim", classId: "warrior", level: 4, baseStats: { hp: 32, str: 13, mag: 0, skill: 9, spd: 8, luck: 5, def: 8, res: 2, move: 5, con: 11 }, growths: infantry, weaponIds: ["iron_axe", "short_bow"], skillIds: ["last_stand"] },
  { id: "yrsa", name: "女武神候补·伊尔莎", faction: "nordheim", classId: "valkyrie", level: 4, baseStats: { hp: 24, str: 8, mag: 9, skill: 12, spd: 13, luck: 8, def: 5, res: 9, move: 7, con: 7 }, growths: flying, weaponIds: ["iron_lance", "ice"], skillIds: ["sister_guard"] },
  { id: "runa", name: "女武神候补·露娜", faction: "nordheim", classId: "valkyrie", level: 4, baseStats: { hp: 23, str: 7, mag: 10, skill: 11, spd: 14, luck: 9, def: 4, res: 10, move: 7, con: 6 }, growths: flying, weaponIds: ["iron_lance", "thunder"], skillIds: ["rally_speed"] },
  { id: "dragon_elder", name: "龙裔长老", faction: "nordheim", classId: "stigma_bearer", level: 8, baseStats: { hp: 29, str: 8, mag: 13, skill: 12, spd: 8, luck: 9, def: 8, res: 12, move: 5, con: 8 }, growths: dragon, weaponIds: ["fire", "heal_staff"], skillIds: ["stigma_seal"] },
  { id: "snow_ranger", name: "雪原游侠·凯尔", faction: "nordheim", classId: "ranger", level: 3, baseStats: { hp: 23, str: 9, mag: 1, skill: 12, spd: 12, luck: 7, def: 5, res: 3, move: 6, con: 7 }, growths: archer, weaponIds: ["short_bow", "iron_sword"], skillIds: ["ranger_skirmish"] },
  { id: "war_drummer", name: "战鼓舞者", faction: "nordheim", classId: "dancer", level: 2, baseStats: { hp: 21, str: 3, mag: 7, skill: 8, spd: 11, luck: 11, def: 3, res: 7, move: 5, con: 5 }, growths: healer, weaponIds: ["heal_staff"], skillIds: ["saint_refresh"] },
  { id: "defector_paladin", name: "叛逃圣骑", faction: "nordheim", classId: "paladin", level: 5, baseStats: { hp: 30, str: 11, mag: 2, skill: 10, spd: 10, luck: 5, def: 9, res: 5, move: 8, con: 9 }, growths: cavalry, weaponIds: ["iron_lance", "horseslayer"], skillIds: ["paladin_canto"] },
  { id: "lost_dragonkin", name: "失忆龙裔", faction: "nordheim", classId: "dragon_king", level: 6, baseStats: { hp: 30, str: 13, mag: 9, skill: 11, spd: 10, luck: 4, def: 10, res: 8, move: 5, con: 9 }, growths: dragon, weaponIds: ["wyrmslayer", "fire"], skillIds: ["stigma_roar"] },
  { id: "luca", name: "卢卡", faction: "neutral", classId: "ranger", level: 3, baseStats: { hp: 22, str: 8, mag: 1, skill: 13, spd: 12, luck: 10, def: 4, res: 3, move: 6, con: 6 }, growths: archer, weaponIds: ["short_bow", "iron_sword"], skillIds: ["feint_snare"] },
  { id: "mercenary_captain", name: "佣兵团长", faction: "neutral", classId: "hero", level: 6, baseStats: { hp: 31, str: 12, mag: 1, skill: 12, spd: 11, luck: 7, def: 8, res: 4, move: 6, con: 9 }, growths: infantry, weaponIds: ["iron_sword", "iron_axe"], skillIds: ["hero_dual_wield"] },
  { id: "hermit_sage", name: "隐居贤者", faction: "neutral", classId: "sage", level: 8, baseStats: { hp: 23, str: 1, mag: 14, skill: 14, spd: 9, luck: 8, def: 4, res: 14, move: 5, con: 6 }, growths: mage, weaponIds: ["fire", "ice", "thunder"], skillIds: ["triune_sage"] },
  { id: "penitent_judge", name: "赎罪审判官", faction: "church", classId: "war_cleric", level: 6, baseStats: { hp: 28, str: 9, mag: 9, skill: 10, spd: 8, luck: 4, def: 8, res: 10, move: 5, con: 8 }, growths: healer, weaponIds: ["heal_staff", "hammer"], skillIds: ["absolution_light"] },
  { id: "mysterious_black_knight", name: "神秘黑骑士", faction: "neutral", classId: "black_knight", level: 10, baseStats: { hp: 34, str: 14, mag: 4, skill: 13, spd: 11, luck: 3, def: 14, res: 7, move: 7, con: 12 }, growths: armor, weaponIds: ["iron_sword", "iron_lance"], skillIds: ["black_knight_dread"] },
];

export const supportPairCatalog: SupportPairDef[] = [
  {
    id: "aldric_elara",
    units: ["aldric", "elara"],
    theme: "双生宿命/禁忌",
    unlockSkillId: "twin_pincer",
    unlockRank: "A",
    ranks: ["C", "B", "A", "S"],
    conversations: [
      {
        rank: "C",
        effect: "解锁誓约共鸣雏形，记录双生直觉。",
        lines: [
          "艾拉菈：你们南方人打仗总拿腔作势。刚才那一剑，你明明可以取我性命。",
          "奥德里克：我不知道。只是那一瞬间，总觉得不该。",
          "艾拉菈：真奇怪。我也是。",
        ],
      },
      {
        rank: "B",
        effect: "龙痕共鸣时羁绊收益提高。",
        lines: [
          "奥德里克：祭坛在回应我们。不是回应军旗，是回应血。",
          "艾拉菈：如果真相证明我们不该并肩呢？",
          "奥德里克：那就先活到能质问真相的那天。",
        ],
      },
      {
        rank: "A",
        effect: "解锁双生夹击。",
        lines: [
          "艾拉菈：我恨过你的国家，也恨过自己为什么无法恨你。",
          "奥德里克：我也一样。命运把我们放在两边，但剑可以自己选择落点。",
          "艾拉菈：那这一次，别偏半寸。和我一起刺穿它。",
        ],
      },
      {
        rank: "S",
        effect: "真结局判定读取该誓约。",
        lines: [
          "奥德里克：封印要一条命。神以为这就能让我们重新彼此为敌。",
          "艾拉菈：那就让神看清楚，血不是枷锁，爱也不是祭品。",
          "奥德里克：若世界只给一条路，我们就把路砍出来。",
        ],
      },
    ],
  },
  {
    id: "aldric_mirelle",
    units: ["aldric", "mirelle"],
    theme: "禁忌暗恋",
    unlockSkillId: "oath_resonance",
    unlockRank: "B",
    ranks: ["C", "B", "A"],
    conversations: [
      {
        rank: "C",
        effect: "米瑞尔获得被看见的动机。",
        lines: [
          "米瑞尔：殿下总是冲在最前面，像不需要任何人。",
          "奥德里克：我需要火力压住左翼。刚才若没有你，我会死在那里。",
          "米瑞尔：你记得？那我下次会让你更难忘。",
        ],
      },
      {
        rank: "B",
        effect: "解锁誓约共鸣。",
        lines: [
          "米瑞尔：我知道自己不该奢望一个答案。可我至少想成为你的力量。",
          "奥德里克：力量不是站在我身后。是有人敢在我错时拦住我。",
          "米瑞尔：那你最好别讨厌我太吵。",
        ],
      },
      {
        rank: "A",
        effect: "第13章后米瑞尔不会因阵营选择离队。",
        lines: [
          "奥德里克：这条路会让索雷因把我们都当叛徒。",
          "米瑞尔：我怕过被抛下，不怕被通缉。",
          "奥德里克：那就一起走。不是命令，是请求。",
        ],
      },
    ],
  },
  {
    id: "elara_sigrun",
    units: ["elara", "sigrun"],
    theme: "姐妹情/背叛",
    unlockSkillId: "sister_guard",
    unlockRank: "B",
    ranks: ["C", "B", "A"],
    conversations: [
      {
        rank: "C",
        effect: "希格露恩恢复护卫誓言。",
        lines: [
          "希格露恩：公主，你又脱离阵线。",
          "艾拉菈：如果我永远被阵线框住，就永远看不见真相。",
          "希格露恩：那至少让我跟上。责骂你也是护卫职责。",
        ],
      },
      {
        rank: "B",
        effect: "解锁雪誓护卫。",
        lines: [
          "艾拉菈：若我选择和南方人并肩，北境会称我为背叛者。",
          "希格露恩：我效忠的不是北境的嘴，是那个会为士兵收尸的你。",
          "艾拉菈：你总知道怎么让我没法逞强。",
        ],
      },
      {
        rank: "A",
        effect: "希格露恩在第16章重组中留下。",
        lines: [
          "希格露恩：背叛这个词太便宜。真正昂贵的是继续相信。",
          "艾拉菈：如果我错了？",
          "希格露恩：那我会亲手把你拉回来，而不是把你交给别人审判。",
        ],
      },
    ],
  },
  {
    id: "bjorn_luca",
    units: ["bjorn", "luca"],
    theme: "喜剧搭档",
    unlockSkillId: "feint_snare",
    unlockRank: "B",
    ranks: ["C", "B"],
    conversations: [
      {
        rank: "C",
        effect: "两人建立诱敌默契。",
        lines: [
          "卢卡：你每次冲锋前都吼那么大声，是战术还是嗓门失控？",
          "比约恩：敌人看我，不看你。这叫牺牲。",
          "卢卡：行，那我负责在你牺牲前把敌人腿射软。",
        ],
      },
      {
        rank: "B",
        effect: "解锁佯攻牵制。",
        lines: [
          "比约恩：你跑得太快，我都来不及替你挡刀。",
          "卢卡：你挡刀太慢，我只好先把刀骗走。",
          "比约恩：听着像胆小。用起来像聪明。成交。",
        ],
      },
    ],
  },
  {
    id: "cecilia_aldric",
    units: ["cecilia", "aldric"],
    theme: "旧友对立/劝赎",
    unlockSkillId: "absolution_light",
    unlockRank: "A",
    ranks: ["C", "B", "A"],
    conversations: [
      {
        rank: "C",
        effect: "旧友线记录第14章劝降伏笔。",
        lines: [
          "塞西莉亚：你变了，奥德里克。以前你不会质疑圣光。",
          "奥德里克：以前我以为圣光不会烧村子。",
          "塞西莉亚：别逼我把你当叛徒。",
        ],
      },
      {
        rank: "B",
        effect: "塞西莉亚被洗脑时保留动摇标记。",
        lines: [
          "奥德里克：你手在抖。",
          "塞西莉亚：那是愤怒。",
          "奥德里克：不。你还记得我们曾发誓保护谁。",
        ],
      },
      {
        rank: "A",
        effect: "解锁忏悔之光。",
        lines: [
          "塞西莉亚：如果我真的错了，那些死者要向谁讨债？",
          "奥德里克：向操纵你的人，也向继续活着的我们。",
          "塞西莉亚：那别让我逃。让我还。",
        ],
      },
    ],
  },
  {
    id: "lucian_livia",
    units: ["lucian", "livia"],
    theme: "双子骑士",
    unlockSkillId: "rally_speed",
    unlockRank: "B",
    ranks: ["C", "B", "A"],
    conversations: [
      {
        rank: "C",
        effect: "双子共享阵型提示。",
        lines: [
          "卢修安：左翼太薄，我去补。",
          "莉薇娅：你每次说补，最后都变成单骑突击。",
          "卢修安：所以我才有你负责把我骂回来。",
        ],
      },
      {
        rank: "B",
        effect: "解锁疾速号令。",
        lines: [
          "莉薇娅：我们不是一把剑的两面。你总该学会慢半步。",
          "卢修安：慢半步会害人。",
          "莉薇娅：快半步也会。听我的节奏。",
        ],
      },
      {
        rank: "A",
        effect: "双子在同场存活时额外获得羁绊。",
        lines: [
          "卢修安：小时候我以为保护你就是挡在前面。",
          "莉薇娅：现在呢？",
          "卢修安：现在我知道，是相信你能和我并排。",
        ],
      },
    ],
  },
  {
    id: "yrsa_runa",
    units: ["yrsa", "runa"],
    theme: "女武神候补",
    unlockSkillId: "sister_guard",
    unlockRank: "B",
    ranks: ["C", "B", "A"],
    conversations: [
      {
        rank: "C",
        effect: "两名候补停止互相抢功。",
        lines: [
          "伊尔莎：你刚才抢了我的击破。",
          "露娜：我救了你的命。",
          "伊尔莎：下次先说救命，再说抢功。",
        ],
      },
      {
        rank: "B",
        effect: "解锁雪誓护卫。",
        lines: [
          "露娜：女武神不是谁飞得最高，是谁能把同伴带回来。",
          "伊尔莎：听起来像教官的话。",
          "露娜：她死前教我的。现在轮到我们记住。",
        ],
      },
      {
        rank: "A",
        effect: "女武神线在第三幕提供撤离支援。",
        lines: [
          "伊尔莎：我一直想赢你。",
          "露娜：现在呢？",
          "伊尔莎：现在想和你一起赢一次大的。",
        ],
      },
    ],
  },
  {
    id: "dragon_elder_lost",
    units: ["dragon_elder", "lost_dragonkin"],
    theme: "失忆与传承",
    unlockSkillId: "stigma_seal",
    unlockRank: "A",
    ranks: ["C", "B", "A"],
    conversations: [
      {
        rank: "C",
        effect: "失忆龙裔开始辨认古龙语。",
        lines: [
          "龙裔长老：你念错了。那不是战吼，是悼词。",
          "失忆龙裔：我为什么会记得它的旋律？",
          "龙裔长老：因为血比名字记得久。",
        ],
      },
      {
        rank: "B",
        effect: "龙痕失控时获得一次提示。",
        lines: [
          "失忆龙裔：梦里有火，有翅膀，还有我杀死的人。",
          "龙裔长老：记忆回来时会先像诅咒。",
          "失忆龙裔：那之后呢？",
          "龙裔长老：之后看你肯不肯把它变成责任。",
        ],
      },
      {
        rank: "A",
        effect: "解锁龙痕封印。",
        lines: [
          "龙裔长老：封印不是否定力量，是给力量一个回家的方向。",
          "失忆龙裔：如果我曾经失控？",
          "龙裔长老：那今天就由你教别人如何停下。",
        ],
      },
    ],
  },
];
