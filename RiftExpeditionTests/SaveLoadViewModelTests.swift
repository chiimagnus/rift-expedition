import Foundation
import RiftCore
import XCTest
@testable import RiftExpedition

@MainActor
final class SaveLoadViewModelTests: XCTestCase {
    func testManualSlotSavesAndLoads() {
        let store = makeStore()
        var loadedSave: SaveGame?
        let viewModel = SaveLoadViewModel(
            store: store,
            makeSave: { self.makeSave(areaID: "vertical_slice") },
            applySave: { loadedSave = $0 }
        )

        viewModel.saveManual(slot: .manual(1))
        viewModel.load(slot: .manual(1))

        XCTAssertEqual(loadedSave?.currentAreaID, "vertical_slice")
        XCTAssertEqual(loadedSave?.party.first?.id, "hero")
        XCTAssertTrue(viewModel.rows.first { $0.slot == .manual(1) }?.canLoad == true)
    }

    func testUnsafeAutosaveRequestIsRejected() {
        let viewModel = SaveLoadViewModel(
            store: makeStore(),
            makeSave: { self.makeSave(areaID: "vertical_slice") },
            applySave: { _ in }
        )

        viewModel.requestAutosave(slot: .auto(1), safety: .unsafe)

        XCTAssertEqual(viewModel.message, "自动存档被拒绝：当前不是安全点。")
        XCTAssertFalse(viewModel.rows.first { $0.slot == .auto(1) }?.canLoad == true)
    }

    func testRejectedAutosavePreservesExistingSlot() throws {
        let store = makeStore()
        try store.write(makeSave(areaID: "old_safe_area"), to: .auto(1), safety: .safe)
        let viewModel = SaveLoadViewModel(
            store: store,
            makeSave: { self.makeSave(areaID: "new_unsafe_area") },
            applySave: { _ in }
        )

        viewModel.requestAutosave(slot: .auto(1), safety: .unsafe)

        XCTAssertEqual(try store.read(.auto(1)).currentAreaID, "old_safe_area")
        XCTAssertEqual(viewModel.message, "自动存档被拒绝：当前不是安全点。")
    }

    func testCorruptSlotShowsChineseError() throws {
        let store = makeStore()
        try store.writeRawData(Data("{".utf8), to: .manual(2))
        let viewModel = SaveLoadViewModel(
            store: store,
            makeSave: { self.makeSave(areaID: "vertical_slice") },
            applySave: { _ in }
        )

        let row = try XCTUnwrap(viewModel.rows.first { $0.slot == .manual(2) })

        XCTAssertTrue(row.isCorrupt)
        XCTAssertEqual(row.detail, "损坏存档：无法读取")
    }

    private func makeStore() -> SaveGameStore {
        SaveGameStore(directory: URL.temporaryDirectory.appending(path: UUID().uuidString))
    }

    private func makeSave(areaID: String) -> SaveGame {
        SaveGame(
            currentAreaID: areaID,
            currentSpawnID: "start",
            party: [
                Actor(
                    id: "hero",
                    displayName: "队员",
                    kind: .player,
                    faction: .player,
                    level: 1,
                    stats: Stats(
                        maxHealth: 20,
                        health: 20,
                        attack: 5,
                        defense: 2,
                        evasion: 3,
                        magic: 1,
                        maxActionPoints: 4,
                        actionPoints: 4
                    ),
                    skillIDs: []
                )
            ],
            inventory: PartyInventory()
        )
    }
}
