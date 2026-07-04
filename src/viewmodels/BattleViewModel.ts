import { getChapter, getTerrain, getUnitDef, getWeapon } from "../data";
import type { BattleState, Cell, CombatForecast, UnitInstance } from "../models/types";
import { runEnemyTurn } from "../services/ai";
import { findUnit, updateOutcome, unitAt } from "../services/chapter";
import { classForUnit } from "../services/classes";
import { forecastCombat, resolveCombat } from "../services/combat";
import { canVisit, visitChapterSite, visitSummary } from "../services/chapterVisits";
import { remainingWeaponUses, weaponForgeLevel } from "../services/equipment";
import { cellKey, distance, moveUnit, reachableCells, terrainAt } from "../services/movement";
import { activateSkill, activeSkills, skillRequiresTarget } from "../services/skills";
import { hasSkill, canUnitAttackAtDistance } from "../services/skillEffects";
import { effectiveStats } from "../services/status";

export class BattleViewModel {
  readonly state: BattleState;
  selectedUnitId: string | undefined;
  selectedSkillId: string | undefined;
  hoverCell: Cell | undefined;

  constructor(state: BattleState) {
    this.state = state;
  }

  get selectedUnit(): UnitInstance | undefined {
    return this.selectedUnitId ? this.state.units.find((unit) => unit.id === this.selectedUnitId && unit.alive) : undefined;
  }

  get selectedReachable(): Set<string> {
    const unit = this.selectedUnit;
    if (!unit || unit.team !== "ally" || this.state.phase !== "player") {
      return new Set();
    }
    if (unit.acted) {
      if ((unit.cantoMoveLeft ?? 0) <= 0) {
        return new Set();
      }
      const reachable = [...reachableCells(this.state, unit).values()].filter(({ cost }) => cost <= (unit.cantoMoveLeft ?? 0));
      return new Set(reachable.map(({ cell }) => cellKey(cell)));
    }
    return new Set(reachableCells(this.state, unit).keys());
  }

  get selectedAttackable(): Set<string> {
    const unit = this.selectedUnit;
    if (!unit || unit.acted || unit.team !== "ally" || this.state.phase !== "player") {
      return new Set();
    }
    const cells = new Set<string>();
    for (const target of this.state.units.filter((candidate) => candidate.alive && candidate.team !== unit.team)) {
      if (this.attackPositionFor(unit, target)) {
        cells.add(cellKey(target.pos));
      }
    }
    return cells;
  }

  get preview(): CombatForecast | undefined {
    const unit = this.selectedUnit;
    if (!unit || !this.hoverCell) {
      return undefined;
    }
    const target = unitAt(this.state, this.hoverCell.x, this.hoverCell.y);
    if (!target || target.team === unit.team) {
      return undefined;
    }
    const attackPosition = this.attackPositionFor(unit, target);
    if (remainingWeaponUses(unit) <= 0 || !attackPosition) {
      return undefined;
    }
    const original = unit.pos;
    unit.pos = attackPosition.cell;
    const forecast = forecastCombat(this.state, unit.id, target.id);
    unit.pos = original;
    return forecast;
  }

