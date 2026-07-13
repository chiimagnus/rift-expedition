import XCTest
@testable import RiftCore

final class QuestEngineTests: XCTestCase {
    func testAcceptingAndCompletingQuestUpdatesStateDeterministically() throws {
        let quest = QuestDefinition(
            id: "blood_debt",
            chapterID: "chapter1",
            title: "血债",
            summary: "和村长确认旧矿洞线索。",
            startDialogID: "elder_intro",
            turnInDialogID: "elder_return",
            requiredItemIDs: []
        )

        let accepted = try QuestEngine.accept(questID: "blood_debt", in: QuestState(), definitions: [quest])
        XCTAssertEqual(QuestEngine.status(of: "blood_debt", in: accepted), .active)

        let completed = try QuestEngine.complete(questID: "blood_debt", in: accepted, definitions: [quest])
        XCTAssertEqual(QuestEngine.status(of: "blood_debt", in: completed), .completed)
        XCTAssertEqual(QuestEngine.logEntries(in: completed, definitions: [quest]).first?.objective, "已完成：和村长确认旧矿洞线索。")
    }

    func testCompletingInactiveQuestFails() {
        let quest = QuestDefinition(
            id: "blood_debt",
            chapterID: "chapter1",
            title: "血债",
            summary: "和村长确认旧矿洞线索。",
            startDialogID: "elder_intro",
            requiredItemIDs: []
        )

        XCTAssertThrowsError(try QuestEngine.complete(questID: "blood_debt", in: QuestState(), definitions: [quest])) { error in
            XCTAssertEqual(error as? QuestEngineError, .questNotActive("blood_debt"))
        }
    }
}
