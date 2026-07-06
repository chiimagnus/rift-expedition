import Foundation
import XCTest
@testable import RiftCore

final class SideQuestRewardTests: XCTestCase {
    func testBitterrootSideQuestCanBeAcceptedCompletedAndRewardsResolve() throws {
        let catalog = try ContentLoader.load(from: projectDataDirectory())
        let quest = try XCTUnwrap(catalog.quests.first { $0.id == "bitterroot_medicine" })
        let itemIDs = Set(catalog.items.map(\.id))
        let runtimeDialogs = try loadRuntimeDialogs()
        let runtimeDialogsByID = Dictionary(uniqueKeysWithValues: runtimeDialogs.map { ($0.id, $0) })

        XCTAssertEqual(quest.startDialogID, "healer_request")
        XCTAssertEqual(quest.turnInDialogID, "healer_return")
        XCTAssertTrue(quest.rewardItemIDs.contains("minor_healing_draught"))
        XCTAssertTrue(quest.rewardItemIDs.contains("river_charm"))
        XCTAssertTrue(quest.rewardItemIDs.allSatisfy(itemIDs.contains))

        let startDialog = try XCTUnwrap(runtimeDialogsByID["healer_request"])
        XCTAssertTrue(startDialog.options.contains { $0.action == "acceptQuest" && $0.questID == quest.id })

        let turnInDialog = try XCTUnwrap(runtimeDialogsByID["healer_return"])
        XCTAssertTrue(turnInDialog.lines.joined().contains("苦根草"))
        XCTAssertTrue(turnInDialog.options.contains { $0.action == "completeQuest" && $0.questID == quest.id })

        let accepted = try QuestEngine.accept(questID: quest.id, in: QuestState(), definitions: catalog.quests)
        let completed = try QuestEngine.complete(questID: quest.id, in: accepted, definitions: catalog.quests)
        XCTAssertEqual(QuestEngine.status(of: quest.id, in: completed), .completed)
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
