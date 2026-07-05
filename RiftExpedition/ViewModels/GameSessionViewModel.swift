import CoreGraphics
import Observation

@MainActor
@Observable
final class GameSessionViewModel {
    var appState: AppState = .mainMenu
    var statusText = "裂隙正在沉睡。"
    var lastWorldClick: CGPoint?

    func startNewGame() {
        appState = .partyCreation
        statusText = "选择两名冒险者后进入第一章。"
    }

    func enterExploration() {
        appState = .exploration
        statusText = "点击地图移动队长。"
    }

    func openSaveLoad() {
        appState = .saveLoad
        statusText = "手动存档与自动存档将在此管理。"
    }

    func returnToMainMenu() {
        appState = .mainMenu
        statusText = "裂隙正在沉睡。"
        lastWorldClick = nil
    }
}

extension GameSessionViewModel: GameSceneEventHandling {
    func gameSceneDidLoad(_ scene: GameScene) {
        statusText = "区域已载入。"
    }

    func gameScene(_ scene: GameScene, didClickWorld point: CGPoint) {
        lastWorldClick = point
        statusText = "目标位置：\(Int(point.x)), \(Int(point.y))"
    }
}
