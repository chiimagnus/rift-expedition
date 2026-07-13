import RiftCore
import SpriteKit
import SwiftUI

struct GameRootView: View {
    let viewModel: GameSessionViewModel
    @State private var menuReady = false

    var body: some View {
        ZStack {
            background

            switch viewModel.appState {
            case .mainMenu:
                mainMenu
            case .partyCreation:
                PartyCreationView(
                    viewModel: viewModel.partyCreationViewModel,
                    onConfirm: viewModel.startChapterWithSelectedParty,
                    onBack: viewModel.returnToMainMenu
                )
            case .exploration:
                exploration
            case .dialogue:
                DialogView(
                    viewModel: viewModel.dialogViewModel,
                    onClose: viewModel.closePanel,
                    onCompleteQuest: viewModel.applyQuestRewards,
                    onStartBattle: viewModel.beginBattleFromDialog
                )
            case .questLog:
                QuestLogView(
                    entries: viewModel.dialogViewModel.questLogEntries,
                    onClose: viewModel.closePanel
                )
            case .inventory:
                if let inventoryViewModel = viewModel.inventoryViewModel {
                    InventoryView(
                        viewModel: inventoryViewModel,
                        onClose: viewModel.closePanel,
                        initialTab: viewModel.inventoryTab
                    )
                } else {
                    simpleStatePanel
                }
            case .battle:
                battle
            case .saveLoad:
                if let saveLoadViewModel = viewModel.saveLoadViewModel {
                    SaveLoadView(
                        viewModel: saveLoadViewModel,
                        onClose: viewModel.closePanel
                    )
                } else {
                    simpleStatePanel
                }
            case .settings:
                SettingsView(
                    viewModel: viewModel,
                    onClose: viewModel.closePanel
                )
            case .chapterComplete:
                ChapterCompleteView(
                    onReturnToMenu: viewModel.returnToMainMenu,
                    onOpenSaveLoad: viewModel.openSaveLoad
                )
            }

            if viewModel.isDebugOverlayVisible {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        DebugOverlayView(viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
        .scaleEffect(viewModel.uiScale)
        .frame(minWidth: 960, minHeight: 540)
        .animation(.easeInOut(duration: 0.22), value: viewModel.appState)
    }

    private var background: some View {
        RiftWoodBackground()
    }

    private var mainMenu: some View {
        GeometryReader { proxy in
            HStack(spacing: 54) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        RiftLogoMark(size: 50)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RIFT EXPEDITION")
                                .font(.caption.weight(.black))
                                .tracking(3.2)
                                .foregroundStyle(RiftPalette.riftBlue)
                            Text("裂隙远征")
                                .font(.system(size: min(proxy.size.width * 0.072, 72), weight: .black, design: .rounded))
                                .foregroundStyle(RiftPalette.frost)
                        }
                    }

                    Text("第一章 · 裂隙村的谎言")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(RiftPalette.ember)
                        .padding(.top, 22)

                    Text("一场被嫁祸给怪物的失踪案，一本足以摧毁村庄秩序的矿账，以及封层另一侧正在苏醒的回声。")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(RiftPalette.textBrownLight)
                        .lineSpacing(5)
                        .frame(maxWidth: 610, alignment: .leading)
                        .padding(.top, 12)

                    HStack(spacing: 8) {
                        RiftStatusPill(text: "双人小队", tint: RiftPalette.riftBlue, icon: "person.2.fill")
                        RiftStatusPill(text: "自由距离回合制", tint: RiftPalette.riftViolet, icon: "scope")
                        RiftStatusPill(text: "45–60 分钟章节", tint: RiftPalette.ember, icon: "clock.fill")
                    }
                    .padding(.top, 20)

                    VStack(spacing: 10) {
                        Button {
                            viewModel.startNewGame()
                        } label: {
                            HStack {
                                Label("开始新远征", systemImage: "play.fill")
                                Spacer()
                                Text("ENTER")
                                    .font(.caption2.monospaced().weight(.black))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RiftPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)

                        Button {
                            viewModel.openSaveLoad()
                        } label: {
                            HStack {
                                Label("继续 / 读取存档", systemImage: "arrow.clockwise")
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RiftSecondaryButtonStyle())

                        Button {
                            viewModel.openSettings()
                        } label: {
                            HStack {
                                Label("系统与无障碍设置", systemImage: "slider.horizontal.3")
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RiftSecondaryButtonStyle())
                    }
                    .frame(maxWidth: 360)
                    .padding(.top, 30)

                    Text(viewModel.statusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RiftPalette.textBrownLight)
                        .padding(.top, 14)

                    Spacer(minLength: 24)

                    HStack(spacing: 12) {
                        Text("CHAPTER BUILD 01")
                        Circle().frame(width: 3, height: 3)
                        Text("MACOS NATIVE")
                        Circle().frame(width: 3, height: 3)
                        Text("中文")
                    }
                    .font(.caption2.monospaced().weight(.bold))
                    .foregroundStyle(RiftPalette.steel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: menuReady ? 0 : -24)
                .opacity(menuReady ? 1 : 0)

                expeditionDossier
                    .frame(width: min(max(proxy.size.width * 0.31, 310), 420))
                    .offset(x: menuReady ? 0 : 28)
                    .opacity(menuReady ? 1 : 0)
            }
            .padding(.horizontal, max(52, proxy.size.width * 0.07))
            .padding(.vertical, 52)
            .onAppear {
                withAnimation(.easeOut(duration: 0.72)) {
                    menuReady = true
                }
            }
        }
    }

    private var expeditionDossier: some View {
        VStack(alignment: .leading, spacing: 18) {
            RiftSectionHeader("远征简报", eyebrow: "CHAPTER INTEL", systemImage: "map.fill")

            ZStack(alignment: .bottomLeading) {
                RiftIllustrationCard(
                    illustrationID: "chapter1_village_square",
                    height: 210,
                    overlayTint: RiftPalette.riftViolet,
                    cornerRadius: 16
                )
                VStack(alignment: .leading, spacing: 10) {
                    RiftLogoMark(size: 52)
                    Text("第一章：失踪的新娘")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                    Text("纯 2D 卡通手绘内容版：原创立绘、环境关键画与更强音景已经接入。")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                    RiftStatusPill(text: "建议时长 · 20~30 分钟", tint: RiftPalette.riftBlue, icon: "clock.fill")
                }
                .padding(18)
            }

            dossierRow(icon: "building.columns.fill", title: "裂隙村", detail: "表面平静，河水已被矿脉污染")
            dossierRow(icon: "figure.hiking", title: "断塔荒野", detail: "脚印、偷猎者与失控野兽")
            dossierRow(icon: "mountain.2.fill", title: "旧元素矿洞", detail: "封层破裂，真相埋在洞心")

            Rectangle()
                .fill(RiftPalette.outline.opacity(0.35))
                .frame(height: 1)

            HStack {
                Label("建议", systemImage: "lightbulb.fill")
                    .foregroundStyle(RiftPalette.ember)
                Text("选择职责互补的两名成员。")
                    .foregroundStyle(RiftPalette.textBrownLight)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(22)
        .riftParchmentPanel(cornerRadius: 22)
    }

    private func dossierRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(RiftPalette.riftBlue)
                .frame(width: 34, height: 34)
                .background(RiftPalette.riftBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrown)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(RiftPalette.textBrownLight)
            }
            Spacer()
        }
    }

    private var exploration: some View {
        ZStack {
            GameSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            LinearGradient(colors: [.black.opacity(0.32), .clear, .black.opacity(0.36)], startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                explorationHeader
                Spacer()
                HStack(alignment: .bottom, spacing: 14) {
                    partyStatusPanel
                    Spacer()
                    explorationHint
                    Spacer()
                    utilityRail
                }
            }
            .padding(18)
        }
    }

    private var explorationHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(spacing: 12) {
                RiftLogoMark(size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentBiomeLabel.uppercased())
                        .font(.caption2.weight(.black))
                        .tracking(1.6)
                        .foregroundStyle(RiftPalette.riftBlue)
                    Text(viewModel.currentAreaDisplayName)
                        .font(.title3.weight(.black))
                        .foregroundStyle(RiftPalette.frost)
                }
            }

            Rectangle()
                .fill(RiftPalette.outline.opacity(0.42))
                .frame(width: 1, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(activeQuest?.isMainQuest == true ? "主线目标" : "当前行动")
                    .font(.caption2.weight(.black))
                    .tracking(1)
                    .foregroundStyle(RiftPalette.ember)
                Text(activeQuest?.title ?? viewModel.statusText)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(RiftPalette.textBrown)
                    .lineLimit(1)
                if let hint = activeQuest?.locationHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(RiftPalette.textBrownLight)
                        .lineLimit(1)
                }
            }

