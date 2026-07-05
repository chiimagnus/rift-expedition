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
                partyCreation
            case .exploration:
                exploration
            case .dialogue, .battle, .inventory, .saveLoad, .chapterComplete:
                simpleStatePanel
            }
        }
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
            }
            .buttonStyle(.borderedProminent)

            Text(viewModel.statusText)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(56)
    }

    private var partyCreation: some View {
        VStack(spacing: 22) {
            Text("创建队伍")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("首版队伍固定为两人。下一步会接入四职业选择；当前可先进入场景验证应用壳。")
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)

            HStack {
                Button("返回主菜单") {
                    viewModel.returnToMainMenu()
                }

                Button("进入第一张地图") {
                    viewModel.enterExploration()
                }
                .keyboardShortcut(.defaultAction)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: 620)
        .padding(40)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
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
                scene.eventHandler = viewModel
            }
            .onDisappear {
                scene.eventHandler = nil
            }
    }
}
