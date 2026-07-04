import { extraClassCatalog, extraSkillCatalog, extraUnitCatalog, supportPairCatalog } from "./expandedContent";
import type { ClassDef, Growths, SkillDef, TerrainDef, UnitDef, WeaponDef, WeaponKind } from "../models/types";

export const COMBAT = {
  minDamage: 1,
  counterHit: 15,
  counterMight: 1,
  doublingThreshold: 4,
  critFromSkill: 0.5,
  doubleRNG: true,
  effMultiplier: 3,
} as const;

// ponytail: starting A/08 tuning; replace with balance-simmed coefficients once full Act 1 telemetry exists.
export const GROWTH = {
  baseNextExp: 36,
  nextExpExponent: 1.5,
  hitExp: 8,
  killBaseExp: 24,
  killLevelBonus: 8,
  supportExp: 10,
  promotionLevel: 10,
  levelCap: 20,
} as const;

// ponytail: starting shop anchors; tune with A/09 balance simulations once loot/reward pacing is complete.
export const ECONOMY = {
  startingGold: 1200,
  convoyCapacityPerWeapon: 99,
  rosterWeaponCapacity: 4,
  repairCostRatio: 0.5,
  forgeMaxLevel: 3,
  forgeMightPerLevel: 1,
} as const;

export const BOND = {
  C: 0,
  B: 40,
  A: 100,
  S: 180,
} as const;

export const weaponTriangle: Record<"sword" | "axe" | "lance", Record<"sword" | "axe" | "lance", number>> = {
  sword: { sword: 0, axe: 1, lance: -1 },
  axe: { sword: -1, axe: 0, lance: 1 },
  lance: { sword: 1, axe: -1, lance: 0 },
};

export const magicTriangle: Record<"fire" | "ice" | "thunder", Record<"fire" | "ice" | "thunder", number>> = {
  fire: { fire: 0, ice: 1, thunder: -1 },
  ice: { fire: -1, ice: 0, thunder: 1 },
  thunder: { fire: 1, ice: -1, thunder: 0 },
};

const infantryGrowth: Growths = { hp: 70, str: 45, mag: 5, skill: 55, spd: 55, luck: 40, def: 30, res: 20 };
const cavalryGrowth: Growths = { hp: 75, str: 50, mag: 5, skill: 45, spd: 45, luck: 35, def: 35, res: 15 };
const flyingGrowth: Growths = { hp: 60, str: 40, mag: 10, skill: 55, spd: 60, luck: 45, def: 20, res: 30 };
const armorGrowth: Growths = { hp: 90, str: 55, mag: 0, skill: 35, spd: 20, luck: 25, def: 55, res: 15 };
const mageGrowth: Growths = { hp: 55, str: 5, mag: 55, skill: 45, spd: 45, luck: 30, def: 15, res: 40 };
const archerGrowth: Growths = { hp: 60, str: 45, mag: 5, skill: 55, spd: 50, luck: 35, def: 25, res: 20 };
const healerGrowth: Growths = { hp: 55, str: 5, mag: 45, skill: 40, spd: 45, luck: 45, def: 15, res: 40 };
const dragonGrowth: Growths = { hp: 80, str: 55, mag: 45, skill: 55, spd: 55, luck: 45, def: 40, res: 40 };

