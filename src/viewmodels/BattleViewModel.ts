import { getClass, getChapter, getTerrain, getUnitDef, getWeapon } from "../data";
import type { BattleState, Cell, CombatForecast, UnitInstance } from "../models/types";
import { attackableEnemiesFrom, runEnemyTurn } from "../services/ai";
import { findUnit, updateOutcome, unitAt } from "../services/chapter";
import { canAttackAtDistance, forecastCombat, resolveCombat } from "../services/combat";
import { cellKey, distance, moveUnit, reachableCells, terrainAt } from "../services/movement";
import { activateSkill, activeSkills } from "../services/skills";

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
    if (!unit || unit.acted || unit.team !== "ally" || this.state.phase !== "player") {
      return new Set();
    }
    return new Set(reachableCells(this.state, unit).keys());
  }

  get selectedAttackable(): Set<string> {
    const unit = this.selectedUnit;
    if (!unit || unit.acted || unit.team !== "ally" || this.state.phase !== "player") {
      return new Set();
    }
    const cells = new Set<string>();
    for (const { cell } of reachableCells(this.state, unit).values()) {
      for (const target of attackableEnemiesFrom(this.state, unit, cell)) {
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
    const weapon = getWeapon(unit.weaponId);
    if (!canAttackAtDistance(weapon, distance(unit.pos, target.pos))) {
      return undefined;
    }
    return forecastCombat(this.state, unit.id, target.id);
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
    if (!selected || selected.acted) {
      return;
    }
    if (occupant?.team === "enemy") {
      this.attackSelected(occupant);
      return;
    }
    if (this.selectedReachable.has(cellKey(cell))) {
      moveUnit(this.state, selected, cell);
      selected.acted = true;
      this.state.log.unshift(`${unitLabel(selected)} 移动至 (${cell.x + 1},${cell.y + 1})。`);
      this.selectedUnitId = undefined;
      this.selectedSkillId = undefined;
      this.autoEndIfDone();
    }
  }

  attackSelected(target: UnitInstance): void {
    const attacker = this.selectedUnit;
    if (!attacker || attacker.acted || attacker.team !== "ally" || target.team === "ally") {
      return;
    }
    const weapon = getWeapon(attacker.weaponId);
    if (!canAttackAtDistance(weapon, distance(attacker.pos, target.pos))) {
      this.state.log.unshift("射程不符。");
      return;
    }
    resolveCombat(this.state, attacker.id, target.id);
    attacker.acted = true;
    this.selectedUnitId = undefined;
    this.selectedSkillId = undefined;
    updateOutcome(this.state);
    this.autoEndIfDone();
  }

  selectSkill(skillId: string): void {
    const unit = this.selectedUnit;
    if (!unit || unit.acted || unit.team !== "ally") {
      return;
    }
    if (skillId === "stigma_awaken" || skillId === "aegis" || skillId === "sprint") {
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

  waitSelected(): void {
    const unit = this.selectedUnit;
    if (!unit || unit.team !== "ally" || unit.acted) {
      return;
    }
    unit.acted = true;
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
      }
    }
    this.state.log.unshift("敌方回合。");
    runEnemyTurn(this.state);
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

  unitText(unit: UnitInstance | undefined): string {
    if (!unit) {
      return "";
    }
    const unitDef = getUnitDef(unit.defId);
    const classDef = getClass(unitDef.classId);
    const weapon = getWeapon(unit.weaponId);
    const statuses = unit.statuses.map((status) => `${status.id}:${status.turns}`).join(" ");
    return `${unitDef.name} ${classDef.name}\nHP ${unit.hp}/${unit.stats.hp}  ${weapon.name}\n力${unit.stats.str} 魔${unit.stats.mag} 技${unit.stats.skill} 速${unit.stats.spd}\n防${unit.stats.def} 魔防${unit.stats.res} 移${unit.stats.move}${statuses ? `\n${statuses}` : ""}`;
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
    const anyReady = this.state.units.some((unit) => unit.alive && unit.team === "ally" && !unit.acted);
    if (!anyReady) {
      this.endPlayerTurn();
    }
  }

  private activateSelectedSkillAt(cell: Cell): void {
    const unit = this.selectedUnit;
    const skillId = this.selectedSkillId;
    if (!unit || !skillId) {
      return;
    }
    const target = unitAt(this.state, cell.x, cell.y);
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
