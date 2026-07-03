import { getClass, getTerrain, getUnitDef, getWeapon } from "../data";
import type { Cell, TerrainDef, UnitInstance } from "../models/types";
import { createInitialBattleState, unitAt } from "../services/chapter";
import { forecastCombat } from "../services/combat";
import { cellKey, distance, inBounds, terrainAt } from "../services/movement";
import { BattleViewModel } from "../viewmodels/BattleViewModel";

const TILE = 32;
const COLS = 14;
const ROWS = 10;
const WIDTH = COLS * TILE;
const HEIGHT = ROWS * TILE;

declare const Phaser: any;

export class BattleScene extends Phaser.Scene {
  private vm!: BattleViewModel;
  private board!: any;
  private overlay!: any;
  private texts: any[] = [];

  constructor() {
    super("BattleScene");
  }

  create(): void {
    this.vm = new BattleViewModel(createInitialBattleState());
    this.board = this.add.graphics();
    this.overlay = this.add.graphics();
    this.input.on("pointermove", (pointer: any) => this.vm.setHover(screenToCell(pointer.x, pointer.y)));
    this.input.on("pointerdown", (pointer: any) => {
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

  update(): void {
    this.render();
  }

  private render(): void {
    this.clearTexts();
    this.drawTerrain();
    this.drawHighlights();
    this.drawUnits();
    this.drawHud();
  }

  private drawTerrain(): void {
    this.board.clear();
    for (let y = 0; y < ROWS; y += 1) {
      for (let x = 0; x < COLS; x += 1) {
        const terrain = getTerrain(this.vm.state.grid[y]?.[x] ?? "plains");
        this.board.fillStyle(terrainColor(terrain), 1);
        this.board.fillRect(x * TILE, y * TILE, TILE, TILE);
        this.board.lineStyle(1, 0x1c1d23, 0.55);
        this.board.strokeRect(x * TILE, y * TILE, TILE, TILE);
      }
    }
  }

  private drawHighlights(): void {
    this.overlay.clear();
    const reachable = this.vm.selectedReachable;
    const attackable = this.vm.selectedAttackable;
    for (const key of reachable) {
      const { x, y } = parseCellKey(key);
      this.overlay.fillStyle(0x2f80ed, 0.26);
      this.overlay.fillRect(x * TILE + 2, y * TILE + 2, TILE - 4, TILE - 4);
    }
    for (const key of attackable) {
      const { x, y } = parseCellKey(key);
      this.overlay.fillStyle(0xd64545, 0.34);
      this.overlay.fillRect(x * TILE + 5, y * TILE + 5, TILE - 10, TILE - 10);
    }
    if (this.vm.hoverCell && inBounds(this.vm.state, this.vm.hoverCell)) {
      this.overlay.lineStyle(2, 0xf3efe4, 0.95);
      this.overlay.strokeRect(this.vm.hoverCell.x * TILE + 1, this.vm.hoverCell.y * TILE + 1, TILE - 2, TILE - 2);
    }
  }

  private drawUnits(): void {
    for (const unit of this.vm.state.units) {
      if (!unit.alive) {
        continue;
      }
      const unitDef = getUnitDef(unit.defId);
      const classDef = getClass(unitDef.classId);
      const x = unit.pos.x * TILE;
      const y = unit.pos.y * TILE;
      const fill = unit.team === "ally" ? 0xf0c96a : 0x76b7e8;
      const border = classDef.tags.includes("dragon") ? 0x9b243d : unit.team === "ally" ? 0xfff1b8 : 0xd7f0ff;
      this.overlay.fillStyle(fill, unit.acted ? 0.55 : 1);
      this.overlay.fillRoundedRect(x + 5, y + 4, TILE - 10, TILE - 8, 4);
      this.overlay.lineStyle(2, border, 1);
      this.overlay.strokeRoundedRect(x + 5, y + 4, TILE - 10, TILE - 8, 4);
      this.addText(x + 9, y + 8, unitGlyph(unit), { fontSize: "13px", color: "#17130d", fontStyle: "700" });
      this.overlay.fillStyle(0x101014, 0.8);
      this.overlay.fillRect(x + 5, y + TILE - 8, TILE - 10, 4);
      this.overlay.fillStyle(unit.team === "ally" ? 0x3fbf7f : 0xdb4a4a, 1);
      this.overlay.fillRect(x + 5, y + TILE - 8, Math.max(1, ((TILE - 10) * unit.hp) / unit.stats.hp), 4);
    }
  }

  private drawHud(): void {
    const phaseText = this.vm.state.phase === "player" ? "我方" : this.vm.state.phase === "enemy" ? "敌方" : this.vm.state.phase;
    this.panel(0, 0, WIDTH, 25, 0x101014, 0.82);
    this.addText(8, 5, `${phaseText}  第 ${this.vm.state.turn} 回合`, { fontSize: "12px", color: "#f3efe4" });
    this.endTurnButton();

    const hoverUnit = this.vm.hoverCell ? unitAt(this.vm.state, this.vm.hoverCell.x, this.vm.hoverCell.y) : undefined;
    const selected = this.vm.selectedUnit;
    const infoUnit = hoverUnit ?? selected;
    if (infoUnit) {
      this.panel(4, HEIGHT - 82, 152, 78, 0x111820, 0.88);
      this.addText(10, HEIGHT - 76, this.vm.unitText(infoUnit), { fontSize: "10px", color: "#f3efe4", lineSpacing: 2 });
    }

    if (this.vm.hoverCell && inBounds(this.vm.state, this.vm.hoverCell)) {
      this.panel(WIDTH - 138, HEIGHT - 50, 134, 46, 0x181410, 0.88);
      this.addText(WIDTH - 132, HEIGHT - 43, this.vm.terrainText(this.vm.hoverCell), { fontSize: "10px", color: "#f3efe4" });
      this.addText(WIDTH - 132, HEIGHT - 27, this.objectAt(this.vm.hoverCell), { fontSize: "10px", color: "#d8c596" });
    }

    const preview = this.previewAtHover();
    if (preview) {
      this.panel(164, HEIGHT - 62, 120, 58, 0x211111, 0.9);
      this.addText(170, HEIGHT - 56, `伤害 ${preview.damage}${preview.followUp ? " x2" : ""}`, { fontSize: "11px", color: "#ffd5d5" });
      this.addText(170, HEIGHT - 39, `命中 ${preview.hit}%  暴 ${preview.crit}%`, { fontSize: "10px", color: "#f3efe4" });
      this.addText(170, HEIGHT - 23, `${counterText(preview.triangle)} ${preview.defenderCanCounter ? "可反击" : "不可反击"}`, { fontSize: "10px", color: "#f3efe4" });
    }

    this.panel(WIDTH - 188, 29, 184, 64, 0x101014, 0.72);
    this.addText(WIDTH - 181, 35, this.vm.objectiveText(), { fontSize: "10px", color: "#f3efe4", wordWrap: { width: 172 } });

    this.panel(164, 29, 116, 58, 0x101014, 0.68);
    this.addText(170, 35, this.vm.state.log.slice(0, 3).join("\n"), { fontSize: "9px", color: "#f3efe4", lineSpacing: 2, wordWrap: { width: 105 } });
  }

  private endTurnButton(): void {
    const x = WIDTH - 67;
    const y = 3;
    this.overlay.fillStyle(0x4b3830, 0.95);
    this.overlay.fillRoundedRect(x, y, 60, 19, 3);
    this.overlay.lineStyle(1, 0xe0c27a, 1);
    this.overlay.strokeRoundedRect(x, y, 60, 19, 3);
    const text = this.addText(x + 9, y + 4, "结束", { fontSize: "11px", color: "#f7e7b1" });
    text.setInteractive({ useHandCursor: true });
    text.on("pointerdown", () => {
      this.vm.endPlayerTurn();
      this.render();
    });
  }

  private panel(x: number, y: number, width: number, height: number, color: number, alpha: number): void {
    this.overlay.fillStyle(color, alpha);
    this.overlay.fillRoundedRect(x, y, width, height, 4);
    this.overlay.lineStyle(1, 0x3a3330, alpha);
    this.overlay.strokeRoundedRect(x, y, width, height, 4);
  }

  private previewAtHover() {
    const selected = this.vm.selectedUnit;
    const hover = this.vm.hoverCell;
    if (!selected || !hover) {
      return undefined;
    }
    const target = unitAt(this.vm.state, hover.x, hover.y);
    if (!target || target.team === selected.team) {
      return undefined;
    }
    const weapon = getWeapon(selected.weaponId);
    if (!weapon || distance(selected.pos, target.pos) < weapon.range[0] || distance(selected.pos, target.pos) > weapon.range[1]) {
      return undefined;
    }
    return forecastCombat(this.vm.state, selected.id, target.id);
  }

  private objectAt(cell: Cell): string {
    const unit = unitAt(this.vm.state, cell.x, cell.y);
    if (unit) {
      return getUnitDef(unit.defId).name;
    }
    return terrainAt(this.vm.state, cell).effects.join(" / ") || " ";
  }

  private addText(x: number, y: number, text: string, style: Record<string, unknown>): any {
    const created = this.add.text(x, y, text, { fontFamily: "system-ui, sans-serif", ...style });
    created.setResolution(2);
    this.texts.push(created);
    return created;
  }

  private clearTexts(): void {
    for (const text of this.texts) {
      text.destroy();
    }
    this.texts = [];
  }
}

function screenToCell(x: number, y: number): Cell | undefined {
  const cell = { x: Math.floor(x / TILE), y: Math.floor(y / TILE) };
  if (cell.x < 0 || cell.x >= COLS || cell.y < 0 || cell.y >= ROWS) {
    return undefined;
  }
  return cell;
}

function parseCellKey(key: string): Cell {
  const [xText, yText] = key.split(",");
  const x = Number(xText);
  const y = Number(yText);
  if (!Number.isFinite(x) || !Number.isFinite(y)) {
    throw new Error(`Invalid cell key: ${key}`);
  }
  return { x, y };
}

function terrainColor(terrain: TerrainDef): number {
  const colors: Record<string, number> = {
    plains: 0x6f9f52,
    road: 0xb49a69,
    forest: 0x2f6b45,
    deep_forest: 0x1f4a34,
    mountain: 0x81796b,
    river: 0x3677b5,
    bridge: 0x8a6a45,
    village: 0xc8ad75,
    altar: 0x6d416d,
  };
  return colors[terrain.id] ?? 0x5f684f;
}

function unitGlyph(unit: UnitInstance): string {
  const unitDef = getUnitDef(unit.defId);
  const classDef = getClass(unitDef.classId);
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

function counterText(value: number): string {
  if (value > 0) {
    return "相克 ▲";
  }
  if (value < 0) {
    return "相克 ▼";
  }
  return "相克 -";
}
