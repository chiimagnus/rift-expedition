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
  { id: "wyvern_lord", name: "龙骑将", moveKind: "fly", tags: ["flying", "cavalry"], weaponKinds: ["lance", "axe"] },
  { id: "sky_knight", name: "天空骑士", moveKind: "fly", tags: ["flying"], weaponKinds: ["lance"] },
  { id: "falcon_knight", name: "隼骑", moveKind: "fly", tags: ["flying"], weaponKinds: ["sword", "lance"] },
  { id: "temple_guard", name: "圣殿卫", moveKind: "foot", tags: ["armored"], weaponKinds: ["lance", "staff"] },
  { id: "archmage", name: "大法师", moveKind: "foot", tags: ["mage"], weaponKinds: ["fire", "ice", "thunder"] },
  { id: "ranger", name: "游侠", moveKind: "foot", tags: ["archer", "scout"], weaponKinds: ["bow", "sword"] },
  { id: "saint", name: "圣女", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"] },
  { id: "thief", name: "神偷", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword", "bow"] },
  { id: "assassin", name: "刺客", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword"] },
  { id: "wyvern_rider", name: "龙骑兵", moveKind: "fly", tags: ["flying", "cavalry"], weaponKinds: ["lance"] },
  { id: "warrior", name: "勇士", moveKind: "foot", tags: ["infantry"], weaponKinds: ["axe", "bow"] },
  { id: "war_cleric", name: "战斗修士", moveKind: "foot", tags: ["healer", "infantry"], weaponKinds: ["staff", "axe"] },
  { id: "dancer", name: "战鼓舞者", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"] },
  { id: "ballista", name: "魔导炮", moveKind: "foot", tags: ["siege", "archer"], weaponKinds: ["bow", "thunder"] },
  { id: "valkyrie", name: "女武神", moveKind: "fly", tags: ["flying", "mage"], weaponKinds: ["lance", "ice", "thunder"] },
  { id: "black_knight", name: "黑骑士", moveKind: "horse", tags: ["cavalry", "armored"], weaponKinds: ["sword", "lance"] },
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
  { id: "aldric_elara", units: ["aldric", "elara"], theme: "双生宿命/禁忌", unlockSkillId: "twin_pincer", ranks: ["C", "B", "A", "S"] },
  { id: "aldric_mirelle", units: ["aldric", "mirelle"], theme: "禁忌暗恋", unlockSkillId: "oath_resonance", ranks: ["C", "B", "A"] },
  { id: "elara_sigrun", units: ["elara", "sigrun"], theme: "姐妹情/背叛", unlockSkillId: "sister_guard", ranks: ["C", "B", "A"] },
  { id: "bjorn_luca", units: ["bjorn", "luca"], theme: "喜剧搭档", unlockSkillId: "feint_snare", ranks: ["C", "B"] },
  { id: "cecilia_aldric", units: ["cecilia", "aldric"], theme: "旧友对立/劝赎", unlockSkillId: "absolution_light", ranks: ["C", "B", "A"] },
  { id: "lucian_livia", units: ["lucian", "livia"], theme: "双子骑士", unlockSkillId: "rally_speed", ranks: ["C", "B", "A"] },
  { id: "yrsa_runa", units: ["yrsa", "runa"], theme: "女武神候补", unlockSkillId: "sister_guard", ranks: ["C", "B", "A"] },
  { id: "dragon_elder_lost", units: ["dragon_elder", "lost_dragonkin"], theme: "失忆与传承", unlockSkillId: "stigma_seal", ranks: ["C", "B", "A"] },
];
