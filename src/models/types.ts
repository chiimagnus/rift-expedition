export type Team = "ally" | "enemy";
export type Phase = "deploy" | "player" | "enemy" | "victory" | "defeat";
export type WeaponKind = "sword" | "axe" | "lance" | "bow" | "fire" | "ice" | "thunder" | "staff" | "dragon";
export type DamageKind = "physical" | "magical" | "healing";
export type MoveKind = "foot" | "horse" | "fly";
export type UnitTag =
  | "infantry"
  | "cavalry"
  | "flying"
  | "armored"
  | "mage"
  | "archer"
  | "healer"
  | "scout"
  | "siege"
  | "dragon";

export interface Cell {
  x: number;
  y: number;
}

export interface Stats {
  hp: number;
  str: number;
  mag: number;
  skill: number;
  spd: number;
  luck: number;
  def: number;
  res: number;
  move: number;
  con: number;
}

export interface Growths {
  hp: number;
  str: number;
  mag: number;
  skill: number;
  spd: number;
  luck: number;
  def: number;
  res: number;
}

export interface TerrainDef {
  id: string;
  name: string;
  moveCost: Record<MoveKind, number | null>;
  defense: number;
  avoid: number;
  effects: string[];
}

export interface WeaponDef {
  id: string;
  name: string;
  kind: WeaponKind;
  damageKind: DamageKind;
  might: number;
  hit: number;
  crit: number;
  weight: number;
  range: [number, number];
  effectiveTags?: UnitTag[];
  brave?: boolean;
}

export interface ClassDef {
  id: string;
  name: string;
  moveKind: MoveKind;
  tags: UnitTag[];
  weaponKinds: WeaponKind[];
  promotesTo?: string[];
}

export interface SkillDef {
  id: string;
  name: string;
  kind: "passive" | "active" | "class" | "bond" | "stigma";
  trigger: string;
  effect: string[];
  cost?: string;
  condition?: string;
  description: string;
}

export interface UnitDef {
  id: string;
  name: string;
  faction: "sorein" | "nordheim" | "church" | "neutral";
  classId: string;
  level: number;
  baseStats: Stats;
  growths: Growths;
  weaponIds: string[];
  skillIds: string[];
  defeatBehavior?: "fall" | "retreat";
}

export interface UnitInstance {
  id: string;
  defId: string;
  team: Team;
  hp: number;
  stats: Stats;
  weaponId: string;
  skillIds: string[];
  pos: Cell;
  acted: boolean;
  alive: boolean;
  level: number;
  exp: number;
}

export interface ChapterDef {
  id: string;
  title: string;
  act: string;
  objective: string;
  nextChapterId?: string;
  victoryText?: string[];
  choice?: StoryChoice;
  terrainLegend: Record<string, string>;
  map: string[];
  deployments: Array<{
    unitDefId: string;
    instanceId: string;
    team: Team;
    x: number;
    y: number;
    weaponId?: string;
  }>;
  opening: string[];
}

export interface StoryChoice {
  id: string;
  prompt: string;
  options: Array<{
    text: string;
    flag: string;
    value: number | boolean;
  }>;
}

export interface EndingDef {
  id: string;
  title: string;
  condition: string;
  tone: string;
  text: string[];
}

export interface CampaignState {
  version: number;
  currentChapterId: string;
  completedChapterIds: string[];
  roster: string[];
  fallen: string[];
  bonds: Record<string, number>;
  taint: Record<string, number>;
  flags: Record<string, number | boolean>;
  mode: "classic" | "casual";
  seed: number;
  savedAt: number;
  endingId?: string;
}

export interface BattleState {
  chapterId: string;
  turn: number;
  phase: Phase;
  grid: string[][];
  units: UnitInstance[];
  rngState: number;
  bonds: Record<string, number>;
  flags: Record<string, number | boolean>;
  log: string[];
}

export interface CombatForecast {
  attackerId: string;
  defenderId: string;
  distance: number;
  damage: number;
  hit: number;
  crit: number;
  followUp: boolean;
  defenderCanCounter: boolean;
  triangle: number;
  effectiveMultiplier: number;
}

export type CombatEvent =
  | { type: "hit"; sourceId: string; targetId: string; damage: number; critical: boolean; remainingHp: number }
  | { type: "miss"; sourceId: string; targetId: string }
  | { type: "defeat"; sourceId: string; targetId: string; retreat: boolean };

export interface CombatResolution {
  forecast: CombatForecast;
  events: CombatEvent[];
}

export interface AiAction {
  unitId: string;
  moveTo: Cell;
  attackTargetId?: string;
}
