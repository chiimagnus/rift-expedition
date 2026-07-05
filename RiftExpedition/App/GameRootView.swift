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
                if let battleViewModel = viewModel.battleViewModel {
                    BattleHUDView(
                        viewModel: battleViewModel,
                        onReturnToMenu: viewModel.returnToMainMenu
                    )
                } else {
                    simpleStatePanel
                }
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
                simpleStatePanel
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

                Button("读取存档") {
                    viewModel.openSaveLoad()
                }

                Button("设置") {
                    viewModel.openSettings()
                }
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
            ExplorationSceneView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.appState.title)
                    .font(.headline)
                Text(viewModel.statusText)
                    .font(.callout)
                HStack {
                    Button("和村长交谈") {
                        viewModel.openDialog("elder_intro")
                    }
                    Button("背包") {
                        viewModel.openInventory()
                    }
                    Button("存档") {
                        viewModel.openSaveLoad()
                    }
                    Button("任务日志") {
                        viewModel.openQuestLog()
                    }
                    Button("设置") {
                        viewModel.openSettings()
                    }
                }
            }
            .padding(14)
            .foregroundStyle(.white)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
            .padding()
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
        }
        .frame(maxWidth: 520)
        .padding(40)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct ExplorationSceneView: View {
    let viewModel: GameSessionViewModel
    @State private var scene = GameScene.makeScene()

    var body: some View {
        SpriteView(scene: scene)
            .onAppear {
                scene.isWorldInputEnabled = viewModel.appState == .exploration
                scene.eventHandler = viewModel
                scene.renderParty(
                    viewModel.explorationController.members,
                    leaderID: viewModel.explorationController.leaderID
                )
            }
            .onDisappear {
                scene.isWorldInputEnabled = false
                scene.eventHandler = nil
            }
            .onChange(of: viewModel.appState) { _, appState in
                scene.isWorldInputEnabled = appState == .exploration
            }
            .onChange(of: viewModel.explorationController) { _, controller in
                scene.renderParty(controller.members, leaderID: controller.leaderID)
            }
    }
}
