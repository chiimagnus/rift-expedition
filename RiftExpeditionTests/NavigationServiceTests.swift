import CoreGraphics
import XCTest
@testable import RiftExpedition

@MainActor
final class NavigationServiceTests: XCTestCase {
    func testVerticalSliceMetadataReadsNavigationObstacles() throws {
        let metadata = try TiledMapLoader.loadMetadata(url: verticalSliceURL(), areaID: "vertical_slice")

        XCTAssertEqual(metadata.areaID, "vertical_slice")
        XCTAssertEqual(metadata.navObstacles.count, 3)
        XCTAssertTrue(metadata.navObstacles.contains { $0.tiledID == 7 && $0.blocksMovement && $0.blocksSight })
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

    private func verticalSliceURL() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "RiftExpedition/Resources/Maps/vertical_slice.tmx")
    }
}
