import { getUnitDef } from "../data";
import type { CampaignState, ChapterDeployment, UnitInstance } from "../models/types";
import { normalizeWeaponForge, normalizeWeaponUses } from "./equipment";

export function instantiateDeployment(deployment: ChapterDeployment, campaign?: CampaignState): UnitInstance | undefined {
  const unitDef = getUnitDef(deployment.unitDefId);
  const rosterEntry = deployment.team === "ally" ? campaign?.roster.find((entry) => entry.unitDefId === unitDef.id) : undefined;
  if (deployment.team === "ally" && ((campaign?.mode === "classic" && campaign.fallen.includes(unitDef.id)) || rosterEntry?.deployed === false)) {
    return undefined;
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
    stats: { ...(rosterEntry?.stats ?? unitDef.baseStats) },
    weaponId,
    weaponUses: normalizeWeaponUses(carriedWeaponIds, rosterEntry?.weaponUses),
    weaponForge: normalizeWeaponForge(carriedWeaponIds, rosterEntry?.weaponForge),
    skillIds: [...(rosterEntry?.skillIds ?? unitDef.skillIds)],
    statuses: [],
    skillUses: {},
    pos: { x: deployment.x, y: deployment.y },
    acted: false,
    moved: false,
    cantoMoveLeft: 0,
    alive: true,
    level: rosterEntry?.level ?? unitDef.level,
    exp: rosterEntry?.exp ?? 0,
  };
}
