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

    private func fixtureDirectory(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.resourceURL?.appending(path: "Fixtures/\(name)"))
    }
}
