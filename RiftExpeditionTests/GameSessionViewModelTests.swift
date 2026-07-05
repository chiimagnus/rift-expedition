import CoreGraphics
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
}