export const terrainCatalog: TerrainDef[] = [
  { id: "plains", name: "平原", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 0, avoid: 0, effects: [] },
  { id: "road", name: "道路", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 0, avoid: 0, effects: ["fast"] },
  { id: "forest", name: "森林", moveCost: { foot: 2, horse: 3, fly: 1 }, defense: 1, avoid: 20, effects: ["horseSlow"] },
  { id: "deep_forest", name: "密林", moveCost: { foot: 3, horse: null, fly: 1 }, defense: 2, avoid: 30, effects: ["horseBlocked"] },
  { id: "mountain", name: "山地", moveCost: { foot: 3, horse: null, fly: 1 }, defense: 2, avoid: 30, effects: ["horseBlocked"] },
  { id: "peak", name: "山峰", moveCost: { foot: 4, horse: null, fly: 1 }, defense: 3, avoid: 40, effects: ["vision"] },
  { id: "fort", name: "要塞", moveCost: { foot: 2, horse: 2, fly: 1 }, defense: 2, avoid: 20, effects: ["regen10"] },
  { id: "village", name: "村庄", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 1, avoid: 10, effects: ["visit"] },
  { id: "river", name: "河流", moveCost: { foot: null, horse: null, fly: 1 }, defense: 0, avoid: 0, effects: ["water"] },
  { id: "shallows", name: "浅滩", moveCost: { foot: 3, horse: 4, fly: 1 }, defense: 0, avoid: -10, effects: ["water"] },
  { id: "bridge", name: "桥", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 0, avoid: 0, effects: ["chokepoint"] },
  { id: "sand", name: "沙地", moveCost: { foot: 2, horse: 3, fly: 1 }, defense: 0, avoid: 0, effects: ["horseSlow"] },
  { id: "poison_bog", name: "毒沼", moveCost: { foot: 2, horse: 3, fly: 1 }, defense: 0, avoid: 10, effects: ["poison"] },
  { id: "lava", name: "火山岩", moveCost: { foot: 2, horse: null, fly: 1 }, defense: 0, avoid: 0, effects: ["eruption"] },
  { id: "ruins", name: "废墟", moveCost: { foot: 2, horse: 2, fly: 1 }, defense: 1, avoid: 15, effects: ["cover"] },
  { id: "altar", name: "龙痕祭坛", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 1, avoid: 10, effects: ["stigma"] },
  { id: "throne", name: "王座", moveCost: { foot: 1, horse: 1, fly: 1 }, defense: 3, avoid: 30, effects: ["bossRegen"] },
  { id: "cliff", name: "断崖", moveCost: { foot: null, horse: null, fly: 1 }, defense: 0, avoid: 0, effects: ["fall"] },
];

const baseClassCatalog: ClassDef[] = [
  { id: "dragon_lance", name: "龙裔·枪", moveKind: "horse", tags: ["cavalry", "dragon"], weaponKinds: ["lance", "sword"], promotesTo: ["paladin", "dragon_king", "stigma_bearer"] },
  { id: "dragon_pegasus", name: "龙裔·天马", moveKind: "fly", tags: ["flying", "dragon"], weaponKinds: ["lance", "fire", "ice", "thunder"], promotesTo: ["sky_knight", "dragon_king", "stigma_bearer"] },
  { id: "sword_fighter", name: "剑士", moveKind: "foot", tags: ["infantry"], weaponKinds: ["sword"], promotesTo: ["swordmaster", "hero"] },
  { id: "lance_cavalier", name: "枪骑", moveKind: "horse", tags: ["cavalry"], weaponKinds: ["lance", "sword"], promotesTo: ["paladin", "wyvern_lord"] },
  { id: "pegasus", name: "天马", moveKind: "fly", tags: ["flying"], weaponKinds: ["lance", "sword"], promotesTo: ["sky_knight", "falcon_knight"] },
  { id: "armor", name: "装甲", moveKind: "foot", tags: ["armored"], weaponKinds: ["lance", "axe"], promotesTo: ["general", "temple_guard"] },
  { id: "mage", name: "法师", moveKind: "foot", tags: ["mage"], weaponKinds: ["fire", "ice", "thunder"], promotesTo: ["sage", "archmage"] },
  { id: "archer", name: "弓兵", moveKind: "foot", tags: ["archer"], weaponKinds: ["bow"], promotesTo: ["sniper", "ranger"] },
  { id: "healer", name: "治疗", moveKind: "foot", tags: ["healer"], weaponKinds: ["staff"], promotesTo: ["bishop", "saint"] },
  { id: "scout", name: "斥候", moveKind: "foot", tags: ["scout"], weaponKinds: ["sword", "bow"], promotesTo: ["thief", "assassin"] },
  { id: "swordmaster", name: "剑圣", moveKind: "foot", tags: ["infantry"], weaponKinds: ["sword"], skillIds: ["iaijutsu"] },
  { id: "hero", name: "勇者", moveKind: "foot", tags: ["infantry"], weaponKinds: ["sword", "axe"], skillIds: ["hero_dual_wield"] },
  { id: "paladin", name: "圣骑士", moveKind: "horse", tags: ["cavalry"], weaponKinds: ["sword", "lance"], skillIds: ["paladin_canto"] },
  { id: "general", name: "将军", moveKind: "foot", tags: ["armored"], weaponKinds: ["lance", "axe"], skillIds: ["bulwark"] },
  { id: "sage", name: "贤者", moveKind: "foot", tags: ["mage"], weaponKinds: ["fire", "ice", "thunder", "staff"], skillIds: ["triune_sage"] },
  { id: "sniper", name: "狙击手", moveKind: "foot", tags: ["archer"], weaponKinds: ["bow"], skillIds: ["cloud_piercer"] },
  { id: "bishop", name: "主教", moveKind: "foot", tags: ["healer", "mage"], weaponKinds: ["staff", "fire"], skillIds: ["resurrection"] },
  { id: "dragon_king", name: "龙王", moveKind: "foot", tags: ["dragon"], weaponKinds: ["dragon", "sword", "lance"], skillIds: ["stigma_roar"] },
  { id: "stigma_bearer", name: "圣痕使", moveKind: "foot", tags: ["dragon"], weaponKinds: ["dragon", "fire", "thunder"], skillIds: ["stigma_seal"] },
];

