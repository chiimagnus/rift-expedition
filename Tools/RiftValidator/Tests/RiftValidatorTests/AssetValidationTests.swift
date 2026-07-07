import XCTest
@testable import RiftValidator

final class AssetValidationTests: XCTestCase {
    func testCC0FixturePasses() throws {
        let result = try AssetValidator.validate(resourcesRoot: fixtureRoot("assets-valid"))

        XCTAssertTrue(result.isValid, "\(result.issues)")
    }

    func testBadLicensesAndFormalPlaceholderFail() throws {
        let result = try AssetValidator.validate(resourcesRoot: fixtureRoot("assets-invalid"))
        let report = result.issues.map(\.message).joined(separator: "\n")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(report.contains("GPL"))
        XCTAssertTrue(report.contains("CC-BY-SA"))
        XCTAssertTrue(report.contains("unknown"))
        XCTAssertTrue(report.contains("placeholder"))
    }

    func testAnimationFixturePasses() throws {
        let result = try AssetValidator.validate(resourcesRoot: fixtureRoot("animation-valid"))

        XCTAssertTrue(result.isValid, "\(result.issues)")
    }

    func testAnimationInvalidSizeFailsWithReadableIssue() throws {
        let result = try AssetValidator.validate(resourcesRoot: fixtureRoot("animation-invalid-size"))
        let report = result.issues.map(\.message).joined(separator: "\n")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(report.contains("test_actor"), report)
        XCTAssertTrue(report.contains("Assets/Characters/test_actor_anim.png"), report)
        XCTAssertTrue(report.contains("1152x384"), report)
        XCTAssertTrue(report.contains("96x96"), report)
    }

    func testAnimationInvalidSheetPathFailsWithReadableIssue() throws {
        let root = try copiedFixtureRoot("animation-valid")
        try writeAnimationConfig(at: root) { json in
            var sprites = json["sprites"] as? [[String: Any]] ?? []
            sprites[0]["sheet"] = "Assets/Sprites/test_actor.png"
            json["sprites"] = sprites
        }

        let result = try AssetValidator.validate(resourcesRoot: root)
        let report = result.issues.map(\.message).joined(separator: "\n")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(report.contains("test_actor"), report)
        XCTAssertTrue(report.contains("Assets/Characters/test_actor_anim.png"), report)
        XCTAssertTrue(report.contains("Assets/Sprites/test_actor.png"), report)
    }

    func testAnimationExtraActionFails() throws {
        let root = try copiedFixtureRoot("animation-valid")
        try writeAnimationConfig(at: root) { json in
            var actions = json["actions"] as? [String: Any] ?? [:]
            actions["cast"] = [
                "startColumn": 9,
                "frameCount": 3
            ]
            json["actions"] = actions
        }

        let result = try AssetValidator.validate(resourcesRoot: root)
        let report = result.issues.map(\.message).joined(separator: "\n")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(report.contains("actions"), report)
        XCTAssertTrue(report.contains("cast"), report)
    }

    func testAnimationDuplicateVisualIDFails() throws {
        let root = try copiedFixtureRoot("animation-valid")
        try writeAnimationConfig(at: root) { json in
            var sprites = json["sprites"] as? [[String: Any]] ?? []
            sprites.append(sprites[0])
            json["sprites"] = sprites
        }

        let result = try AssetValidator.validate(resourcesRoot: root)
        let report = result.issues.map(\.message).joined(separator: "\n")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(report.contains("Duplicate actor animation visualID"), report)
        XCTAssertTrue(report.contains("test_actor"), report)
    }

    private func fixtureRoot(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.resourceURL?.appending(path: "Fixtures/\(name)"))
    }

    private func copiedFixtureRoot(_ name: String) throws -> URL {
        let source = try fixtureRoot(name)
        let destination = FileManager.default.temporaryDirectory
            .appending(path: "RiftValidatorTests-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func writeAnimationConfig(at root: URL, mutate: (inout [String: Any]) -> Void) throws {
        let url = root.appending(path: "Assets/actor-animations.json")
        let data = try Data(contentsOf: url)
        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Could not read fixture JSON")
            return
        }
        mutate(&json)
        let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try prettyData.write(to: url)
    }
}
