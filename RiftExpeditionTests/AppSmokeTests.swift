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
        let tilemap = try XCTUnwrap(worldLayer.childNode(withName: "village_square"))
        XCTAssertFalse(worldLayer.children.isEmpty)
        XCTAssertGreaterThan(worldLayer.xScale, 0)
        XCTAssertEqual(worldLayer.xScale, worldLayer.yScale)

        // Regression guard for the map/object misalignment bug: the rendered map's own visual
        // center must land at the scene's visual center, regardless of where SKTiled anchors the
        // tilemap's internal (0,0) origin. This is independent of `GameScene`'s own centering math.
        let mapFrame = tilemap.calculateAccumulatedFrame()
        let mapCenterInScene = worldLayer.convert(CGPoint(x: mapFrame.midX, y: mapFrame.midY), to: scene)
        XCTAssertEqual(mapCenterInScene.x, scene.size.width / 2, accuracy: 2.0)
        XCTAssertEqual(mapCenterInScene.y, scene.size.height / 2, accuracy: 2.0)
    }

    func testLoadedMapShowsPlayerMarkersWithoutCollisionDebugFrames() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))

        scene.loadMap(areaID: "village_square")

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let staticLayer = try XCTUnwrap(worldLayer.childNode(withName: "staticObjectLayer"))
        XCTAssertNotNil(staticLayer.childNode(withName: "exitMarker_4"))
        XCTAssertNotNil(staticLayer.childNode(withName: "exitMarker_5"))
        XCTAssertNotNil(staticLayer.childNode(withName: "triggerMarker_15"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_6"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_7"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_8"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_9"))
    }
}
