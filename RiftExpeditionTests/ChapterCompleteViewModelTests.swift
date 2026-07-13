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

        var inventory = session.inventory
        inventory.addItem(id: "element_ore_ledger")
        session.inventory = inventory

        XCTAssertTrue(session.dialogViewModel.start(dialogID: "elder_return"))
        let complete = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "blood_debt" })
        XCTAssertEqual(session.dialogViewModel.choose(complete), .questCompletionRequested("blood_debt"))

        session.completeQuest(questID: "blood_debt")

        XCTAssertEqual(session.appState, .chapterComplete)
        XCTAssertTrue(session.statusText.contains("第一章完成"))
    }

    func testChapterCompletionUsesQuestMetadataInsteadOfLegacyQuestID() {
        let renamedMainQuest = QuestDefinition(
            id: "renamed_main_quest",
            chapterID: "chapter1",
            title: "改名后的主线",
            summary: "完成章节。",
            isMainQuest: true,
            locationHint: "村庄",
            objectives: ["完成目标"],
            startDialogID: "start",
            turnInDialogID: "finish",
            requiredItemIDs: [],
            rewardItemIDs: [],
            rewardSkillIDs: []
        )
        let sideQuest = QuestDefinition(
            id: "optional_side_quest",
            chapterID: "chapter1",
            title: "支线",
            summary: "可选目标。",
            isMainQuest: false,
            locationHint: "河岸",
            objectives: ["探索"],
            startDialogID: "side_start",
            turnInDialogID: "side_finish",
            requiredItemIDs: [],
            rewardItemIDs: [],
            rewardSkillIDs: []
        )
        let questState = QuestState(statuses: ["renamed_main_quest": .completed])

        XCTAssertTrue(GameSessionViewModel.chapterIsComplete(
            chapterID: "chapter1",
            questState: questState,
            questDefinitions: [renamedMainQuest, sideQuest]
        ))
        XCTAssertFalse(GameSessionViewModel.chapterIsComplete(
            chapterID: "chapter2",
            questState: questState,
            questDefinitions: [renamedMainQuest, sideQuest]
        ))
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
