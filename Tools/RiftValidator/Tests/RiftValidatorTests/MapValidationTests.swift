import XCTest
@testable import RiftValidator

final class MapValidationTests: XCTestCase {
    func testValidFixturePasses() throws {
        let result = try MapValidator.validate(url: fixture("valid-map"))

        XCTAssertTrue(result.isValid, result.reportMarkdown())
    }

    func testMissingSpawnLayerFailsWithReadableError() throws {
        let result = try MapValidator.validate(url: fixture("invalid-map-missing-spawn"))

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.reportMarkdown().contains("Missing object layer: spawn"))
    }

    private func fixture(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "tmx", subdirectory: "Fixtures"))
    }
}
