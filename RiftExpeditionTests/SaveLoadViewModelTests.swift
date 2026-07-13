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
            makeSave: { self.makeSave(areaID: "village_square") },
            applySave: { loadedSave = $0; return .applied }
        )

        viewModel.saveManual(slot: .manual(1))
        viewModel.load(slot: .manual(1))

        XCTAssertEqual(loadedSave?.currentAreaID, "village_square")
        XCTAssertEqual(loadedSave?.party.first?.id, "hero")
        XCTAssertTrue(viewModel.rows.first { $0.slot == .manual(1) }?.canLoad == true)
    }

    func testRejectedApplyDoesNotReportLoadSuccess() {
        let store = makeStore()
        try? store.write(makeSave(areaID: "village_square"), to: .manual(1), safety: .safe)
        var applyCount = 0
        let viewModel = SaveLoadViewModel(
            store: store,
            makeSave: { self.makeSave(areaID: "village_square") },
            applySave: { _ in
                applyCount += 1
                return .rejected("存档引用了无效地图或出生点。")
            }
        )

        viewModel.load(slot: .manual(1))

        XCTAssertEqual(applyCount, 1)
        XCTAssertEqual(viewModel.message, "读取失败：存档引用了无效地图或出生点。")
    }

    func testRowsUseInjectedAreaDisplayName() throws {
        let store = makeStore()
        try store.write(makeSave(areaID: "village_square"), to: .manual(1), safety: .safe)
        let viewModel = SaveLoadViewModel(
            store: store,
            makeSave: { self.makeSave(areaID: "village_square") },
            applySave: { _ in .applied },
            areaDisplayName: { areaID in areaID == "village_square" ? "裂隙村广场" : areaID }
        )

        let row = try XCTUnwrap(viewModel.rows.first { $0.slot == .manual(1) })

        XCTAssertTrue(row.detail.contains("裂隙村广场"))
        XCTAssertFalse(row.detail.contains("village_square"))
    }

    func testBatchReadDeduplicatesRepeatedSlotsWithoutCrashing() throws {
        let store = makeStore()
        try store.write(makeSave(areaID: "village_square"), to: .manual(1), safety: .safe)

        let results = store.readResults(for: [.manual(1), .manual(1), .manual(2)])

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[.manual(1)]?.save?.currentAreaID, "village_square")
    }

    func testCorruptSlotShowsChineseError() throws {
        let store = makeStore()
        try store.writeRawData(Data("{".utf8), to: .manual(2))
        let viewModel = SaveLoadViewModel(
            store: store,
            makeSave: { self.makeSave(areaID: "village_square") },
            applySave: { _ in .applied }
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
                ),
                Actor(
                    id: "partner",
                    displayName: "同伴",
                    kind: .player,
                    faction: .player,
                    level: 1,
                    stats: Stats(
                        maxHealth: 18,
                        health: 18,
                        attack: 4,
                        defense: 2,
                        evasion: 4,
                        magic: 2,
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
