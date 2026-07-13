import CoreGraphics
import XCTest
@testable import RiftExpedition

@MainActor
final class NavigationServiceTests: XCTestCase {
    func testChapterMapMetadataReadsNavigationObstacles() throws {
        let metadata = try TiledMapLoader.loadMetadata(url: villageOutskirtsURL(), areaID: "village_outskirts")

        XCTAssertEqual(metadata.areaID, "village_outskirts")
        XCTAssertEqual(metadata.navObstacles.count, 6)
        XCTAssertTrue(metadata.navObstacles.contains { $0.tiledID == 7 && $0.blocksMovement && $0.blocksSight })
    }

    func testAllChapterOneMapsLoadWithStrictMetadata() throws {
        let mapDirectory = villageOutskirtsURL().deletingLastPathComponent()
        let areaIDs = [
            "village_square", "village_riverside", "village_outskirts",
            "wilds_road", "wilds_ruins", "wilds_riverbank",
            "cave_entrance", "cave_mines", "cave_depths"
        ]

        for areaID in areaIDs {
            let metadata = try TiledMapLoader.loadMetadata(
                url: mapDirectory.appending(path: "\(areaID).tmx"),
                areaID: areaID
            )
            XCTAssertEqual(metadata.areaID, areaID)
            XCTAssertFalse(metadata.spawns.isEmpty)
        }
    }

    func testMetadataRejectsMissingEncounterID() throws {
        let url = try mutatedMapURL(
            replacing: "name=\"encounterId\"",
            with: "name=\"missingEncounterId\""
        )

        XCTAssertThrowsError(try TiledMapLoader.loadMetadata(url: url, areaID: "village_outskirts")) { error in
            XCTAssertEqual(
                error as? TiledMapLoaderError,
                .missingObjectProperty(
                    areaID: "village_outskirts",
                    group: "encounter",
                    tiledID: 11,
                    property: "encounterId"
                )
            )
        }
    }

    func testMetadataRejectsInvalidObstacleBoolean() throws {
        let url = try mutatedMapURL(
            replacing: "<property name=\"blocksMovement\" value=\"true\" />",
            with: "<property name=\"blocksMovement\" value=\"yes\" />"
        )

        XCTAssertThrowsError(try TiledMapLoader.loadMetadata(url: url, areaID: "village_outskirts")) { error in
            XCTAssertEqual(
                error as? TiledMapLoaderError,
                .invalidBooleanProperty(
                    areaID: "village_outskirts",
                    group: "navObstacle",
                    tiledID: 5,
                    property: "blocksMovement",
                    value: "yes"
                )
            )
        }
    }

    func testMetadataRejectsInvalidEncounterRadius() throws {
        let url = try mutatedMapURL(
            replacing: "<property name=\"radius\" value=\"96\" />",
            with: "<property name=\"radius\" value=\"not-a-number\" />"
        )

        XCTAssertThrowsError(try TiledMapLoader.loadMetadata(url: url, areaID: "village_outskirts")) { error in
            XCTAssertEqual(
                error as? TiledMapLoaderError,
                .invalidNumberProperty(
                    areaID: "village_outskirts",
                    group: "encounter",
                    tiledID: 11,
                    property: "radius",
                    value: "not-a-number"
                )
            )
        }
    }

    func testPathAvoidsMovementObstacle() {
        let obstacle = NavigationObstacle(
            tiledID: 1,
            frame: CGRect(x: 50, y: -20, width: 40, height: 80),
            blocksMovement: true,
            blocksSight: true
        )
        let service = NavigationService(obstacles: [obstacle], agentRadius: 4)

        let path = service.path(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 130, y: 0))

        XCTAssertGreaterThan(path.count, 2)
        for (start, end) in zip(path, path.dropFirst()) {
            XCTAssertFalse(obstacle.frame.intersectsSegment(from: start, to: end))
        }
    }

    func testLineOfSightIsBlockedBySightObstacle() {
        let obstacle = NavigationObstacle(
            tiledID: 1,
            frame: CGRect(x: 50, y: -20, width: 40, height: 80),
            blocksMovement: true,
            blocksSight: true
        )
        let service = LineOfSightService(obstacles: [obstacle])

        XCTAssertFalse(service.hasLineOfSight(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 130, y: 0)))
        XCTAssertTrue(service.hasLineOfSight(from: CGPoint(x: 0, y: 90), to: CGPoint(x: 130, y: 90)))
    }

    private func mutatedMapURL(replacing target: String, with replacement: String) throws -> URL {
        let sourceURL = villageOutskirtsURL()
        let original = try String(contentsOf: sourceURL, encoding: .utf8)
        guard original.contains(target) else {
            XCTFail("Fixture does not contain mutation target: \(target)")
            return sourceURL
        }
        let url = sourceURL.deletingLastPathComponent().appending(path: ".audit-\(UUID().uuidString).tmx")
        guard let range = original.range(of: target) else {
            XCTFail("Fixture mutation range disappeared")
            return sourceURL
        }
        var mutated = original
        mutated.replaceSubrange(range, with: replacement)
        try mutated.write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func villageOutskirtsURL() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "RiftExpedition/Resources/Maps/chapter1/village_outskirts.tmx")
    }
}