export const classCatalog = [...baseClassCatalog, ...extraClassCatalog] satisfies ClassDef[];

export const weaponCatalog: WeaponDef[] = [
  { id: "iron_sword", name: "铁剑", kind: "sword", damageKind: "physical", might: 5, hit: 90, crit: 0, weight: 4, range: [1, 1], durability: 40, cost: 460 },
  { id: "iron_axe", name: "铁斧", kind: "axe", damageKind: "physical", might: 8, hit: 75, crit: 0, weight: 8, range: [1, 1], durability: 35, cost: 520 },
  { id: "iron_lance", name: "铁枪", kind: "lance", damageKind: "physical", might: 7, hit: 80, crit: 0, weight: 7, range: [1, 1], durability: 40, cost: 520 },
  { id: "short_bow", name: "短弓", kind: "bow", damageKind: "physical", might: 6, hit: 85, crit: 0, weight: 5, range: [2, 2], durability: 35, cost: 560, effectiveTags: ["flying"] },
  { id: "fire", name: "炎术", kind: "fire", damageKind: "magical", might: 7, hit: 95, crit: 0, weight: 3, range: [1, 2], durability: 35, cost: 620 },
  { id: "ice", name: "冰术", kind: "ice", damageKind: "magical", might: 6, hit: 90, crit: 5, weight: 4, range: [1, 2], durability: 30, cost: 660 },
  { id: "thunder", name: "雷术", kind: "thunder", damageKind: "magical", might: 8, hit: 80, crit: 10, weight: 5, range: [1, 2], durability: 30, cost: 740 },
  { id: "heal_staff", name: "治疗杖", kind: "staff", damageKind: "healing", might: 12, hit: 100, crit: 0, weight: 1, range: [1, 1], durability: 30, cost: 600 },
  { id: "horseslayer", name: "破骑枪", kind: "lance", damageKind: "physical", might: 8, hit: 75, crit: 0, weight: 10, range: [1, 1], durability: 20, cost: 980, effectiveTags: ["cavalry"] },
  { id: "hammer", name: "破甲锤", kind: "axe", damageKind: "physical", might: 9, hit: 70, crit: 0, weight: 12, range: [1, 1], durability: 20, cost: 900, effectiveTags: ["armored"] },
  { id: "wyrmslayer", name: "龙杀剑", kind: "sword", damageKind: "physical", might: 7, hit: 80, crit: 0, weight: 7, range: [1, 1], durability: 20, cost: 1200, effectiveTags: ["dragon"] },
];

