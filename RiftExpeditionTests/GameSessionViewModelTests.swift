import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class GameSessionViewModelTests: XCTestCase {
    func testAreaIDsMapToRegionalBGMCues() {
        XCTAssertEqual(AudioService.bgmCue(for: "village_square"), .villageTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "village_riverside"), .villageTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "wilds_road"), .wildsTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "wilds_riverbank"), .wildsTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "cave_entrance"), .caveTheme)
        XCTAssertEqual(AudioService.bgmCue(for: "cave_depths"), .caveTheme)
    }

    func testLeaderEnteringExitChangesArea() throws {
        let session = GameSessionViewModel()
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()
        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_square", to: "village_riverside")
        )

        session.gameScene(GameScene(size: .init(width: 1, height: 1)), didAdvance: 1.0 / 60.0)

        XCTAssertEqual(session.currentAreaID, "village_riverside")
        XCTAssertEqual(session.currentSpawnID, "from_square")
        XCTAssertEqual(session.appState, .exploration)
        XCTAssertEqual(session.statusText, "进入区域：裂隙村河岸")
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
        XCTAssertEqual(save.currentAreaID, "village_square")
        XCTAssertEqual(save.party.count, 2)
    }

    func testBitterrootCanBePickedUpAndTurnedInForRewards() throws {
        let session = GameSessionViewModel()
        let scene = GameScene(size: .init(width: 1, height: 1))
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()

        XCTAssertTrue(session.dialogViewModel.start(dialogID: "healer_request"))
        let accept = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "bitterroot_medicine" })
        XCTAssertEqual(session.dialogViewModel.choose(accept), .none)

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_square", to: "village_riverside")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "village_riverside")

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "village_riverside", to: "wilds_riverbank")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "wilds_riverbank")

        let bitterrootPosition = try itemPosition(in: "wilds_riverbank", itemID: "bitterroot_herb")
        session.explorationController.configureParty(session.party, at: bitterrootPosition)
        session.gameScene(scene, didClickWorld: bitterrootPosition)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "bitterroot_herb"), 1)

        session.explorationController.configureParty(
            session.party,
            at: try exitCenter(in: "wilds_riverbank", to: "village_riverside")
        )
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "village_riverside")
        if session.appState == .dialogue {
            session.closePanel()
        }

        let healerPosition = try npcPosition(in: "village_riverside", actorID: "healer")
        session.explorationController.configureParty(session.party, at: healerPosition)
        session.gameScene(scene, didClickWorld: healerPosition)
        XCTAssertEqual(session.appState, .dialogue)
        XCTAssertEqual(session.dialogViewModel.activeDialog?.id, "healer_return")

        let complete = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "bitterroot_medicine" })
        XCTAssertEqual(session.dialogViewModel.choose(complete), .completedQuest("bitterroot_medicine"))
        session.applyQuestRewards(questID: "bitterroot_medicine")

        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "bitterroot_herb"), 0)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "river_charm"), 1)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "minor_healing_draught"), 3)
    }

    private func exitCenter(in areaID: String, to targetAreaID: String) throws -> CGPoint {
        let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
        let exit = try XCTUnwrap(metadata.exits.first { $0.targetAreaID == targetAreaID })
        return exit.frame.center
    }

    private func itemPosition(in areaID: String, itemID: String) throws -> CGPoint {
        let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
        return try XCTUnwrap(metadata.items.first { $0.itemID == itemID }).position
    }

    private func npcPosition(in areaID: String, actorID: String) throws -> CGPoint {
        let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
        return try XCTUnwrap(metadata.npcs.first { $0.actorID == actorID }).position
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
