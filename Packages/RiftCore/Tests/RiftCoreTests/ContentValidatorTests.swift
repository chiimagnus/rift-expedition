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
            encounters: [],
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
            encounters: [],
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
            ContentCatalog(classes: [], skills: [], items: [], encounters: [], quests: [], dialogues: [dialogue])
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
        let catalog = ContentCatalog(classes: [], skills: invalidSkills, items: [], encounters: [], quests: [], dialogues: [])

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
            ContentCatalog(classes: [], skills: skills, items: [], encounters: [], quests: [], dialogues: [])
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
            encounters: [],
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
            encounters: [],
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

    func testBlankTopLevelContentFieldsAreRejected() {
        let stats = Stats(
            maxHealth: 10,
            health: 10,
            attack: 1,
            defense: 1,
            evasion: 1,
            magic: 1,
            maxActionPoints: 4,
            actionPoints: 4
        )
        let skill = SkillDefinition(
            id: "slash",
            displayName: "斩击",
            actionPointCost: 1,
            range: 1,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: true,
            effects: [.damage(1)]
        )
        let quest = QuestDefinition(
            id: " ",
            chapterID: " ",
            title: " ",
            summary: " ",
            isMainQuest: false,
            locationHint: " ",
            objectives: [" "],
            startDialogID: " ",
            turnInDialogID: " ",
            requiredItemIDs: [],
            rewardItemIDs: [],
            rewardSkillIDs: []
        )
        let catalog = ContentCatalog(
            classes: [
                ClassDefinition(
                    id: " ",
                    displayName: " ",
                    initialStats: stats,
                    initialSkillIDs: ["slash"],
                    defaultEquipment: EquipmentLoadout()
                )
            ],
            skills: [skill],
            items: [ItemDefinition(id: " ", displayName: " ", kind: .quest)],
            encounters: [],
            quests: [quest],
            dialogues: [DialogDefinition(id: " ", speakerName: " ", lines: [" "], options: [])]
        )

        let message = ContentValidator.collectErrors(in: catalog).map(\.description).joined(separator: "\n")
        for expected in [
            "Invalid class", "id must not be blank", "displayName must not be blank",
            "Invalid item", "Invalid quest", "chapterID must not be blank",
            "title must not be blank", "summary must not be blank",
            "locationHint must not be blank", "objectives must not contain blank values",
            "Invalid dialogue", "speakerName must not be blank", "line 0 must not be blank",
            "options must not be empty"
        ] {
            XCTAssertTrue(message.contains(expected), expected)
        }
    }

    func testEquipmentIdentityAndDefaultSlotMustMatch() {
        let stats = Stats(
            maxHealth: 10,
            health: 10,
            attack: 1,
            defense: 1,
            evasion: 1,
            magic: 1,
            maxActionPoints: 4,
            actionPoints: 4
        )
        let skill = SkillDefinition(
            id: "slash",
            displayName: "斩击",
            actionPointCost: 1,
            range: 1,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: true,
            effects: [.damage(1)]
        )
        let item = ItemDefinition(
            id: "training_sword",
            displayName: "训练剑",
            kind: .equipment,
            equipment: EquipmentDefinition(
                id: "mismatched_internal_id",
                displayName: "训练剑",
                slot: .armor
            )
        )
        let catalog = ContentCatalog(
            classes: [
                ClassDefinition(
                    id: "warrior",
                    displayName: "战士",
                    initialStats: stats,
                    initialSkillIDs: ["slash"],
                    defaultEquipment: EquipmentLoadout(weaponID: "training_sword")
                )
            ],
            skills: [skill],
            items: [item],
            encounters: [],
            quests: [],
            dialogues: []
        )

        let message = ContentValidator.collectErrors(in: catalog).map(\.description).joined(separator: "\n")
        XCTAssertTrue(message.contains("equipment id must match item id"))
        XCTAssertTrue(message.contains("defaultEquipment.weaponID expected weapon, got armor"))
    }

    func testDuplicateSkillsObjectivesAndRewardsAreRejected() {
        let stats = Stats(
            maxHealth: 10,
            health: 10,
            attack: 1,
            defense: 1,
            evasion: 1,
            magic: 1,
            maxActionPoints: 4,
            actionPoints: 4
        )
        let skill = SkillDefinition(
            id: "slash",
            displayName: "斩击",
            actionPointCost: 1,
            range: 1,
            target: .enemy,
            affectsAllies: false,
            canBeDodged: true,
            effects: [.damage(1)]
        )
        let quest = QuestDefinition(
            id: "duplicates",
            chapterID: "chapter1",
            title: "重复任务",
            summary: "测试重复列表",
            isMainQuest: false,
            locationHint: "测试地点",
            objectives: ["同一目标", "同一目标"],
            startDialogID: "start",
            turnInDialogID: "turn_in",
            requiredItemIDs: [],
            rewardItemIDs: ["reward", "reward"],
            rewardSkillIDs: ["slash", "slash"]
        )
        let close = DialogOptionDefinition(id: "close", title: "关闭", action: .close)
        let catalog = ContentCatalog(
            classes: [
                ClassDefinition(
                    id: "warrior",
                    displayName: "战士",
                    initialStats: stats,
                    initialSkillIDs: ["slash", "slash"],
                    defaultEquipment: EquipmentLoadout()
                )
            ],
            skills: [skill],
            items: [ItemDefinition(id: "reward", displayName: "奖励", kind: .quest)],
            encounters: [],
            quests: [quest],
            dialogues: [
                DialogDefinition(id: "start", speakerName: "NPC", lines: ["开始"], options: [close]),
                DialogDefinition(id: "turn_in", speakerName: "NPC", lines: ["完成"], options: [close])
            ]
        )

        let message = ContentValidator.collectErrors(in: catalog).map(\.description).joined(separator: "\n")
        XCTAssertTrue(message.contains("initialSkillIDs must not contain duplicates"))
        XCTAssertTrue(message.contains("objectives must not contain duplicates"))
        XCTAssertTrue(message.contains("rewardItemIDs must not contain duplicates"))
        XCTAssertTrue(message.contains("rewardSkillIDs must not contain duplicates"))
    }

    func testItemKindsRejectForeignPayloads() {
        let skill = SkillDefinition(
            id: "heal",
            displayName: "治疗",
            actionPointCost: 1,
            range: 1,
            target: .ally,
            affectsAllies: true,
            canBeDodged: false,
            effects: [.heal(1)]
        )
        let equipmentPayload = EquipmentDefinition(id: "payload", displayName: "载荷", slot: .weapon)
        let catalog = ContentCatalog(
            classes: [],
            skills: [skill],
            items: [
                ItemDefinition(id: "bad_equipment", displayName: "错误装备", kind: .equipment, equipment: equipmentPayload, skillID: "heal"),
                ItemDefinition(id: "bad_consumable", displayName: "错误消耗品", kind: .consumable, equipment: equipmentPayload, skillID: "heal"),
                ItemDefinition(id: "bad_quest", displayName: "错误任务物", kind: .quest, equipment: equipmentPayload, skillID: "heal")
            ],
            encounters: [],
            quests: [],
            dialogues: []
        )

        let message = ContentValidator.collectErrors(in: catalog).map(\.description).joined(separator: "\n")
        XCTAssertTrue(message.contains("equipment item forbids skillID"))
        XCTAssertTrue(message.contains("consumable item forbids equipment definition"))
        XCTAssertTrue(message.contains("quest item forbids equipment and skillID"))
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

    func testEncounterJSONIsLoadedIntoTheCatalog() throws {
        let catalog = try ContentLoader.load(from: projectDataDirectory())

        XCTAssertEqual(catalog.encounters.first?.id, "boar_intro")
        XCTAssertEqual(catalog.encounters.first?.enemies.first?.displayName, "受惊野猪")
    }

    func testEncounterSemanticsAndReferencesAreStrictlyValidated() throws {
        var catalog = try ContentLoader.load(from: projectDataDirectory())
        var invalid = try XCTUnwrap(catalog.encounters.first)
        invalid.id = "invalid_encounter"
        invalid.displayName = ""
        var enemy = try XCTUnwrap(invalid.enemies.first)
        enemy.id = ""
        enemy.displayName = ""
        enemy.kind = .player
        enemy.faction = .player
        enemy.level = 0
        enemy.experience = -1
        enemy.stats.health = 0
        enemy.stats.actionPoints = enemy.stats.maxActionPoints + 1
        enemy.classID = "missing_class"
        enemy.skillIDs = ["missing_skill", "missing_skill"]
        enemy.statuses = [
            StatusEffect(type: .burning, remainingTurns: 0),
            StatusEffect(type: .burning, remainingTurns: 1)
        ]
        invalid.enemies = [enemy, enemy]
        catalog.encounters = [invalid]

        let message = ContentValidator.collectErrors(in: catalog).map(\.description).joined(separator: "\n")
        for required in [
            "displayName must not be blank",
            "enemy ids must not contain duplicates",
            "enemy faction must be hostile, animal, or monster",
            "enemy kind must be humanEnemy, animal, or monster",
            "level must be positive",
            "progression values must be non-negative",
            "health must be within 1...maxHealth",
            "actionPoints must be within 0...maxActionPoints",
            "missing_class",
            "missing_skill",
            "skillIDs must not contain duplicates",
            "statuses must not contain duplicates",
            "status durations must be positive"
        ] {
            XCTAssertTrue(message.contains(required), required)
        }
    }

    func testStartBattleDialogMustReferenceExistingEncounter() throws {
        var catalog = try ContentLoader.load(from: projectDataDirectory())
        catalog.dialogues.append(
            DialogDefinition(
                id: "missing_encounter_dialog",
                speakerName: "测试",
                lines: ["开战"],
                options: [
                    DialogOptionDefinition(
                        id: "fight",
                        title: "战斗",
                        action: .startBattle,
                        encounterID: "missing_encounter"
                    )
                ]
            )
        )

        let message = ContentValidator.collectErrors(in: catalog).map(\.description).joined(separator: "\n")
        XCTAssertTrue(message.contains("option.encounterID"))
        XCTAssertTrue(message.contains("missing_encounter"))
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
