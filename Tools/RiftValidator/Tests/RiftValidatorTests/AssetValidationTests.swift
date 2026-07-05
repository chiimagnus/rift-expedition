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

    private func fixtureRoot(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.resourceURL?.appending(path: "Fixtures/\(name)"))
    }
}
