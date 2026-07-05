import CoreGraphics
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class GameSessionViewModelTests: XCTestCase {
    func testLeaderEnteringExitChangesArea() {
        let session = GameSessionViewModel()
        session.partyCreationViewModel.toggleSelection("warrior")
        session.partyCreationViewModel.toggleSelection("mage")
        session.startChapterWithSelectedParty()
        session.explorationController.configureParty(session.party, at: CGPoint(x: 40, y: 320))

        session.gameScene(GameScene(size: .init(width: 1, height: 1)), didAdvance: 1.0 / 60.0)

        XCTAssertEqual(session.currentAreaID, "village_riverside")
        XCTAssertEqual(session.currentSpawnID, "from_square")
        XCTAssertEqual(session.appState, .exploration)
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

        session.explorationController.configureParty(session.party, at: CGPoint(x: 40, y: 320))
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "village_riverside")

        session.explorationController.configureParty(session.party, at: CGPoint(x: 112, y: 608))
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "wilds_riverbank")

        session.explorationController.configureParty(session.party, at: CGPoint(x: 736, y: 512))
        session.gameScene(scene, didClickWorld: CGPoint(x: 736, y: 512))
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "bitterroot_herb"), 1)

        session.explorationController.configureParty(session.party, at: CGPoint(x: 40, y: 512))
        session.gameScene(scene, didAdvance: 1.0 / 60.0)
        XCTAssertEqual(session.currentAreaID, "village_riverside")

        session.explorationController.configureParty(session.party, at: CGPoint(x: 736, y: 320))
        session.gameScene(scene, didClickWorld: CGPoint(x: 736, y: 320))
        XCTAssertEqual(session.appState, .dialogue)
        XCTAssertEqual(session.dialogViewModel.activeDialog?.id, "healer_return")

        let complete = try XCTUnwrap(session.dialogViewModel.activeDialog?.options.first { $0.questID == "bitterroot_medicine" })
        XCTAssertEqual(session.dialogViewModel.choose(complete), .completedQuest("bitterroot_medicine"))
        session.applyQuestRewards(questID: "bitterroot_medicine")

        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "bitterroot_herb"), 0)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "river_charm"), 1)
        XCTAssertEqual(session.inventoryViewModel?.inventory.count(of: "minor_healing_draught"), 3)
    }
}
