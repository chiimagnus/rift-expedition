import { endingCatalog, getChapter, getClass, getEnding, getTerrain, getUnitDef, getWeapon } from "../data";
import type { CampaignState, Cell, ChapterVictoryCondition, RosterEntry, TerrainDef, UnitInstance } from "../models/types";
import { createInitialBattleState, unitAt } from "../services/chapter";
import { applyStoryChoice, clearCampaign, completeCurrentChapter, createNewCampaign, ensureChapterRoster, loadCampaign, mergeBattleIntoCampaign, saveCampaign } from "../services/campaign";
import { canRosterUseWeapon, classForRoster, classForUnit, promoteRosterUnit, promotionTargets } from "../services/classes";
import { forgeWeaponCost, repairWeaponCost } from "../services/equipment";
import { assignConvoyWeapon, buyWeapon, cycleRosterWeapon, forgeRosterWeapon, repairRosterWeapon, setRosterDeployment } from "../services/loadout";
import { inBounds } from "../services/movement";
import { firstUnviewedSupportConversation, type AvailableSupportConversation, viewSupportConversation } from "../services/supports";
import { BattleViewModel } from "../viewmodels/BattleViewModel";
import { pageSlice } from "./layout";

const TILE = 32;
const COLS = 14;
const ROWS = 10;
const WIDTH = COLS * TILE;
const HEIGHT = ROWS * TILE;
const SHOP_WEAPON_IDS = ["iron_sword", "iron_lance", "short_bow", "fire", "heal_staff"] as const;
const DEPLOY_PAGE_SIZE = 5;

declare const Phaser: any;

export class BattleScene extends Phaser.Scene {
  private campaign = createNewCampaign();
  private vm!: BattleViewModel;
  private board!: any;
  private overlay!: any;
  private uiObjects: any[] = [];
  private uiHitboxes: Array<{ x: number; y: number; width: number; height: number }> = [];
  private activeSupport: AvailableSupportConversation | undefined;
  private deployPage = 0;

  constructor() {
    super("BattleScene");
  }

