import { endingCatalog, fullChapterCatalog } from "./campaign";
import { byId, classCatalog, skillCatalog, terrainCatalog, unitCatalog, weaponCatalog } from "./content";
import type { ChapterDef, ClassDef, EndingDef, SkillDef, TerrainDef, UnitDef, WeaponDef } from "../models/types";

export * from "./content";
export { endingCatalog } from "./campaign";

export const chapterCatalog = fullChapterCatalog satisfies ChapterDef[];

export const getChapter = (id: string): ChapterDef => byId(chapterCatalog, id);
export const getEnding = (id: string): EndingDef => byId(endingCatalog, id);
export const getTerrain = (id: string): TerrainDef => byId(terrainCatalog, id);
export const getWeapon = (id: string): WeaponDef => byId(weaponCatalog, id);
export const getClass = (id: string): ClassDef => byId(classCatalog, id);
export const getUnitDef = (id: string): UnitDef => byId(unitCatalog, id);
export const getSkill = (id: string): SkillDef => byId(skillCatalog, id);