            Spacer()

            RiftStatusPill(text: "探索中", tint: RiftPalette.success, icon: "location.fill")
        }
        .padding(14)
        .riftParchmentPanel(cornerRadius: 16)
    }

    private var partyStatusPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("远征小队")
                .font(.caption2.weight(.black))
                .tracking(1.2)
                .foregroundStyle(RiftPalette.textBrownLight)

            ForEach(viewModel.party) { actor in
                HStack(spacing: 10) {
                    RiftActorPortrait(classID: actor.classID, size: 46)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(actor.displayName)
                                .font(.callout.weight(.bold))
                                .foregroundStyle(RiftPalette.textBrown)
                            Spacer()
                            Text("Lv.\(actor.level)")
                                .font(.caption2.monospaced().weight(.bold))
                                .foregroundStyle(RiftPalette.textBrownLight)
                        }
                        RiftMetricBar(
                            value: actor.stats.maxHealth == 0 ? 0 : Double(actor.stats.health) / Double(actor.stats.maxHealth),
                            tint: healthTint(for: actor),
                            height: 6
                        )
                        Text("\(actor.stats.health) / \(actor.stats.maxHealth) HP")
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(RiftPalette.textBrownLight)
                    }
                    .frame(width: 150)
                }
            }
        }
        .padding(13)
        .riftParchmentPanel(cornerRadius: 15)
    }

    private var utilityRail: some View {
        HStack(spacing: 6) {
            explorationButton("person.crop.rectangle.stack.fill", title: "队伍档案", action: viewModel.openInventory)
            explorationButton("list.bullet.clipboard.fill", title: "任务日志", action: viewModel.openQuestLog)
            explorationButton("square.and.arrow.down.fill", title: "存档", action: viewModel.openSaveLoad)
            explorationButton("gearshape.fill", title: "设置", action: viewModel.openSettings)
        }
        .padding(8)
        .riftParchmentPanel(cornerRadius: 14)
    }

    private var explorationHint: some View {
        HStack(spacing: 9) {
            RiftKeycap(text: "LMB")
            Text("移动 / 互动")
            RiftKeycap(text: "TAB")
            Text("切换队长")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(RiftPalette.textBrownLight)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.42), in: Capsule())
        .overlay(Capsule().stroke(RiftPalette.outline.opacity(0.34), lineWidth: 1))
    }

    private func explorationButton(_ icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.callout.weight(.bold))
                .frame(width: 30, height: 28)
        }
        .buttonStyle(RiftGhostButtonStyle())
        .help(title)
        .accessibilityLabel(title)
    }

    private var battle: some View {
        ZStack {
            GameSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            LinearGradient(colors: [.black.opacity(0.26), .clear, .black.opacity(0.46)], startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)

            if let battleViewModel = viewModel.battleViewModel {
                BattleHUDView(
                    viewModel: battleViewModel,
                    onFinishBattle: viewModel.finishBattle,
                    onReturnToMenu: viewModel.returnToMainMenu
                )
                .padding(18)
            } else {
                simpleStatePanel
            }
        }
    }

    private var simpleStatePanel: some View {
        VStack(spacing: 16) {
            RiftLogoMark(size: 66)
            Text(viewModel.appState.title)
                .font(.largeTitle.bold())
                .foregroundStyle(RiftPalette.textBrown)
            Text(viewModel.statusText)
                .foregroundStyle(RiftPalette.textBrownLight)
            Button("返回主菜单") {
                viewModel.returnToMainMenu()
            }
            .buttonStyle(RiftPrimaryButtonStyle())
        }
        .frame(maxWidth: 520)
        .padding(40)
        .riftParchmentPanel(cornerRadius: 20)
    }

    private var activeQuest: QuestLogEntry? {
        viewModel.dialogViewModel.questLogEntries.first(where: { $0.status == .active })
    }

    private var currentBiomeLabel: String {
        if viewModel.currentAreaID.contains("cave") { return "旧矿洞" }
        if viewModel.currentAreaID.contains("wilds") { return "断塔荒野" }
        return "裂隙村"
    }

    private func healthTint(for actor: Actor) -> Color {
        guard actor.stats.maxHealth > 0 else { return RiftPalette.danger }
        let ratio = Double(actor.stats.health) / Double(actor.stats.maxHealth)
        if ratio < 0.3 { return RiftPalette.danger }
        if ratio < 0.6 { return RiftPalette.ember }
        return RiftPalette.success
    }
}

