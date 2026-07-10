import SpriteKit
import SwiftUI

struct GameRootView: View {
    let viewModel: GameSessionViewModel

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
    }

    // 整个游戏壳层统一使用木纹背景，与羊皮纸面板/旗帜标题牌搭配，构成手绘卡通奇幻风的统一视觉语言。
    private var background: some View {
        RiftWoodBackground()
    }

    private var mainMenu: some View {
        RiftPanelScaffold(
            title: "裂隙远征",
            subtitle: "村庄、野外与洞穴之间，第一章的谎言正等着被拆穿。",
            maxWidth: 1_080
        ) {
            HStack(alignment: .top, spacing: 42) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("第一章 · 裂隙村的谎言")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(RiftPalette.textBrown)
                    Text("组建两人小队，在村庄、野外与洞穴中追查一份足以撕裂裂隙村的账本。")
                        .font(.body)
                        .foregroundStyle(RiftPalette.textBrownLight)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {
                        Button("开始新远征") {
                            viewModel.startNewGame()
                        }
                        .buttonStyle(RiftPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                        .accessibilityLabel("开始新游戏")

                        Button("继续 / 读取存档") {
                            viewModel.openSaveLoad()
                        }
                        .buttonStyle(RiftSecondaryButtonStyle())
                        .accessibilityLabel("读取或管理存档")

                        Button("设置") {
                            viewModel.openSettings()
                        }
                        .buttonStyle(RiftSecondaryButtonStyle())
                        .accessibilityLabel("打开设置")
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("回合制战术战斗", systemImage: "scope")
                    Label("自由距离、视线与整数 AP", systemImage: "ruler")
                    Label("共享背包与角色成长", systemImage: "backpack")
                    Label("5 个手动存档 + 安全自动存档", systemImage: "square.and.arrow.down")
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(RiftPalette.textBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(RiftPalette.parchmentShade)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(RiftPalette.outline.opacity(0.45), lineWidth: 1.5))
                )
            }
            .frame(minHeight: 300)

            Text(viewModel.statusText)
                .font(.callout.weight(.medium))
                .foregroundStyle(RiftPalette.textBrownLight)
        }
    }

    private var exploration: some View {
        ZStack {
            GameSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("探索 · \(viewModel.currentAreaDisplayName)")
                            .font(.headline.weight(.heavy))
                        Text(viewModel.statusText)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    .foregroundStyle(RiftPalette.textBrown)

                    Spacer()

                    HStack(spacing: 6) {
                        explorationButton("backpack.fill", title: "队伍档案", action: viewModel.openInventory)
                        explorationButton("list.bullet.rectangle", title: "任务日志", action: viewModel.openQuestLog)
                        explorationButton("square.and.arrow.down", title: "存档", action: viewModel.openSaveLoad)
                        explorationButton("gearshape.fill", title: "设置", action: viewModel.openSettings)
                    }
                }
                .padding(12)
                .riftParchmentPanel(cornerRadius: 16)

                HStack(spacing: 8) {
                    ForEach(viewModel.party) { actor in
                        HStack(spacing: 6) {
                            RiftActorPortrait(classID: actor.classID, size: 32)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(actor.displayName).font(.caption.weight(.bold))
                                Text("\(actor.stats.health)/\(actor.stats.maxHealth) HP")
                                    .font(.caption2.monospacedDigit())
                            }
                        }
                        .foregroundStyle(RiftPalette.textBrown)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RiftPalette.parchment.opacity(0.94), in: Capsule())
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
    }

    private func explorationButton(_ icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.callout.weight(.bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(RiftSecondaryButtonStyle())
        .accessibilityLabel(title)
    }

    private var battle: some View {
        ZStack(alignment: .topLeading) {
            GameSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            if let battleViewModel = viewModel.battleViewModel {
                BattleHUDView(
                    viewModel: battleViewModel,
                    onFinishBattle: viewModel.finishBattle,
                    onReturnToMenu: viewModel.returnToMainMenu
                )
                .padding()
            } else {
                simpleStatePanel
            }
        }
    }

    private var simpleStatePanel: some View {
        VStack(spacing: 16) {
            Text(viewModel.appState.title)
                .font(.largeTitle.bold())
                .foregroundStyle(RiftPalette.textBrown)

            Text(viewModel.statusText)
                .foregroundStyle(RiftPalette.textBrownLight)

            Button("返回主菜单") {
                viewModel.returnToMainMenu()
            }
            .buttonStyle(RiftPrimaryButtonStyle())
            .accessibilityLabel("返回主菜单")
        }
        .frame(maxWidth: 520)
        .padding(40)
        .riftParchmentPanel(cornerRadius: 18)
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
                scene.renderBattle(snapshot)
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
            scene.renderBattle(viewModel.battleViewModel?.sceneSnapshot)
        }
    }
}