  create(): void {
    this.campaign = loadCampaign(globalThis.localStorage);
    this.startChapter(this.campaign.currentChapterId);
    this.board = this.add.graphics();
    this.overlay = this.add.graphics();
    this.input.on("pointermove", (pointer: any) => {
      const hover = this.isSystemScreenOpen() || this.pointerHitsUi(pointer.x, pointer.y) ? undefined : screenToCell(pointer.x, pointer.y);
      if (!sameCell(this.vm.hoverCell, hover)) {
        this.vm.setHover(hover);
        this.render();
      }
    });
    this.input.on("pointerdown", (pointer: any) => {
      if (this.isSystemScreenOpen() || this.pointerHitsUi(pointer.x, pointer.y)) {
        return;
      }
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
  }

  private render(): void {
    this.clearUiObjects();
    this.uiHitboxes = [];
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
    for (const cell of objectiveCells(getChapter(this.vm.state.chapterId).victoryCondition)) {
      this.overlay.lineStyle(2, 0xf0c96a, 0.95);
      this.overlay.strokeRect(cell.x * TILE + 4, cell.y * TILE + 4, TILE - 8, TILE - 8);
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
      const classDef = classForUnit(unit);
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
    if (this.campaign.endingId) {
      this.drawEnding();
      return;
    }
    const phaseText = this.vm.state.phase === "deploy" ? "部署" : this.vm.state.phase === "player" ? "我方" : this.vm.state.phase === "enemy" ? "敌方" : this.vm.state.phase;
    this.panel(0, 0, WIDTH, 25, 0x101014, 0.82);
    this.addText(8, 5, `${phaseText}  第 ${this.vm.state.turn} 回合`, { fontSize: "12px", color: "#f3efe4" });
    if (this.vm.state.phase === "deploy") {
      this.drawDeployPanel();
      if (this.activeSupport) {
        this.drawSupportPanel();
      }
      return;
    }
    this.endTurnButton();

    const hoverUnit = this.vm.hoverCell ? unitAt(this.vm.state, this.vm.hoverCell.x, this.vm.hoverCell.y) : undefined;
    const selected = this.vm.selectedUnit;
    const infoUnit = hoverUnit ?? selected;
    if (infoUnit) {
      this.panel(4, HEIGHT - 82, 152, 78, 0x111820, 0.88);
      this.addText(10, HEIGHT - 76, this.vm.unitText(infoUnit), { fontSize: "10px", color: "#f3efe4", lineSpacing: 2 });
    }
    this.drawActionMenu();

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
    this.addText(WIDTH - 181, 35, `${this.vm.chapterTitle()}\n${this.vm.objectiveText()}`, { fontSize: "10px", color: "#f3efe4", wordWrap: { width: 172 } });

    this.panel(164, 29, 116, 58, 0x101014, 0.68);
    this.addText(170, 35, this.vm.state.log.slice(0, 3).join("\n"), { fontSize: "9px", color: "#f3efe4", lineSpacing: 2, wordWrap: { width: 105 } });

    if (this.vm.state.phase === "victory") {
      this.drawVictoryPanel();
    } else if (this.vm.state.phase === "defeat") {
      this.drawDefeatPanel();
    }
    if (this.activeSupport) {
      this.drawSupportPanel();
    }
  }

  private endTurnButton(): void {
    const x = WIDTH - 67;
    const y = 3;
    this.button(x, y, 60, 19, "结束", () => {
      this.vm.endPlayerTurn();
      this.render();
    });
  }

  private drawActionMenu(): void {
    const unit = this.vm.selectedUnit;
    if (!unit || unit.acted || unit.team !== "ally" || this.vm.state.phase !== "player") {
      this.button(6, 28, 58, 18, "新战役", () => {
        clearCampaign(globalThis.localStorage);
        this.campaign = createNewCampaign();
        this.activeSupport = undefined;
        this.startChapter(this.campaign.currentChapterId);
        this.render();
      });
      const support = firstUnviewedSupportConversation(this.campaign);
      if (support && this.vm.state.phase === "player") {
        this.button(68, 28, 58, 18, `支援${support.rank}`, () => {
          this.activeSupport = support;
          this.render();
        });
      }
      return;
    }

    const x = 160;
    let y = HEIGHT - 28;
    this.button(x, y, 46, 18, "待机", () => {
      this.vm.waitSelected();
      this.render();
    });
    let offset = 50;
    if (this.vm.canVisitSelected()) {
      this.button(x + offset, y, 46, 18, "访问", () => {
        this.vm.visitSelected();
        this.render();
      });
      offset += 50;
    }
    for (const skill of this.vm.activeSkillList(unit).slice(0, 3)) {
      this.button(x + offset, y, 58, 18, skill.name, () => {
        this.vm.selectSkill(skill.id);
        this.render();
      });
      offset += 62;
    }
    if (this.vm.selectedSkillId) {
      y -= 20;
      this.panel(x, y, 180, 18, 0x2b1a1a, 0.88);
      this.addText(x + 6, y + 4, `技能目标：${this.vm.selectedSkillId}`, { fontSize: "10px", color: "#ffd5d5" });
    }
  }

  private panel(x: number, y: number, width: number, height: number, color: number, alpha: number): void {
    this.addHitbox(x, y, width, height);
    this.overlay.fillStyle(color, alpha);
    this.overlay.fillRoundedRect(x, y, width, height, 4);
    this.overlay.lineStyle(1, 0x3a3330, alpha);
    this.overlay.strokeRoundedRect(x, y, width, height, 4);
  }

  private previewAtHover() {
    return this.vm.preview;
  }

  private objectAt(cell: Cell): string {
    const unit = unitAt(this.vm.state, cell.x, cell.y);
    if (unit) {
      return getUnitDef(unit.defId).name;
    }
    return this.vm.objectText(cell);
  }

  private addText(x: number, y: number, text: string, style: Record<string, unknown>): any {
    const created = this.add.text(x, y, text, { fontFamily: "system-ui, sans-serif", ...style });
    created.setResolution(2);
    this.uiObjects.push(created);
    return created;
  }

  private startChapter(chapterId: string, resetDeployPage = true): void {
    if (resetDeployPage) {
      this.deployPage = 0;
    }
    this.campaign = ensureChapterRoster(this.campaign, chapterId);
    saveCampaign(globalThis.localStorage, this.campaign);
    const state = createInitialBattleState(chapterId, this.campaign);
    this.vm = new BattleViewModel(state);
  }

  private drawDeployPanel(): void {
    const chapter = getChapter(this.vm.state.chapterId);
    const deployableIds = this.deployableUnitIds();
    const deployable = this.campaign.roster.filter((entry) => deployableIds.includes(entry.unitDefId) && !this.campaign.fallen.includes(entry.unitDefId));
    const page = pageSlice(deployable, this.deployPage, DEPLOY_PAGE_SIZE);
    const deployedCount = deployable.filter((entry) => entry.deployed).length;
    this.deployPage = page.page;

    this.panel(6, 28, WIDTH - 12, HEIGHT - 34, 0x101014, 0.96);
    this.addText(16, 38, "战前部署", { fontSize: "15px", color: "#f7e7b1", fontStyle: "700" });
    const support = firstUnviewedSupportConversation(this.campaign);
    if (support) {
      this.button(WIDTH - 134, 38, 56, 20, `支援${support.rank}`, () => {
        this.activeSupport = support;
        this.render();
      });
    }
    this.button(WIDTH - 72, 38, 56, 20, "开战", () => {
      this.vm.beginBattle();
      this.render();
    });
    this.addText(16, 61, chapter.objective, { fontSize: "10px", color: "#f3efe4", wordWrap: { width: 260 }, lineSpacing: 2 });
    this.addText(16, 87, `出击 ${deployedCount}/${deployable.length}  金 ${this.campaign.gold}  仓 ${this.convoySummary()}`, {
      fontSize: "10px",
      color: "#d8c596",
      wordWrap: { width: 260 },
    });
    this.addText(296, 42, "侦察地图", { fontSize: "10px", color: "#e0c27a" });
    this.drawScoutMap(296, 58, 10);

    SHOP_WEAPON_IDS.forEach((weaponId, index) => {
      this.button(16 + index * 55, 108, 52, 18, `买${getWeapon(weaponId).name}`, () => {
        this.applyCampaignChange(() => buyWeapon(this.campaign, weaponId));
      });
    });

    page.items.forEach((entry, index) => {
      const y = 136 + index * 29;
      const unitDef = getUnitDef(entry.unitDefId);
      this.addText(16, y, `${unitDef.name} ${classForRoster(entry).name} ${entry.deployed ? "出" : "待"}\n${this.rosterWeaponText(entry)}`, { fontSize: "9px", color: "#f3efe4", lineSpacing: 1 });
      this.button(142, y + 1, 42, 18, entry.deployed ? "待命" : "出战", () => {
        this.applyCampaignChange(() => setRosterDeployment(this.campaign, entry.unitDefId, !entry.deployed, deployableIds));
      });
      this.button(188, y + 1, 30, 18, "换", () => {
        this.applyCampaignChange(() => cycleRosterWeapon(this.campaign, entry.unitDefId));
      });
      const convoyWeaponId = this.firstUsableConvoyWeapon(entry);
      if (convoyWeaponId) {
        this.button(222, y + 1, 30, 18, "取", () => {
          this.applyCampaignChange(() => assignConvoyWeapon(this.campaign, entry.unitDefId, convoyWeaponId));
        });
      }
      if (repairWeaponCost(entry) > 0) {
        this.button(256, y + 1, 30, 18, "修", () => {
          this.applyCampaignChange(() => repairRosterWeapon(this.campaign, entry.unitDefId));
        });
      }
      if (forgeWeaponCost(entry) > 0) {
        this.button(290, y + 1, 30, 18, "锻", () => {
          this.applyCampaignChange(() => forgeRosterWeapon(this.campaign, entry.unitDefId));
        });
      }
      promotionTargets(entry).slice(0, 3).forEach((classId, targetIndex) => {
        this.button(324 + targetIndex * 34, y + 1, 32, 18, getClass(classId).name.slice(0, 2), () => {
          this.applyCampaignChange(() => promoteRosterUnit(this.campaign, entry.unitDefId, classId));
        });
      });
    });

    if (page.totalPages > 1) {
      this.button(16, 292, 54, 20, "上一页", () => {
        this.deployPage -= 1;
        this.render();
      });
      this.button(378, 292, 54, 20, "下一页", () => {
        this.deployPage += 1;
        this.render();
      });
    }
    this.addText(188, 296, `第 ${page.page + 1}/${page.totalPages} 页  ${page.start + 1}-${page.end}/${deployable.length}`, {
      fontSize: "10px",
      color: "#8fa1b2",
    });
  }

  private drawScoutMap(x: number, y: number, scale: number): void {
    this.overlay.lineStyle(1, 0x3a3330, 1);
    this.overlay.strokeRect(x - 1, y - 1, COLS * scale + 2, ROWS * scale + 2);
    for (let row = 0; row < ROWS; row += 1) {
      for (let col = 0; col < COLS; col += 1) {
        const terrain = getTerrain(this.vm.state.grid[row]?.[col] ?? "plains");
        this.overlay.fillStyle(terrainColor(terrain), 0.92);
        this.overlay.fillRect(x + col * scale, y + row * scale, scale - 1, scale - 1);
      }
    }
    for (const unit of this.vm.state.units) {
      if (!unit.alive) {
        continue;
      }
      this.overlay.fillStyle(unit.team === "ally" ? 0xf0c96a : 0xdb4a4a, 1);
      this.overlay.fillRect(x + unit.pos.x * scale + 2, y + unit.pos.y * scale + 2, scale - 4, scale - 4);
    }
  }

  private drawSupportPanel(): void {
    const support = this.activeSupport;
    if (!support) {
      return;
    }
    const conversation = support.pair.conversations.find((candidate) => candidate.rank === support.rank);
    if (!conversation) {
      return;
    }
    this.drawSystemBackdrop();
    const names = support.pair.units.map((unitId) => getUnitDef(unitId).name).join(" × ");
    this.panel(36, 48, 376, 222, 0x101014, 0.97);
    this.addText(54, 64, `${names} · ${support.rank}`, { fontSize: "16px", color: "#f7e7b1", fontStyle: "700" });
    this.addText(54, 92, `${conversation.lines.join("\n")}\n——${conversation.effect}`, {
      fontSize: "11px",
      color: "#f3efe4",
      lineSpacing: 5,
      wordWrap: { width: 340 },
    });
    this.button(144, 238, 160, 20, "确认", () => {
      this.campaign = viewSupportConversation(this.campaign, support.pair.id, support.rank);
      this.syncRosterSkillsToBattle();
      saveCampaign(globalThis.localStorage, this.campaign);
      this.activeSupport = undefined;
      this.render();
    });
  }

  private drawVictoryPanel(): void {
    const chapter = getChapter(this.vm.state.chapterId);
    this.drawSystemBackdrop();
    this.panel(58, 76, 332, 172, 0x111820, 0.94);
    this.addText(70, 88, `${chapter.title} 完成`, { fontSize: "16px", color: "#f7e7b1", fontStyle: "700" });
    this.addText(70, 112, (chapter.victoryText ?? ["战斗结束。"]).join("\n"), { fontSize: "11px", color: "#f3efe4", wordWrap: { width: 306 }, lineSpacing: 4 });

    if (chapter.choice && this.campaign.flags[chapter.choice.options[0]?.flag ?? ""] == null) {
      this.addText(70, 154, chapter.choice.prompt, { fontSize: "11px", color: "#e0c27a", wordWrap: { width: 306 } });
      chapter.choice.options.forEach((option, index) => {
        this.button(72, 174 + index * 22, 300, 18, option.text, () => this.advanceAfterChoice(index));
      });
      return;
    }

    this.button(144, 216, 160, 20, chapter.nextChapterId ? "进入下一章" : "查看结局", () => this.advanceCampaign());
  }

  private drawDefeatPanel(): void {
    this.drawSystemBackdrop();
    this.panel(86, 100, 276, 100, 0x201010, 0.94);
    this.addText(112, 116, "败北", { fontSize: "18px", color: "#ffd5d5", fontStyle: "700" });
    this.addText(112, 143, "战线崩溃。重新开始本章。", { fontSize: "11px", color: "#f3efe4" });
    this.button(144, 169, 160, 20, "重试", () => this.startChapter(this.campaign.currentChapterId));
  }

  private drawEnding(): void {
    if (!this.campaign.endingId) {
      return;
    }
    const ending = getEnding(this.campaign.endingId);
    this.drawSystemBackdrop();
    this.panel(38, 52, 372, 210, 0x101014, 0.96);
    this.addText(58, 70, ending.title, { fontSize: "20px", color: "#f7e7b1", fontStyle: "700" });
    this.addText(58, 100, `${ending.tone}\n${ending.text.join("\n")}`, { fontSize: "12px", color: "#f3efe4", wordWrap: { width: 332 }, lineSpacing: 5 });
    this.addText(58, 176, `触发条件：${ending.condition}`, { fontSize: "10px", color: "#d8c596", wordWrap: { width: 332 } });
    this.button(142, 224, 164, 22, "新战役", () => {
      clearCampaign(globalThis.localStorage);
      this.campaign = createNewCampaign();
      this.startChapter(this.campaign.currentChapterId);
    });
    this.addText(112, 252, `${endingCatalog.length} 个结局已接入`, { fontSize: "10px", color: "#8fa1b2" });
  }

  private advanceAfterChoice(optionIndex: number): void {
    const chapter = getChapter(this.vm.state.chapterId);
    if (chapter.choice) {
      this.campaign = applyStoryChoice(this.campaign, chapter.choice, optionIndex);
    }
    this.advanceCampaign();
  }

  private advanceCampaign(): void {
    this.campaign = mergeBattleIntoCampaign(this.campaign, this.vm.state);
    this.campaign = completeCurrentChapter(this.campaign);
    saveCampaign(globalThis.localStorage, this.campaign);
    if (!this.campaign.endingId) {
      this.startChapter(this.campaign.currentChapterId);
    }
    this.render();
  }

  private syncRosterSkillsToBattle(): void {
    const rosterByUnit = new Map(this.campaign.roster.map((entry) => [entry.unitDefId, entry]));
    for (const unit of this.vm.state.units) {
      const entry = rosterByUnit.get(unit.defId);
      if (unit.team === "ally" && entry) {
        unit.classId = entry.classId;
        unit.skillIds = [...entry.skillIds];
      }
    }
  }

  private applyCampaignChange(update: () => CampaignState): void {
    try {
      this.campaign = update();
      saveCampaign(globalThis.localStorage, this.campaign);
      this.startChapter(this.campaign.currentChapterId, false);
    } catch (error) {
      this.vm.state.log.unshift(error instanceof Error ? error.message : "操作失败。");
    }
    this.render();
  }

  private deployableUnitIds(): string[] {
    const ids = getChapter(this.vm.state.chapterId).deployments
      .filter((deployment) => deployment.team === "ally")
      .map((deployment) => deployment.unitDefId);
    return [...new Set(ids)];
  }

  private convoySummary(): string {
    const entries = Object.entries(this.campaign.convoy).filter(([, count]) => count > 0);
    if (entries.length === 0) {
      return "空";
    }
    return entries
      .slice(0, 2)
      .map(([weaponId, count]) => `${getWeapon(weaponId).name}${count}`)
      .join(" ");
  }

  private firstUsableConvoyWeapon(entry: RosterEntry): string | undefined {
    return Object.entries(this.campaign.convoy).find(([weaponId, count]) => count > 0 && !entry.weaponIds.includes(weaponId) && canRosterUseWeapon(entry, weaponId))?.[0];
  }

  private rosterWeaponText(entry: RosterEntry): string {
    const weapon = getWeapon(entry.weaponId);
    const uses = entry.weaponUses[entry.weaponId] ?? weapon.durability;
    const forge = entry.weaponForge[entry.weaponId] ?? 0;
    return `${weapon.name}${forge ? `+${forge}` : ""} ${uses}/${weapon.durability}`;
  }

  private drawSystemBackdrop(): void {
    this.addHitbox(0, 25, WIDTH, HEIGHT - 25);
    this.overlay.fillStyle(0x05060a, 0.76);
    this.overlay.fillRect(0, 25, WIDTH, HEIGHT - 25);
  }

  private button(x: number, y: number, width: number, height: number, label: string, onClick: () => void): void {
    this.addHitbox(x, y, width, height);
    this.overlay.fillStyle(0x4b3830, 0.95);
    this.overlay.fillRoundedRect(x, y, width, height, 3);
    this.overlay.lineStyle(1, 0xe0c27a, 1);
    this.overlay.strokeRoundedRect(x, y, width, height, 3);
    this.addText(x + 8, y + 4, label, { fontSize: "10px", color: "#f7e7b1" });
    const zone = this.add.zone(x, y, width, height).setOrigin(0, 0).setInteractive({ useHandCursor: true });
    zone.on("pointerdown", (_pointer: unknown, _localX: unknown, _localY: unknown, event: { stopPropagation?: () => void } | undefined) => {
      event?.stopPropagation?.();
      onClick();
    });
    this.uiObjects.push(zone);
  }

  private addHitbox(x: number, y: number, width: number, height: number): void {
    this.uiHitboxes.push({ x, y, width, height });
  }

  private pointerHitsUi(x: number, y: number): boolean {
    return this.uiHitboxes.some((box) => x >= box.x && x <= box.x + box.width && y >= box.y && y <= box.y + box.height);
  }

  private isSystemScreenOpen(): boolean {
    return Boolean(this.campaign.endingId || this.activeSupport || this.vm.state.phase === "deploy" || this.vm.state.phase === "victory" || this.vm.state.phase === "defeat");
  }

  private clearUiObjects(): void {
    for (const object of this.uiObjects) {
      object.destroy();
    }
    this.uiObjects = [];
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

function sameCell(left: Cell | undefined, right: Cell | undefined): boolean {
  return left?.x === right?.x && left?.y === right?.y;
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
  const classDef = classForUnit(unit);
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

function objectiveCells(condition: ChapterVictoryCondition | undefined): Cell[] {
  if (!condition) {
    return [];
  }
  if (condition.type === "seize" || condition.type === "escape") {
    return [{ x: condition.x, y: condition.y }];
  }
  if (condition.type === "all" || condition.type === "any") {
    return condition.conditions.flatMap(objectiveCells);
  }
  return [];
}