private struct GameSceneView: View {
    let viewModel: GameSessionViewModel
    @State private var scene = GameScene.makeScene()

    var body: some View {
        // 打开 `ignoresSiblingOrder: true` 之后，SpriteKit 会按每个节点的 zPosition（图层高低）
        // 做全局排序，而不是按父子层级一层层排。
        // 地图插件 SKTiled 的 `SKTilemap` 会给它解析出来的每个地图图层自己分配一个内部的
        // zPosition；如果不开这个开关，我们直接挂在 worldLayer 下面的内容（队伍标记、NPC、
        // 物品、出口、遭遇点——具体见 GameScene）就可能被 SpriteKit 排到地图图层「看不见」的
        // 位置，表现出来就是「只看到地图，别的都不显示」。这是 SKTiled 官方推荐的 SKView
        // 设置方式，这里再配合把我们自己图层的 zPosition 调得高一些，双重保险。
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .accessibilityLabel("游戏地图")
            .accessibilityHint("点击地面移动，点击角色、物品或触发点互动。")
            .onAppear {
                scene.eventHandler = viewModel
                scene.loadMap(areaID: viewModel.currentAreaID)
                renderSceneState()
            }
            .onDisappear {
                scene.isWorldInputEnabled = false
                scene.eventHandler = nil
            }
            .onChange(of: viewModel.appState) { _, appState in
                scene.isWorldInputEnabled = appState == .exploration || appState == .battle
                scene.loadMap(areaID: viewModel.currentAreaID)
                renderSceneState()
            }
            .onChange(of: viewModel.currentAreaID) { _, areaID in
                scene.loadMap(areaID: areaID)
                renderSceneState()
            }
            .onChange(of: viewModel.explorationController) { _, controller in
                guard viewModel.appState == .exploration else { return }
                scene.renderParty(controller.members, leaderID: controller.leaderID)
            }
            .onChange(of: viewModel.battleViewModel?.sceneSnapshot) { _, snapshot in
                renderBattleSnapshot(snapshot)
            }
    }

    private func renderSceneState() {
        scene.isWorldInputEnabled = viewModel.appState == .exploration || viewModel.appState == .battle
        if viewModel.appState == .exploration {
            scene.renderParty(
                viewModel.explorationController.members,
                leaderID: viewModel.explorationController.leaderID
            )
            scene.renderBattle(nil)
        } else if viewModel.appState == .battle {
            scene.renderParty([], leaderID: nil)
            renderBattleSnapshot(viewModel.battleViewModel?.sceneSnapshot)
        }
    }

    private func renderBattleSnapshot(_ snapshot: BattleSceneSnapshot?) {
        scene.renderBattle(snapshot)
        guard let lastEventID = snapshot?.presentationEvents.last?.id else { return }
        viewModel.battleViewModel?.acknowledgePresentationEvents(through: lastEventID)
    }
}
