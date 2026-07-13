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


    func testOldSchemaIsRejected() throws {
        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["schemaVersion"] = SaveGame.currentSchemaVersion - 1
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: legacyData)) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .unsupportedSchemaVersion(found: SaveGame.currentSchemaVersion - 1, expected: SaveGame.currentSchemaVersion)
            )
        }
    }

    func testCurrentSchemaRejectsEmptyParty() throws {
        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["party"] = []
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: data)) { error in
            XCTAssertEqual(error as? SaveGameDecodingError, .emptyParty)
        }
    }

    func testCurrentSchemaRejectsNonTwoPersonParty() throws {
        var save = makeSave()
        save.party.removeLast()
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .invalidPartySize(found: 1, expected: 2)
            )
        }

        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let party = try XCTUnwrap(object["party"] as? [[String: Any]])
        object["party"] = party + [party[0]]
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: data)) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .invalidPartySize(found: 3, expected: 2)
            )
        }
    }

    func testCurrentSchemaRejectsDuplicateActorIDs() throws {
        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let party = try XCTUnwrap(object["party"] as? [[String: Any]])
        object["party"] = [party[0], party[0]]
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: data)) { error in
            XCTAssertEqual(error as? SaveGameDecodingError, .duplicateActorID("hero"))
        }
    }

    func testCurrentSchemaRejectsEmptyActorID() throws {
        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var party = try XCTUnwrap(object["party"] as? [[String: Any]])
        party[0]["id"] = "  "
        object["party"] = party
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: data)) { error in
            XCTAssertEqual(error as? SaveGameDecodingError, .emptyActorID)
        }
    }

    func testMissingCurrentSchemaFieldIsRejected() throws {
        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "resolvedEncounterKeys")
        let incompleteData = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: incompleteData))
    }

    func testCurrentSchemaRejectsBlankAreaAndSpawnIDs() throws {
        for (field, expectedError) in [
            ("currentAreaID", SaveGameDecodingError.emptyAreaID),
            ("currentSpawnID", SaveGameDecodingError.emptySpawnID)
        ] {
            let encoded = try JSONEncoder().encode(makeSave())
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            object[field] = "  "
            let data = try JSONSerialization.data(withJSONObject: object)

            XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: data)) { error in
                XCTAssertEqual(error as? SaveGameDecodingError, expectedError)
            }
        }
    }

    func testCurrentSchemaRejectsInvalidActorProgression() throws {
        var save = makeSave()
        save.party[0].level = 0
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .invalidActorProgression(actorID: "hero", field: "level", value: 0)
            )
        }

        save = makeSave()
        save.party[0].experience = -1
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .invalidActorProgression(actorID: "hero", field: "experience", value: -1)
            )
        }
    }

    func testCurrentSchemaRejectsInvalidStatsAndResourceBounds() throws {
        var save = makeSave()
        save.party[0].stats.maxHealth = 0
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .invalidActorStat(actorID: "hero", field: "maxHealth", value: 0)
            )
        }

        save = makeSave()
        save.party[0].stats.health = 21
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .healthOutOfRange(actorID: "hero", health: 21, maxHealth: 20)
            )
        }

        save = makeSave()
        save.party[0].stats.actionPoints = 5
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .actionPointsOutOfRange(actorID: "hero", actionPoints: 5, maxActionPoints: 4)
            )
        }
    }

    func testCurrentSchemaRejectsInvalidAndDuplicateStatuses() throws {
        var save = makeSave()
        save.party[0].statuses = [StatusEffect(type: .burning, remainingTurns: 0)]
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .invalidStatusDuration(actorID: "hero", status: .burning, remainingTurns: 0)
            )
        }

        save = makeSave()
        save.party[0].statuses = [
            StatusEffect(type: .wet, remainingTurns: 1),
            StatusEffect(type: .wet, remainingTurns: 2)
        ]
        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .duplicateStatus(actorID: "hero", status: .wet)
            )
        }
    }

    func testCurrentSchemaRejectsMalformedMapStateKeys() throws {
        let fields = ["collectedMapItemKeys", "firedMapTriggerKeys", "resolvedEncounterKeys"]
        for field in fields {
            let encoded = try JSONEncoder().encode(makeSave())
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            object[field] = ["missing-tiled-id"]
            let data = try JSONSerialization.data(withJSONObject: object)

            XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: data)) { error in
                XCTAssertEqual(
                    error as? SaveGameDecodingError,
                    .invalidMapStateKey(field: field, key: "missing-tiled-id")
                )
            }
        }
    }

    func testCurrentSchemaRejectsDuplicateMapStateKeys() throws {
        let encoded = try JSONEncoder().encode(makeSave())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["resolvedEncounterKeys"] = ["wilds_road:41", "wilds_road:41"]
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(SaveGame.self, from: data)) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .duplicateMapStateKey(field: "resolvedEncounterKeys", key: "wilds_road:41")
            )
        }
    }

    func testValidationRejectsInvalidInMemorySaveBeforeWriting() throws {
        var save = makeSave()
        save.collectedMapItemKeys = ["village_square:0"]

        XCTAssertThrowsError(try save.validate()) { error in
            XCTAssertEqual(
                error as? SaveGameDecodingError,
                .invalidMapStateKey(field: "collectedMapItemKeys", key: "village_square:0")
            )
        }
    }

    func testAutosaveRotationUsesEmptySlotsBeforeOldestSlot() {
        let now = Date()
        XCTAssertEqual(SaveSlotPolicy.nextAutosaveSlot(existingModifiedAt: [:]), .auto(1))
        XCTAssertEqual(
            SaveSlotPolicy.nextAutosaveSlot(existingModifiedAt: [.auto(1): now]),
            .auto(2)
        )

        let fullSlots = Dictionary(uniqueKeysWithValues: SaveSlotPolicy.autoSlots.map { slot in
            (slot, now.addingTimeInterval(Double(slot.index)))
        })
        XCTAssertEqual(SaveSlotPolicy.nextAutosaveSlot(existingModifiedAt: fullSlots), .auto(1))
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

final class PartyInventoryValidationTests: XCTestCase {
    func testValidInventoryRoundTrips() throws {
        let inventory = try PartyInventory(itemCounts: ["minor_healing_draught": 2])
        let data = try JSONEncoder().encode(inventory)
        XCTAssertEqual(try JSONDecoder().decode(PartyInventory.self, from: data), inventory)
    }

    func testInitializerRejectsEmptyItemIDAndNonPositiveQuantity() {
        XCTAssertThrowsError(try PartyInventory(itemCounts: [" ": 1])) { error in
            XCTAssertEqual(error as? PartyInventoryValidationError, .emptyItemID)
        }
        XCTAssertThrowsError(try PartyInventory(itemCounts: ["potion": 0])) { error in
            XCTAssertEqual(
                error as? PartyInventoryValidationError,
                .nonPositiveQuantity(itemID: "potion", quantity: 0)
            )
        }
    }

    func testDecoderRejectsInvalidCounts() throws {
        for (json, expected) in [
            (#"{"itemCounts":{"":1}}"#, PartyInventoryValidationError.emptyItemID),
            (#"{"itemCounts":{"potion":-1}}"#, .nonPositiveQuantity(itemID: "potion", quantity: -1))
        ] {
            XCTAssertThrowsError(try JSONDecoder().decode(PartyInventory.self, from: Data(json.utf8))) { error in
                XCTAssertEqual(error as? PartyInventoryValidationError, expected)
            }
        }
    }
}

final class SaveContentValidatorTests: XCTestCase {
    func testValidSaveContentPasses() throws {
        try SaveContentValidator.validate(makeContentSave(), against: makeCatalog())
    }

    func testUnknownInventoryItemIsRejected() throws {
        var save = makeContentSave()
        save.inventory.addItem(id: "removed_item")

        XCTAssertThrowsError(try SaveContentValidator.validate(save, against: makeCatalog())) { error in
            XCTAssertEqual(error as? SaveContentValidationError, .unknownInventoryItem("removed_item"))
        }
    }

    func testUnknownQuestAndActorReferencesAreRejected() throws {
        var save = makeContentSave()
        save.questState.statuses["removed_quest"] = .active
        XCTAssertThrowsError(try SaveContentValidator.validate(save, against: makeCatalog())) { error in
            XCTAssertEqual(error as? SaveContentValidationError, .unknownQuest("removed_quest"))
        }

        save = makeContentSave()
        save.party[0].skillIDs = ["removed_skill"]
        XCTAssertThrowsError(try SaveContentValidator.validate(save, against: makeCatalog())) { error in
            XCTAssertEqual(
                error as? SaveContentValidationError,
                .unknownSkill(actorID: "hero", skillID: "removed_skill")
            )
        }
    }

    func testWrongEquipmentSlotAndMissingInventoryEquipmentAreRejected() throws {
        var save = makeContentSave()
        save.party[0].equipment.weaponID = "cloth_armor"
        XCTAssertThrowsError(try SaveContentValidator.validate(save, against: makeCatalog())) { error in
            XCTAssertEqual(
                error as? SaveContentValidationError,
                .invalidEquipmentSlot(actorID: "hero", itemID: "cloth_armor", expected: .weapon, actual: .armor)
            )
        }

        save = makeContentSave()
        save.party[0].equipment.weaponID = "training_sword"
        try save.inventory.removeItem(id: "training_sword")
        XCTAssertThrowsError(try SaveContentValidator.validate(save, against: makeCatalog())) { error in
            XCTAssertEqual(
                error as? SaveContentValidationError,
                .equippedItemMissingFromInventory(actorID: "hero", itemID: "training_sword")
            )
        }
    }

    private func makeContentSave() -> SaveGame {
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
                    classID: "warrior",
                    skillIDs: ["slash"],
                    equipment: EquipmentLoadout(weaponID: "training_sword", armorID: "cloth_armor")
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
                    classID: "warrior",
                    skillIDs: ["slash"]
                )
            ],
            inventory: try! PartyInventory(itemCounts: ["training_sword": 1, "cloth_armor": 1]),
            questState: QuestState(statuses: ["quest": .active])
        )
    }

    private func makeCatalog() -> ContentCatalog {
        let stats = Stats(
            maxHealth: 20,
            health: 20,
            attack: 5,
            defense: 2,
            evasion: 3,
            magic: 1,
            maxActionPoints: 4,
            actionPoints: 4
        )
        return ContentCatalog(
            classes: [
                ClassDefinition(
                    id: "warrior",
                    displayName: "战士",
                    initialStats: stats,
                    initialSkillIDs: ["slash"],
                    defaultEquipment: EquipmentLoadout(weaponID: "training_sword", armorID: "cloth_armor")
                )
            ],
            skills: [
                SkillDefinition(
                    id: "slash",
                    displayName: "劈砍",
                    actionPointCost: 2,
                    range: 1.5,
                    target: .enemy,
                    affectsAllies: false,
                    canBeDodged: true,
                    effects: [.damage(5)]
                )
            ],
            items: [
                ItemDefinition(
                    id: "training_sword",
                    displayName: "训练剑",
                    kind: .equipment,
                    equipment: EquipmentDefinition(id: "training_sword", displayName: "训练剑", slot: .weapon)
                ),
                ItemDefinition(
                    id: "cloth_armor",
                    displayName: "布甲",
                    kind: .equipment,
                    equipment: EquipmentDefinition(id: "cloth_armor", displayName: "布甲", slot: .armor)
                )
            ],
            quests: [
                QuestDefinition(
                    id: "quest",
                    chapterID: "chapter1",
                    title: "任务",
                    summary: "任务",
                    startDialogID: "dialog",
                    requiredItemIDs: []
                )
            ],
            dialogues: [
                DialogDefinition(id: "dialog", speakerName: "NPC", lines: ["内容"], options: [])
            ]
        )
    }
}
