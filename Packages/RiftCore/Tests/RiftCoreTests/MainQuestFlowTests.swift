import Foundation
import XCTest
@testable import RiftCore

final class MainQuestFlowTests: XCTestCase {
    func testBloodDebtMainQuestHasCompleteSingleEndingFlow() throws {
        let catalog = try ContentLoader.load(from: projectDataDirectory())
        let quest = try XCTUnwrap(catalog.quests.first { $0.id == "blood_debt" })
        let dialogueIDs = Set(catalog.dialogues.map(\.id))
        let runtimeDialogs = try loadRuntimeDialogs()
        let runtimeDialogsByID = Dictionary(uniqueKeysWithValues: runtimeDialogs.map { ($0.id, $0) })
        let requiredStoryBeats = [
            "elder_intro",
            "fiance_accuse",
            "cave_entrance_trace",
            "mine_evidence",
            "daughter_reveal",
            "chapter_end_marker",
            "elder_return"
        ]

        XCTAssertEqual(quest.startDialogID, "elder_intro")
        XCTAssertEqual(quest.turnInDialogID, "elder_return")
        for keyword in ["沈砚", "梁铮", "外来法师", "村长", "元素矿"] {
            XCTAssertTrue(quest.summary.contains(keyword), keyword)
        }

        for dialogID in requiredStoryBeats {
            XCTAssertTrue(dialogueIDs.contains(dialogID), dialogID)
            let runtimeDialog = try XCTUnwrap(runtimeDialogsByID[dialogID], dialogID)
            XCTAssertFalse(runtimeDialog.lines.isEmpty, dialogID)
        }

        let finalDialog = try XCTUnwrap(runtimeDialogsByID["elder_return"])
        XCTAssertTrue(finalDialog.lines.joined().contains("顾怀恩"))
        XCTAssertTrue(finalDialog.options.contains { option in
            option.action == "completeQuest" && option.questID == "blood_debt"
        })

        let accepted = try QuestEngine.accept(questID: quest.id, in: QuestState(), definitions: catalog.quests)
        XCTAssertEqual(QuestEngine.status(of: quest.id, in: accepted), .active)

        let completed = try QuestEngine.complete(questID: quest.id, in: accepted, definitions: catalog.quests)
        XCTAssertEqual(QuestEngine.status(of: quest.id, in: completed), .completed)

        let itemIDs = Set(catalog.items.map(\.id))
        let skillIDs = Set(catalog.skills.map(\.id))
        XCTAssertTrue(quest.rewardItemIDs.allSatisfy(itemIDs.contains))
        XCTAssertTrue(quest.rewardSkillIDs.allSatisfy(skillIDs.contains))
    }

    private func loadRuntimeDialogs() throws -> [RuntimeDialog] {
        let url = projectDataDirectory().appending(path: "dialogs.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([RuntimeDialog].self, from: data)
    }

    private func projectDataDirectory() -> URL {
        projectRoot().appending(path: "RiftExpedition/Resources/Data")
    }

    private func projectRoot() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private struct RuntimeDialog: Decodable {
    var id: String
    var speakerName: String
    var lines: [String]
    var options: [RuntimeDialogOption]
}

private struct RuntimeDialogOption: Decodable {
    var id: String
    var title: String
    var action: String
    var questID: String?
}
