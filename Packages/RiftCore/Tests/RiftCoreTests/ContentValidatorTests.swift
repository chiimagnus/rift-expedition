import Foundation
import XCTest
@testable import RiftCore

final class ContentValidatorTests: XCTestCase {
    func testValidFixtureLoadsAndValidates() throws {
        let catalog = try ContentLoader.load(from: fixtureDirectory("valid"))

        try ContentValidator.validate(catalog)

        XCTAssertEqual(catalog.classes.first?.displayName, "战士")
    }

    func testMissingSkillReferenceFailsWithReadableError() throws {
        let catalog = try ContentLoader.load(from: fixtureDirectory("invalid-missing-skill"))

        XCTAssertThrowsError(try ContentValidator.validate(catalog)) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("Missing reference"))
            XCTAssertTrue(message.contains("missing_skill"))
        }
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
