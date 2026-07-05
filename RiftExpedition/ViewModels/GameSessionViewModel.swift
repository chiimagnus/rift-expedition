import CoreGraphics
import Foundation
import Observation
import RiftCore

@MainActor
@Observable
final class GameSessionViewModel {
    var appState: AppState = .mainMenu
    var statusText = "裂隙正在沉睡。"
    var lastWorldClick: CGPoint?
    var party: [Actor] = []
    let partyCreationViewModel: PartyCreationViewModel

    init(contentBundle: Bundle = .main) {
        partyCreationViewModel = Self.loadPartyCreation(from: contentBundle)
    }

    func startNewGame() {
        appState = .partyCreation
        statusText = "选择两名冒险者后进入第一章。"
    }

    func enterExploration() {
        appState = .exploration
        statusText = "点击地图移动队长。"
    }

    func startChapterWithSelectedParty() {
        let createdParty = partyCreationViewModel.createParty()
        guard createdParty.count == 2 else {
            statusText = "请选择两名不同职业。"
            return
        }

        party = createdParty
        enterExploration()
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

    private static func loadPartyCreation(from bundle: Bundle) -> PartyCreationViewModel {
        guard let dataDirectory = bundle.resourceURL?.appending(path: "Data"),
              let catalog = try? ContentLoader.load(from: dataDirectory)
        else {
            return PartyCreationViewModel(classes: [])
        }
        let skillNames: [String: String] = Dictionary(uniqueKeysWithValues: catalog.skills.map { ($0.id, $0.displayName) })
        return PartyCreationViewModel(classes: catalog.classes, skillNamesByID: skillNames)
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
