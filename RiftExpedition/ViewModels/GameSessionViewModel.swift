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
    var explorationController = ExplorationController()
    let partyCreationViewModel: PartyCreationViewModel
    let dialogViewModel: DialogViewModel

    init(contentBundle: Bundle = .main) {
        let catalog = Self.loadCatalog(from: contentBundle)
        partyCreationViewModel = Self.makePartyCreation(from: catalog)
        dialogViewModel = DialogViewModel(
            scripts: DialogViewModel.loadScripts(from: contentBundle),
            questDefinitions: catalog?.quests ?? []
        )
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
        explorationController.configureParty(createdParty, at: CGPoint(x: 96, y: 96))
        enterExploration()
    }

    func openSaveLoad() {
        appState = .saveLoad
        statusText = "手动存档与自动存档将在此管理。"
    }

    func openDialog(_ dialogID: String) {
        if dialogViewModel.start(dialogID: dialogID) {
            appState = .dialogue
        } else {
            statusText = "没有找到对话。"
        }
    }

    func openQuestLog() {
        appState = .questLog
    }

    func closePanel() {
        appState = party.isEmpty ? .mainMenu : .exploration
    }

    func beginBattleFromDialog(encounterID: String) {
        appState = .battle
        statusText = "遭遇已触发。"
    }

    func returnToMainMenu() {
        appState = .mainMenu
        statusText = "裂隙正在沉睡。"
        lastWorldClick = nil
    }

    private static func loadCatalog(from bundle: Bundle) -> ContentCatalog? {
        guard let dataDirectory = bundle.resourceURL?.appending(path: "Data") else { return nil }
        return try? ContentLoader.load(from: dataDirectory)
    }

    private static func makePartyCreation(from catalog: ContentCatalog?) -> PartyCreationViewModel {
        guard let catalog else { return PartyCreationViewModel(classes: []) }
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
        if appState == .exploration {
            explorationController.setLeaderDestination(point)
            statusText = "队长移动到：\(Int(point.x)), \(Int(point.y))"
        } else {
            statusText = "目标位置：\(Int(point.x)), \(Int(point.y))"
        }
    }

    func gameSceneDidRequestLeaderSwitch(_ scene: GameScene) {
        guard appState == .exploration else { return }

        explorationController.switchToNextLeader()
        statusText = "已切换队长。"
    }

    func gameScene(_ scene: GameScene, didAdvance deltaTime: TimeInterval) {
        guard appState == .exploration else { return }

        explorationController.advance(deltaTime: deltaTime)
    }
}
