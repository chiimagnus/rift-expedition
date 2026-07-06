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
        // village_square's navObstacle ids 6-9 are the four screen-edge boundary walls
        // (北/南/西/东边界). They are always far larger than any real decorative obstacle
        // (e.g. 1024x32 or 32x640), so `shouldRenderAsProp`'s size gate always excludes them —
        // this stays true no matter which obstacle names get whitelisted.
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_6"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_7"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_8"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_9"))
        // ids 10 (石井) and 11 (旧告示墙) are real discrete obstacles that now fall within the
        // expanded name whitelist and size gate, so they must render as visible props.
        XCTAssertNotNil(staticLayer.childNode(withName: "obstacleProp_10"))
        XCTAssertNotNil(staticLayer.childNode(withName: "obstacleProp_11"))
    }

    func testEncounterTriggersAlwaysRenderVisibleMarkers() throws {
        // Encounters are fixed, map-authored, never random or hidden (Docs/chapter1-worldgraph.md).
        // The marker must always be visible — no stealth/ambush spoiler-gating.
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))

        scene.loadMap(areaID: "village_outskirts")

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let staticLayer = try XCTUnwrap(worldLayer.childNode(withName: "staticObjectLayer"))
        XCTAssertNotNil(staticLayer.childNode(withName: "encounterMarker_11"))
    }

    func testExplorationPartyMembersRenderWithClassSprites() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))
        scene.loadMap(areaID: "village_square")

        scene.renderParty(
            [
                PartyMemberPosition(
                    actorID: "player_1",
                    displayName: "战士1",
                    classID: "warrior",
                    position: CGPoint(x: 160, y: 320),
                    target: nil
                )
            ],
            leaderID: "player_1"
        )

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let partyNode = try XCTUnwrap(worldLayer.childNode(withName: "party_player_1"))
        // Regression guard for the "exploration party has no art" bug: the party marker must
        // carry an actual class sprite child, not just a bare colored circle.
        XCTAssertNotNil(partyNode.childNode(withName: "partySprite_player_1"))
    }
}