  selectCell(cell: Cell): void {
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
      this.selectedSkillId = undefined;
      return;
    }
    if (!selected) {
      return;
    }
    if (occupant?.team === "enemy") {
      this.attackSelected(occupant);
      return;
    }
    if (this.selectedReachable.has(cellKey(cell))) {
      if (selected.acted) {
        const moved = selected.pos.x !== cell.x || selected.pos.y !== cell.y;
        selected.pos = { ...cell };
        selected.cantoMoveLeft = 0;
        if (moved) {
          selected.moved = true;
        }
      } else {
        moveUnit(this.state, selected, cell);
        selected.acted = true;
      }
      this.state.log.unshift(`${unitLabel(selected)} 移动至 (${cell.x + 1},${cell.y + 1})。`);
      this.selectedUnitId = undefined;
      this.selectedSkillId = undefined;
      updateOutcome(this.state);
      this.autoEndIfDone();
    }
  }

  attackSelected(target: UnitInstance): void {
    const attacker = this.selectedUnit;
    if (!attacker || attacker.acted || attacker.team !== "ally" || target.team === "ally") {
      return;
    }
    const weapon = getWeapon(attacker.weaponId);
    if (remainingWeaponUses(attacker) <= 0) {
      this.state.log.unshift(`${weapon.name} 已损坏。`);
      return;
    }
    const attackPosition = this.attackPositionFor(attacker, target);
    if (!attackPosition || weapon.damageKind === "healing") {
      this.state.log.unshift("射程不符。");
      return;
    }
    if (!moveUnit(this.state, attacker, attackPosition.cell)) {
      this.state.log.unshift("攻击位置被阻挡。");
      return;
    }
    resolveCombat(this.state, attacker.id, target.id);
    attacker.acted = true;
    this.selectedSkillId = undefined;
    updateOutcome(this.state);
    if (this.primeCanto(attacker, attackPosition.cost)) {
      this.selectedUnitId = attacker.id;
      this.state.log.unshift(`${unitLabel(attacker)} 可再移动 ${attacker.cantoMoveLeft} 格。`);
      return;
    }
    this.selectedUnitId = undefined;
    this.autoEndIfDone();
  }

  selectSkill(skillId: string): void {
    const unit = this.selectedUnit;
    if (!unit || unit.acted || unit.team !== "ally") {
      return;
    }
    if (!skillRequiresTarget(skillId)) {
      const result = activateSkill(this.state, unit.id, skillId, unit.id);
      if (!result.ok) {
        this.state.log.unshift(result.message);
      }
      this.selectedUnitId = undefined;
      this.selectedSkillId = undefined;
      updateOutcome(this.state);
      this.autoEndIfDone();
      return;
    }
    this.selectedSkillId = skillId;
    this.state.log.unshift("请选择技能目标。");
  }

  activeSkillList(unit: UnitInstance | undefined): ReturnType<typeof activeSkills> {
    if (!unit || unit.acted || unit.team !== "ally") {
      return [];
    }
    return activeSkills(unit);
  }

  canVisitSelected(): boolean {
    const unit = this.selectedUnit;
    return unit ? canVisit(this.state, unit) : false;
  }

  visitSelected(): void {
    const unit = this.selectedUnit;
    if (!unit) {
      return;
    }
    const result = visitChapterSite(this.state, unit.id);
    if (!result.ok) {
      this.state.log.unshift(result.message);
      return;
    }
    this.selectedUnitId = undefined;
    this.selectedSkillId = undefined;
    updateOutcome(this.state);
    this.autoEndIfDone();
  }

  waitSelected(): void {
    const unit = this.selectedUnit;
    if (!unit || unit.team !== "ally" || (unit.acted && (unit.cantoMoveLeft ?? 0) <= 0)) {
      return;
    }
    unit.acted = true;
    unit.cantoMoveLeft = 0;
    this.state.log.unshift(`${unitLabel(unit)} 待机。`);
    this.selectedUnitId = undefined;
    this.selectedSkillId = undefined;
    this.autoEndIfDone();
  }

  endPlayerTurn(): void {
    if (this.state.phase !== "player") {
      return;
    }
    this.selectedUnitId = undefined;
    this.selectedSkillId = undefined;
    for (const unit of this.state.units) {
      if (unit.team === "ally") {
        unit.acted = true;
        unit.cantoMoveLeft = 0;
      }
    }
    this.state.log.unshift("敌方回合。");
    runEnemyTurn(this.state);
  }

  beginBattle(): void {
    if (this.state.phase !== "deploy") {
      return;
    }
    this.state.phase = "player";
    this.state.log.unshift("部署完成，战斗开始。");
  }

  setHover(cell: Cell | undefined): void {
    this.hoverCell = cell;
  }

  terrainText(cell: Cell | undefined): string {
    if (!cell) {
      return "";
    }
    const terrain = terrainAt(this.state, cell);
    return `${terrain.name} 防${terrain.defense} 避${terrain.avoid}`;
  }

  objectText(cell: Cell): string {
    const summary = visitSummary(this.state, cell);
    return summary ?? (terrainAt(this.state, cell).effects.join(" / ") || " ");
  }

  unitText(unit: UnitInstance | undefined): string {
    if (!unit) {
      return "";
    }
    const unitDef = getUnitDef(unit.defId);
    const classDef = classForUnit(unit);
    const weapon = getWeapon(unit.weaponId);
    const uses = remainingWeaponUses(unit);
    const forge = weaponForgeLevel(unit);
    const statuses = unit.statuses.map((status) => `${status.id}:${status.turns}`).join(" ");
    return `${unitDef.name} Lv.${unit.level} E${unit.exp}\n${classDef.name} HP ${unit.hp}/${unit.stats.hp}  ${weapon.name}${forge ? `+${forge}` : ""} ${uses}/${weapon.durability}\n力${unit.stats.str} 魔${unit.stats.mag} 技${unit.stats.skill} 速${unit.stats.spd}\n防${unit.stats.def} 魔防${unit.stats.res} 移${unit.stats.move}${statuses ? `\n${statuses}` : ""}`;
  }

  objectiveText(): string {
    return getChapter(this.state.chapterId).objective;
  }

  chapterTitle(): string {
    return getChapter(this.state.chapterId).title;
  }

  private autoEndIfDone(): void {
    if (this.state.phase !== "player") {
      return;
    }
    const anyReady = this.state.units.some((unit) => unit.alive && unit.team === "ally" && (!unit.acted || (unit.cantoMoveLeft ?? 0) > 0));
    if (!anyReady) {
      this.endPlayerTurn();
    }
  }

  private attackPositionFor(attacker: UnitInstance, target: UnitInstance): { cell: Cell; cost: number } | undefined {
    const weapon = getWeapon(attacker.weaponId);
    if (remainingWeaponUses(attacker) <= 0 || weapon.damageKind === "healing") {
      return undefined;
    }
    return [...reachableCells(this.state, attacker).values()]
      .filter(({ cell }) => {
        const occupant = unitAt(this.state, cell.x, cell.y);
        return (!occupant || occupant.id === attacker.id) && canUnitAttackAtDistance(attacker, weapon, distance(cell, target.pos));
      })
      .sort((a, b) => a.cost - b.cost || a.cell.x - b.cell.x || a.cell.y - b.cell.y)[0];
  }

  private primeCanto(unit: UnitInstance, moveCost: number): boolean {
    if (!unit.alive || this.state.phase !== "player" || !hasSkill(unit, "paladin_canto")) {
      unit.cantoMoveLeft = 0;
      return false;
    }
    unit.cantoMoveLeft = Math.max(0, effectiveStats(unit).move - moveCost);
    return unit.cantoMoveLeft > 0;
  }

  private activateSelectedSkillAt(cell: Cell): void {
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
    this.selectedUnitId = undefined;
    this.selectedSkillId = undefined;
    updateOutcome(this.state);
    this.autoEndIfDone();
  }
}

function unitLabel(unit: UnitInstance): string {
  return getUnitDef(unit.defId).name;
}
