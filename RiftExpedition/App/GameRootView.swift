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
                        onClose: viewModel.closePanel
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

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.07),
                Color(red: 0.18, green: 0.15, blue: 0.10),
                Color(red: 0.05, green: 0.06, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var mainMenu: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("裂隙远征")
                .font(.system(size: 64, weight: .black, design: .serif))
                .foregroundStyle(.white)

            Text("村庄、野外与洞穴之间，第一章的谎言正等着被拆穿。")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.76))

            HStack(spacing: 14) {
                Button("新游戏") {
                    viewModel.startNewGame()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel("开始新游戏")

                Button("读取存档") {
                    viewModel.openSaveLoad()
                }
                .accessibilityLabel("读取或管理存档")

                Button("设置") {
                    viewModel.openSettings()
                }
                .accessibilityLabel("打开设置")
            }
            .buttonStyle(.borderedProminent)

            Text(viewModel.statusText)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(56)
    }

    private var exploration: some View {
        ZStack(alignment: .topLeading) {
            GameSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.appState.title)
                    .font(.headline)
                Text(viewModel.statusText)
                    .font(.callout)
                Text("点击地图移动；点击角色、线索、宝箱或草药互动；Tab 切换队长。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                HStack(spacing: 8) {
                    Button("背包") {
                        viewModel.openInventory()
                    }
                    .accessibilityLabel("打开共享背包和角色面板")

                    Button("存档") {
                        viewModel.openSaveLoad()
                    }
                    .accessibilityLabel("打开存档面板")

                    Button("任务日志") {
                        viewModel.openQuestLog()
                    }
                    .accessibilityLabel("打开任务日志")

                    Button("设置") {
                        viewModel.openSettings()
                    }
                    .accessibilityLabel("打开设置")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(14)
            .foregroundStyle(.white)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
            .padding()
            .accessibilityElement(children: .contain)
        }
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
                .foregroundStyle(.white)

            Text(viewModel.statusText)
                .foregroundStyle(.white.opacity(0.72))

            Button("返回主菜单") {
                viewModel.returnToMainMenu()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("返回主菜单")
        }
        .frame(maxWidth: 520)
        .padding(40)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
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
