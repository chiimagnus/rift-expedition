import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class DialogViewModelTests: XCTestCase {
    func testAcceptQuestOptionUpdatesQuestLog() throws {
        let viewModel = DialogViewModel(scripts: [script], questDefinitions: [quest])

        XCTAssertTrue(viewModel.start(dialogID: "elder_intro"))
        let option = try XCTUnwrap(viewModel.activeDialog?.options.first)

        XCTAssertEqual(viewModel.choose(option), .none)
        XCTAssertEqual(viewModel.questLogEntries.first?.id, "blood_debt")
        XCTAssertEqual(viewModel.questLogEntries.first?.status, .active)
    }


    func testCompleteQuestOptionRequestsAtomicSessionCompletionWithoutMutatingState() throws {
        let session = GameSessionState(
            questState: QuestState(statuses: ["blood_debt": .active])
        )
        let completion = DialogDefinition(
            id: "elder_return",
            speakerName: "村长",
            lines: ["交出证据。"],
            options: [
                DialogOptionDefinition(
                    id: "complete",
                    title: "交付",
                    action: .completeQuest,
                    questID: "blood_debt",
                    encounterID: nil
                )
            ]
        )
        let viewModel = DialogViewModel(
            scripts: [completion],
            questDefinitions: [quest],
            session: session
        )

        XCTAssertTrue(viewModel.start(dialogID: "elder_return"))
        let option = try XCTUnwrap(viewModel.activeDialog?.options.first)

        XCTAssertEqual(viewModel.choose(option), .questCompletionRequested("blood_debt"))
        XCTAssertEqual(session.questState.statuses["blood_debt"], .active)
    }

    func testBattleOptionReturnsEncounterID() throws {
        let viewModel = DialogViewModel(scripts: [script], questDefinitions: [quest])

        XCTAssertTrue(viewModel.start(dialogID: "elder_intro"))
        let option = try XCTUnwrap(viewModel.activeDialog?.options.last)

        XCTAssertEqual(viewModel.choose(option), .startBattle("boar_intro"))
    }

    private var script: DialogDefinition {
        DialogDefinition(
            id: "elder_intro",
            speakerName: "村长",
            lines: ["去村外查清楚。"],
            options: [
                DialogOptionDefinition(id: "accept", title: "接下任务", action: .acceptQuest, questID: "blood_debt", encounterID: nil),
                DialogOptionDefinition(id: "fight", title: "拔剑吧", action: .startBattle, questID: nil, encounterID: "boar_intro")
            ]
        )
    }

    private var quest: QuestDefinition {
        QuestDefinition(
            id: "blood_debt",
            chapterID: "chapter1",
            title: "血债",
            summary: "查清旧矿洞。",
            isMainQuest: false,
            locationHint: "测试地点",
            objectives: ["完成测试目标"],
            startDialogID: "elder_intro",
            turnInDialogID: "elder_return",
            requiredItemIDs: [],
            rewardItemIDs: [],
            rewardSkillIDs: []
        )
    }
}
