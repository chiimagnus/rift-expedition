import CoreGraphics
import XCTest
@testable import RiftExpedition

@MainActor
final class ChapterCompleteViewModelTests: XCTestCase {
    func testCompletingFinalQuestChangesAppStateToChapterComplete() throws {
        let session = GameSessionViewModel()
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()

        XCTAssertTrue(session.dialogViewModel.start(dialogID: "elder_intro"))
        let accept = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "blood_debt" })
        XCTAssertEqual(session.dialogViewModel.choose(accept), .none)

        XCTAssertTrue(session.dialogViewModel.start(dialogID: "elder_return"))
        let complete = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "blood_debt" })
        XCTAssertEqual(session.dialogViewModel.choose(complete), .completedQuest("blood_debt"))

        session.applyQuestRewards(questID: "blood_debt")

        XCTAssertEqual(session.appState, .chapterComplete)
        XCTAssertTrue(session.statusText.contains("第一章完成"))
    }

    func testMapTriggerOpensDialogueWhenLeaderEntersTriggerFrame() throws {
        let session = GameSessionViewModel()
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()

        let metadata = try TiledMapLoader.loadMetadata(areaID: "village_square")
        let notice = try XCTUnwrap(metadata.triggers.first { $0.triggerID == "village_square_notice" })
        session.explorationController.configureParty(session.party, at: notice.frame.center)
        session.gameScene(GameScene(size: .init(width: 1, height: 1)), didAdvance: 1.0 / 60.0)

        XCTAssertEqual(session.appState, .dialogue)
        XCTAssertEqual(session.dialogViewModel.activeDialog?.id, "notice_board")
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