const baseSkillCatalog: SkillDef[] = [
  { id: "foresight", name: "见切", kind: "passive", trigger: "onDefend", effect: ["speedGapEvade"], condition: "速度差>=5", description: "速度差足够时必闪一次攻击。" },
  { id: "armor_break", name: "破甲", kind: "passive", trigger: "onAttack", effect: ["ignoreDef:50"], condition: "斧/锤", description: "无视目标一半防御。" },
  { id: "dragon_slayer", name: "屠龙", kind: "passive", trigger: "onAttack", effect: ["effective:dragon"], condition: "龙杀武器", description: "对龙裔特攻。" },
  { id: "adept", name: "连击", kind: "passive", trigger: "onAttack", effect: ["extraHit:skill%"], description: "技巧概率追加一击。" },
  { id: "calm", name: "冷静", kind: "passive", trigger: "onDefend", effect: ["negateCrit"], description: "敌不可对我暴击。" },
  { id: "vengeance", name: "复仇", kind: "passive", trigger: "onAttack", effect: ["lostHpDamage"], description: "受伤越重，下击威力越高。" },
  { id: "hold_fast", name: "坚守", kind: "passive", trigger: "onTurnEnd", effect: ["defenseMod:30%"], condition: "未移动", description: "不移动回合防御提升。" },
  { id: "pathfinder", name: "踏刃", kind: "passive", trigger: "onMove", effect: ["ignoreForestSlow"], condition: "步兵", description: "森林与山地不再拖慢移动。" },
  { id: "lucky_star", name: "幸运星", kind: "passive", trigger: "onDefend", effect: ["doubleLuckAntiCrit"], description: "幸运翻倍参与抗暴。" },
  { id: "gale_cross", name: "疾风连斩", kind: "active", trigger: "manual", effect: ["area:cross", "damage"], cost: "每战1次", description: "攻击十字范围。" },
  { id: "aegis", name: "圣盾", kind: "active", trigger: "manual", effect: ["damageTaken:50%"], cost: "每战2次", description: "本回合受伤减半。" },
  { id: "charge", name: "冲锋", kind: "active", trigger: "manual", effect: ["moveDistanceMight"], cost: "每回合1次", condition: "骑兵", description: "移动后攻击按移动格加威力。" },
  { id: "healing_wave", name: "治愈波", kind: "active", trigger: "manual", effect: ["heal:area"], cost: "杖耐久", description: "范围回血。" },
  { id: "taunt", name: "挑衅", kind: "active", trigger: "manual", effect: ["taunt"], cost: "每战1次", description: "强制邻敌下回合攻我。" },
  { id: "sprint", name: "疾走", kind: "active", trigger: "manual", effect: ["move:+3"], cost: "每战1次", description: "本回合移动提升。" },
  { id: "poison_blade", name: "毒刃", kind: "active", trigger: "onHit", effect: ["status:poison"], condition: "盗贼", description: "命中施加持续扣血。" },
  { id: "iaijutsu", name: "剑圣·居合", kind: "class", trigger: "onAttack", effect: ["crit:double"], condition: "剑圣", description: "暴击率翻倍。" },
  { id: "bulwark", name: "将军·壁垒", kind: "class", trigger: "always", effect: ["noForcedMove"], condition: "将军", description: "不可被击退或拉扯。" },
  { id: "cloud_piercer", name: "狙击·穿云", kind: "class", trigger: "onAttack", effect: ["range:+1", "ignoreTerrainAvoid"], condition: "狙击手", description: "射程提升并无视地形回避。" },
  { id: "triune_sage", name: "贤者·三相", kind: "class", trigger: "always", effect: ["equip:fire,ice,thunder"], condition: "贤者", description: "可同时携三系魔法。" },
  { id: "dive", name: "龙骑·俯冲", kind: "class", trigger: "onAttack", effect: ["highGroundMight"], condition: "龙骑将", description: "从高处攻击提升威力。" },
  { id: "resurrection", name: "主教·复活", kind: "class", trigger: "manual", effect: ["reviveAdjacent"], cost: "限次", condition: "主教", description: "复活相邻阵亡友军。" },
  { id: "twin_pincer", name: "双生夹击", kind: "bond", trigger: "bondAdjacent", effect: ["guaranteeCrit"], condition: "羁绊A", description: "兄妹相邻攻击必暴。" },
  { id: "guard_lunge", name: "援护突刺", kind: "bond", trigger: "allyDefended", effect: ["redirectCounter"], condition: "羁绊B", description: "邻友被攻时替其反击。" },
  { id: "oath_resonance", name: "誓约共鸣", kind: "bond", trigger: "bondAdjacent", effect: ["hit:+15", "avoid:+15"], condition: "羁绊C", description: "相邻双方命中与回避提升。" },
  { id: "stigma_awaken", name: "龙痕觉醒", kind: "stigma", trigger: "manual", effect: ["stats:large", "dragonTaint:+1"], cost: "龙化值", condition: "主角限定", description: "三回合全属性大增，之后龙化累积。" },
];

export const skillCatalog = [...baseSkillCatalog, ...extraSkillCatalog] satisfies SkillDef[];

