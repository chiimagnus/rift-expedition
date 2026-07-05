import Foundation
import XCTest
@testable import RiftCore

final class SaveSlotPolicyTests: XCTestCase {
    func testOnlyFiveAutoSlotsAreValid() throws {
        XCTAssertEqual(SaveSlotPolicy.autoSlots, [.auto(1), .auto(2), .auto(3), .auto(4), .auto(5)])

        XCTAssertThrowsError(try SaveSlotPolicy.validate(.auto(6))) { error in
            XCTAssertEqual(error as? SaveSlotError, .invalidAutoSlot(6))
        }
    }

    func testUnsafeAutosaveIsRejected() {
        XCTAssertThrowsError(try SaveSlotPolicy.prepareWrite(to: .auto(1), safety: .unsafe)) { error in
            XCTAssertEqual(error as? SaveSlotError, .unsafeAutosave)
        }
    }

    func testCorruptSlotDoesNotAffectOtherSlots() throws {
        let validData = try JSONEncoder().encode(makeSave())
        let corruptData = Data("{".utf8)

        let results = SaveSlotPolicy.readSlots(from: [
            .manual(1): validData,
            .manual(2): corruptData
        ])

        XCTAssertTrue(try XCTUnwrap(results.first { $0.slot == .manual(1) }).isReadable)
        XCTAssertFalse(try XCTUnwrap(results.first { $0.slot == .manual(2) }).isReadable)
    }

    private func makeSave() -> SaveGame {
        SaveGame(
            currentAreaID: "village_square",
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
