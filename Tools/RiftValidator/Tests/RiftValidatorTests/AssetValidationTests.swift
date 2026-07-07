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

    private func fixtureRoot(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.resourceURL?.appending(path: "Fixtures/\(name)"))
    }
}
