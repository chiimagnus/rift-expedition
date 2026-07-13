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


    func testSchemaTwoSaveDecodesWithNoResolvedEncounters() throws {
        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["schemaVersion"] = 2
        object.removeValue(forKey: "resolvedEncounterKeys")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(SaveGame.self, from: legacyData)

        XCTAssertEqual(decoded.schemaVersion, 2)
        XCTAssertEqual(decoded.resolvedEncounterKeys, [])
    }

    func testResolvedEncounterKeysRoundTripInCurrentSchema() throws {
        var save = makeSave()
        save.resolvedEncounterKeys = ["wilds_road:41", "cave_depths:77"]

        let encoded = try JSONEncoder().encode(save)
        let decoded = try JSONDecoder().decode(SaveGame.self, from: encoded)

        XCTAssertEqual(decoded.schemaVersion, SaveGame.currentSchemaVersion)
        XCTAssertEqual(decoded.resolvedEncounterKeys, save.resolvedEncounterKeys)
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