const baseUnitCatalog: UnitDef[] = [
  { id: "aldric", name: "奥德里克", faction: "sorein", classId: "dragon_lance", level: 1, baseStats: { hp: 27, str: 11, mag: 4, skill: 10, spd: 9, luck: 7, def: 9, res: 4, move: 6, con: 9 }, growths: dragonGrowth, weaponIds: ["iron_lance", "iron_sword"], skillIds: ["oath_resonance", "stigma_awaken"], defeatBehavior: "retreat" },
  { id: "valentin", name: "瓦伦丁", faction: "sorein", classId: "armor", level: 3, baseStats: { hp: 30, str: 12, mag: 0, skill: 8, spd: 5, luck: 5, def: 13, res: 3, move: 4, con: 12 }, growths: armorGrowth, weaponIds: ["iron_lance"], skillIds: ["hold_fast"] },
  { id: "mirelle", name: "米瑞尔", faction: "sorein", classId: "mage", level: 1, baseStats: { hp: 19, str: 1, mag: 10, skill: 9, spd: 8, luck: 6, def: 3, res: 7, move: 5, con: 5 }, growths: mageGrowth, weaponIds: ["fire"], skillIds: ["triune_sage"] },
  { id: "cecilia", name: "塞西莉亚", faction: "church", classId: "sword_fighter", level: 2, baseStats: { hp: 23, str: 9, mag: 2, skill: 11, spd: 11, luck: 5, def: 5, res: 4, move: 5, con: 7 }, growths: infantryGrowth, weaponIds: ["iron_sword"], skillIds: ["calm"] },
  { id: "rowan", name: "少年弓手", faction: "sorein", classId: "archer", level: 1, baseStats: { hp: 21, str: 8, mag: 1, skill: 10, spd: 8, luck: 6, def: 4, res: 2, move: 5, con: 6 }, growths: archerGrowth, weaponIds: ["short_bow"], skillIds: [] },
  { id: "seren", name: "见习圣女", faction: "sorein", classId: "healer", level: 1, baseStats: { hp: 18, str: 1, mag: 8, skill: 7, spd: 7, luck: 8, def: 2, res: 8, move: 5, con: 5 }, growths: healerGrowth, weaponIds: ["heal_staff"], skillIds: ["healing_wave"] },
  { id: "elara", name: "艾拉菈", faction: "nordheim", classId: "dragon_pegasus", level: 1, baseStats: { hp: 24, str: 8, mag: 9, skill: 11, spd: 12, luck: 7, def: 5, res: 8, move: 7, con: 7 }, growths: dragonGrowth, weaponIds: ["iron_lance", "thunder"], skillIds: ["stigma_awaken"], defeatBehavior: "retreat" },
  { id: "sigrun", name: "希格露恩", faction: "nordheim", classId: "pegasus", level: 3, baseStats: { hp: 25, str: 10, mag: 4, skill: 12, spd: 13, luck: 8, def: 6, res: 8, move: 7, con: 7 }, growths: flyingGrowth, weaponIds: ["iron_lance"], skillIds: ["guard_lunge"] },
  { id: "bjorn", name: "比约恩", faction: "nordheim", classId: "sword_fighter", level: 2, baseStats: { hp: 28, str: 12, mag: 0, skill: 8, spd: 8, luck: 5, def: 7, res: 2, move: 5, con: 10 }, growths: infantryGrowth, weaponIds: ["iron_axe"], skillIds: ["vengeance"], defeatBehavior: "retreat" },
  { id: "nord_raider", name: "北境斧兵", faction: "nordheim", classId: "sword_fighter", level: 1, baseStats: { hp: 22, str: 9, mag: 0, skill: 7, spd: 7, luck: 3, def: 6, res: 1, move: 5, con: 9 }, growths: infantryGrowth, weaponIds: ["iron_axe"], skillIds: [] },
  { id: "nord_scout", name: "雪原游侠", faction: "nordheim", classId: "scout", level: 1, baseStats: { hp: 20, str: 7, mag: 0, skill: 10, spd: 11, luck: 6, def: 3, res: 2, move: 6, con: 6 }, growths: infantryGrowth, weaponIds: ["iron_sword"], skillIds: ["pathfinder"] },
  { id: "ice_mage", name: "冰系精灵法师", faction: "nordheim", classId: "mage", level: 1, baseStats: { hp: 18, str: 1, mag: 9, skill: 9, spd: 8, luck: 4, def: 2, res: 8, move: 5, con: 5 }, growths: mageGrowth, weaponIds: ["ice"], skillIds: [] },
];

export const unitCatalog = [...baseUnitCatalog, ...extraUnitCatalog] satisfies UnitDef[];
export { supportPairCatalog };

export function byId<T extends { id: string }>(items: readonly T[], id: string): T {
  const item = items.find((candidate) => candidate.id === id);
  if (!item) {
    throw new Error(`Unknown content id: ${id}`);
  }
  return item;
}

export function isPhysicalTriangleKind(kind: WeaponKind): kind is "sword" | "axe" | "lance" {
  return kind === "sword" || kind === "axe" || kind === "lance";
}

export function isMagicTriangleKind(kind: WeaponKind): kind is "fire" | "ice" | "thunder" {
  return kind === "fire" || kind === "ice" || kind === "thunder";
}
