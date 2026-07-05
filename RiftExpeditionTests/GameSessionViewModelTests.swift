import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class GameSessionViewModelTests: XCTestCase {
    func testClickWhileLeaderIsInEncounterStartsBattleWithoutOverwritingStatus() {
        let session = GameSessionViewModel()
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()
        session.explorationController.configureParty(session.party, at: CGPoint(x: 608, y: 348))

        session.gameScene(GameScene(size: .init(width: 1, height: 1)), didClickWorld: CGPoint(x: 100, y: 100))

        XCTAssertEqual(session.appState, .battle)
        XCTAssertEqual(session.statusText, "遭遇已触发。")
        XCTAssertNotNil(session.battleState)
    }

    func testStartingChapterWritesSafeAutosave() throws {
        let directory = URL.temporaryDirectory
            .appending(path: "RiftExpeditionTests")
            .appending(path: UUID().uuidString)
        let store = SaveGameStore(directory: directory)
        let session = GameSessionViewModel(saveGameStore: store)
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")

        session.startChapterWithSelectedParty()

        let save = try store.read(.auto(1))
        XCTAssertEqual(save.currentAreaID, "vertical_slice")
        XCTAssertEqual(save.party.count, 2)
    }
}
