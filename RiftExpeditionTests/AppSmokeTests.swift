import XCTest
import SpriteKit
@testable import RiftExpedition

@MainActor
final class AppSmokeTests: XCTestCase {
    func testRootViewAndSceneCanBeCreated() {
        _ = ContentView()

        let scene = GameScene.makeScene()
        XCTAssertEqual(scene.size, GameScene.sceneSize)
    }

    func testSceneCentersLoadedMapInWorldLayer() throws {
        let scene = GameScene(size: CGSize(width: 1600, height: 900))
        scene.scaleMode = .resizeFill
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))

        scene.loadMap(areaID: "village_square")

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        XCTAssertFalse(worldLayer.children.isEmpty)
        XCTAssertGreaterThan(worldLayer.xScale, 0)
        XCTAssertEqual(worldLayer.xScale, worldLayer.yScale)
        XCTAssertGreaterThanOrEqual(worldLayer.position.x, -0.5)
        XCTAssertGreaterThanOrEqual(worldLayer.position.y, -0.5)
    }
}
