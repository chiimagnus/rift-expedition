import Foundation
import XCTest
@testable import RiftCore

final class ContentValidatorTests: XCTestCase {
    func testValidFixtureLoadsAndValidates() throws {
        let catalog = try ContentLoader.load(from: fixtureDirectory("valid"))

        try ContentValidator.validate(catalog)

        XCTAssertEqual(catalog.classes.first?.displayName, "战士")
    }

    func testMissingSkillReferenceFailsDuringLoadWithReadableError() throws {
        XCTAssertThrowsError(try ContentLoader.load(from: fixtureDirectory("invalid-missing-skill"))) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("Missing reference"))
            XCTAssertTrue(message.contains("missing_skill"))
        }
    }

    func testDialogsJSONIsTheCatalogAndRuntimeSource() throws {
        let catalog = try ContentLoader.load(from: projectDataDirectory())
        let intro = try XCTUnwrap(catalog.dialogues.first { $0.id == "elder_intro" })

        XCTAssertTrue(intro.options.contains {
            $0.action == .acceptQuest && $0.questID == "blood_debt"
        })
    }

    func testConsumableMustReferenceExistingSkill() {
        let catalog = ContentCatalog(
            classes: [],
            skills: [],
            items: [
                ItemDefinition(
                    id: "minor_healing_draught",
                    displayName: "止血药剂",
                    kind: .consumable,
                    skillID: "missing_heal"
                )
            ],
            quests: [],
            dialogues: []
        )

        XCTAssertThrowsError(try ContentValidator.validate(catalog)) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("item:minor_healing_draught"))
            XCTAssertTrue(message.contains("missing_heal"))
        }
    }

    func testDialogOptionIDsAndPayloadsAreStrictlyValidated() {
        let quest = QuestDefinition(
            id: "blood_debt",
            chapterID: "chapter1",
            title: "血债",
            summary: "测试",
            isMainQuest: false,
            locationHint: "测试地点",
            objectives: ["完成测试目标"],
            startDialogID: "broken_dialog",
            turnInDialogID: "turn_in",
            requiredItemIDs: [],
            rewardItemIDs: [],
            rewardSkillIDs: []
        )
        let dialogue = DialogDefinition(
            id: "broken_dialog",
            speakerName: "测试",
            lines: ["测试"],
            options: [
                DialogOptionDefinition(
                    id: "duplicate",
                    title: "接受",
                    action: .acceptQuest,
                    questID: nil,
                    encounterID: "boar_intro"
                ),
                DialogOptionDefinition(
                    id: "duplicate",
                    title: "",
                    action: .startBattle,
                    questID: "blood_debt",
                    encounterID: nil
                ),
                DialogOptionDefinition(
                    id: "close_with_payload",
                    title: "关闭",
                    action: .close,
                    questID: "blood_debt",
                    encounterID: nil
                )
            ]
        )
        let catalog = ContentCatalog(
            classes: [],
            skills: [],
            items: [],
            quests: [quest],
            dialogues: [dialogue]
        )

        XCTAssertThrowsError(try ContentValidator.validate(catalog)) { error in
            let message = String(describing: error)
            for required in [
                "Duplicate dialogue option in broken_dialog id: duplicate",
                "acceptQuest requires questID",
                "startBattle forbids questID",
                "startBattle requires encounterID",
                "close forbids questID and encounterID",
                "option title must not be blank"
            ] {
                XCTAssertTrue(message.contains(required), required)
            }
        }
    }

    func testQuestDialogOptionMustReferenceExistingQuest() {
        let dialogue = DialogDefinition(
            id: "orphan_dialog",
            speakerName: "测试",
            lines: ["测试"],
            options: [
                DialogOptionDefinition(
                    id: "accept_missing",
                    title: "接受",
                    action: .acceptQuest,
                    questID: "missing_quest"
                )
            ]
        )

        XCTAssertThrowsError(try ContentValidator.validate(
            ContentCatalog(classes: [], skills: [], items: [], quests: [], dialogues: [dialogue])
        )) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("option.questID"))
            XCTAssertTrue(message.contains("missing_quest"))
        }
    }

    func testInvalidSkillSemanticsAreRejected() {
        let invalidSkills = [
            SkillDefinition(
                id: "negative_ap",
                displayName: "负 AP",
                actionPointCost: -1,
                range: 1,
                target: .enemy,
                affectsAllies: false,
                canBeDodged: true,
                effects: [.damage(1)]
            ),
            SkillDefinition(
                id: "negative_range",
                displayName: "负射程",
                actionPointCost: 1,
                range: -1,
                target: .enemy,
                affectsAllies: false,
                canBeDodged: true,
                effects: [.damage(1)]
            ),
            SkillDefinition(
                id: "empty_effects",
                displayName: "空效果",
                actionPointCost: 1,
                range: 1,
                target: .enemy,
                affectsAllies: false,
                canBeDodged: true,
                effects: []
            ),
            SkillDefinition(
                id: "unknown_status",
                displayName: "未知状态",
                actionPointCost: 1,
                range: 1,
                target: .enemy,
                affectsAllies: false,
                canBeDodged: false,
                effects: [.applyStatus(statusID: "frozen", durationTurns: 0)]
            ),
            SkillDefinition(
                id: "unknown_surface",
                displayName: "未知地表",
                actionPointCost: 1,
                range: 1,
                target: .enemy,
                affectsAllies: false,
                canBeDodged: false,
                effects: [.createSurface(surfaceID: "lava", durationTurns: -1)]
            )
        ]
        let catalog = ContentCatalog(classes: [], skills: invalidSkills, items: [], quests: [], dialogues: [])

        XCTAssertThrowsError(try ContentValidator.validate(catalog)) { error in
            let message = String(describing: error)
            for required in [
                "actionPointCost must be positive",
                "range must be finite and non-negative",
                "effects must not be empty",
                "unknown statusID: frozen",
                "status duration must be positive",
                "unknown surfaceID: lava",
                "surface duration must be positive"
            ] {
                XCTAssertTrue(message.contains(required), required)
            }
        }
    }

    func testNonPositiveDamageAndHealingAreRejected() {
        let skills = [
            SkillDefinition(
                id: "zero_damage",
                displayName: "零伤害",
                actionPointCost: 1,
                range: 1,
                target: .enemy,
                affectsAllies: false,
                canBeDodged: false,
                effects: [.damage(0)]
            ),
            SkillDefinition(
                id: "negative_heal",
                displayName: "负治疗",
                actionPointCost: 1,
                range: 1,
                target: .ally,
                affectsAllies: true,
                canBeDodged: false,
                effects: [.heal(-1)]
            )
        ]

        XCTAssertThrowsError(try ContentValidator.validate(
            ContentCatalog(classes: [], skills: skills, items: [], quests: [], dialogues: [])
        )) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("damage amount must be positive"))
            XCTAssertTrue(message.contains("heal amount must be positive"))
        }
    }

    func testQuestRequiredItemsMustReferenceExistingItems() {
        let quest = QuestDefinition(
            id: "missing_turn_in_item",
            chapterID: "chapter1",
            title: "缺失交付物",
            summary: "测试",
            isMainQuest: false,
            locationHint: "测试地点",
            objectives: ["完成测试目标"],
            startDialogID: "start",
            turnInDialogID: "turn_in",
            requiredItemIDs: ["missing_ledger"],
            rewardItemIDs: [],
            rewardSkillIDs: []
        )
        let catalog = ContentCatalog(
            classes: [],
            skills: [],
            items: [],
            quests: [quest],
            dialogues: [
                DialogDefinition(id: "start", speakerName: "测试", lines: ["开始"], options: []),
                DialogDefinition(id: "turn_in", speakerName: "测试", lines: ["交付"], options: [])
            ]
        )

        XCTAssertThrowsError(try ContentValidator.validate(catalog)) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("quest:missing_turn_in_item"))
            XCTAssertTrue(message.contains("requiredItemIDs"))
            XCTAssertTrue(message.contains("missing_ledger"))
        }
    }

    func testQuestRequiredItemsMustBeUnique() {
        let quest = QuestDefinition(
            id: "duplicate_turn_in",
            chapterID: "chapter1",
            title: "重复交付物",
            summary: "测试",
            isMainQuest: false,
            locationHint: "测试地点",
            objectives: ["完成测试目标"],
            startDialogID: "start",
            turnInDialogID: "turn_in",
            requiredItemIDs: ["ledger", "ledger"],
            rewardItemIDs: [],
            rewardSkillIDs: []
        )
        let catalog = ContentCatalog(
            classes: [],
            skills: [],
            items: [ItemDefinition(id: "ledger", displayName: "账册", kind: .quest)],
            quests: [quest],
            dialogues: [
                DialogDefinition(id: "start", speakerName: "测试", lines: ["开始"], options: []),
                DialogDefinition(id: "turn_in", speakerName: "测试", lines: ["交付"], options: [])
            ]
        )

        XCTAssertThrowsError(try ContentValidator.validate(catalog)) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("duplicate_turn_in"))
            XCTAssertTrue(message.contains("requiredItemIDs must not contain duplicates"))
        }
    }

    func testChapterOneClassesHaveThreeValidInitialSkillsAndEquipment() throws {
        let catalog = try ContentLoader.load(from: projectDataDirectory())

        try ContentValidator.validate(catalog)

        let expectedClassIDs = Set(["warrior", "archer", "mage", "rogue"])
        XCTAssertEqual(Set(catalog.classes.map(\.id)), expectedClassIDs)

        let skillsByID = Dictionary(uniqueKeysWithValues: catalog.skills.map { ($0.id, $0) })
        let itemsByID = Dictionary(uniqueKeysWithValues: catalog.items.map { ($0.id, $0) })

        for classDefinition in catalog.classes {
            XCTAssertEqual(classDefinition.initialSkillIDs.count, 3, classDefinition.id)
            XCTAssertEqual(Set(classDefinition.initialSkillIDs).count, 3, classDefinition.id)

            for skillID in classDefinition.initialSkillIDs {
                let skill = try XCTUnwrap(skillsByID[skillID], skillID)
                XCTAssertGreaterThan(skill.actionPointCost, 0, skillID)
                XCTAssertLessThanOrEqual(skill.actionPointCost, 4, skillID)
                XCTAssertGreaterThanOrEqual(skill.range, 0, skillID)
                XCTAssertFalse(skill.displayName.isEmpty, skillID)
            }

            try assertEquipment(classDefinition.defaultEquipment.weaponID, slot: .weapon, itemsByID: itemsByID)
            try assertEquipment(classDefinition.defaultEquipment.armorID, slot: .armor, itemsByID: itemsByID)
            try assertEquipment(classDefinition.defaultEquipment.accessoryID, slot: .accessory, itemsByID: itemsByID)
        }
    }

    func testStartingBalanceDocumentCoversClassAndAPValues() throws {
        let balanceURL = projectRoot().appending(path: "Docs/balance-starting-values.md")
        let text = try String(contentsOf: balanceURL, encoding: .utf8)

        for requiredText in ["战士", "弓箭手", "法师", "刺客", "AP", "调参方向"] {
            XCTAssertTrue(text.contains(requiredText), requiredText)
        }
    }

    private func fixtureDirectory(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.resourceURL?.appending(path: "Fixtures/\(name)"))
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

    private func assertEquipment(
        _ itemID: String?,
        slot: EquipmentSlot,
        itemsByID: [String: ItemDefinition],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let itemID = try XCTUnwrap(itemID, "missing \(slot) item", file: file, line: line)
        let item = try XCTUnwrap(itemsByID[itemID], itemID, file: file, line: line)
        XCTAssertEqual(item.kind, .equipment, file: file, line: line)
        XCTAssertEqual(item.equipment?.slot, slot, file: file, line: line)
    }
}
