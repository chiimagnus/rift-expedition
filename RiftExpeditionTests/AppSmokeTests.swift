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

    func testSceneCanLoadAnimationCatalogOrFallBackToActorPlaceholders() throws {
        XCTAssertNotNil(ActorAnimationCatalog.resourceURL())
        XCTAssertNotNil(ActorAnimationCatalog.load())

        let sceneWithCatalog = GameScene(size: GameScene.sceneSize)
        sceneWithCatalog.didMove(to: SKView(frame: CGRect(origin: .zero, size: sceneWithCatalog.size)))
        XCTAssertNotNil(sceneWithCatalog.childNode(withName: "worldLayer"))

        let sceneWithoutCatalog = GameScene(size: GameScene.sceneSize)
        sceneWithoutCatalog.assetBundle = Bundle(for: Self.self)
        XCTAssertNil(ActorAnimationCatalog.resourceURL(bundle: sceneWithoutCatalog.assetBundle))
        XCTAssertNil(ActorAnimationCatalog.load(bundle: sceneWithoutCatalog.assetBundle))
        sceneWithoutCatalog.didMove(to: SKView(frame: CGRect(origin: .zero, size: sceneWithoutCatalog.size)))
        XCTAssertNotNil(sceneWithoutCatalog.childNode(withName: "worldLayer"))
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

        // `calculateAccumulatedFrame()` 会把 SKTiled 的对象层内部节点也算进去，不是瓦片地图本体
        // 的视觉边界。地图居中必须以 SKTiled 暴露给渲染布局使用的 boundingRect 为准。
        let mapFrame = tilemap.boundingRect
        let mapCenterInScene = worldLayer.convert(CGPoint(x: mapFrame.midX, y: mapFrame.midY), to: scene)
        XCTAssertEqual(mapCenterInScene.x, scene.size.width / 2, accuracy: 2.0)
        XCTAssertEqual(mapCenterInScene.y, scene.size.height / 2, accuracy: 2.0)
    }

    func testTiledMetadataUsesRenderedMapCoordinateSpace() throws {
        let metadata = try TiledMapLoader.loadMetadata(areaID: "village_square")
        let start = try XCTUnwrap(metadata.spawns.first { $0.id == "start" })
        let riversideExit = try XCTUnwrap(metadata.exits.first { $0.targetAreaID == "village_riverside" })
        let notice = try XCTUnwrap(metadata.triggers.first { $0.triggerID == "village_square_notice" })

        // 这些断言故意不是 TMX 原始坐标；它们锁住 SKTiled 渲染坐标，防止逻辑坐标再次和画面错位。
        XCTAssertEqual(start.position, CGPoint(x: -352, y: 0))
        XCTAssertEqual(riversideExit.frame, CGRect(x: -480, y: -32, width: 32, height: 64))
        XCTAssertEqual(notice.frame, CGRect(x: -112, y: 128, width: 128, height: 64))
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
        // village_square 地图里 navObstacle id 6-9 是四面屏幕边界墙（北/南/西/东边界）。
        // 它们的尺寸总是比任何真实的装饰性障碍物大得多（比如 1024x32 或 32x640），
        // 所以 shouldRenderAsProp 的尺寸判断规则总会把它们排除掉——不管名单里加了哪些
        // 障碍物名字，这一点都成立。
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_6"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_7"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_8"))
        XCTAssertNil(staticLayer.childNode(withName: "obstacleProp_9"))
        // id 10（石井）和 11（旧告示墙）是真实存在的独立障碍物，现在已经落在扩充后的
        // 名字白名单和尺寸判断规则范围内，所以它们必须渲染成看得见的场景物件。
        XCTAssertNotNil(staticLayer.childNode(withName: "obstacleProp_10"))
        XCTAssertNotNil(staticLayer.childNode(withName: "obstacleProp_11"))
    }

    func testEncounterTriggersAlwaysRenderVisibleMarkers() throws {
        // 所有遭遇战都是地图上固定安排好的，从来不是随机或者隐藏的（见
        // Docs/chapter1-worldgraph.md）。所以遭遇标记必须始终可见——不做「防剧透」式的隐藏。
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
        // 这是为了防止「探索模式下队伍没有立绘」这个 bug 再次出现的回归测试：队伍标记
        // 必须真的带着一个职业立绘的子节点，而不是光秃秃一个色圈。
        XCTAssertNotNil(partyNode.childNode(withName: "partySprite_player_1"))
    }

    func testExplorationPartyReusesNodeAndPlaysIdleThenWalkAnimation() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))

        let idleMember = PartyMemberPosition(
            actorID: "player_1",
            displayName: "战士1",
            classID: "warrior",
            position: CGPoint(x: 160, y: 320),
            target: nil,
            facing: .down
        )
        scene.renderParty([idleMember], leaderID: "player_1")

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let partyNode = try XCTUnwrap(worldLayer.childNode(withName: "party_player_1"))
        let idleSprite = try XCTUnwrap(partyNode.childNode(withName: "partySprite_player_1") as? SKSpriteNode)
        XCTAssertNotNil(idleSprite.action(forKey: "actorAnimation"))

        let movingMember = PartyMemberPosition(
            actorID: "player_1",
            displayName: "战士1",
            classID: "warrior",
            position: CGPoint(x: 180, y: 320),
            target: CGPoint(x: 220, y: 320),
            facing: .right
        )
        scene.renderParty([movingMember], leaderID: "player_1")

        let updatedPartyNode = try XCTUnwrap(worldLayer.childNode(withName: "party_player_1"))
        let walkSprite = try XCTUnwrap(updatedPartyNode.childNode(withName: "partySprite_player_1") as? SKSpriteNode)
        XCTAssertTrue(partyNode === updatedPartyNode)
        XCTAssertNotNil(walkSprite.action(forKey: "actorAnimation"))
    }

    func testBattleRenderReusesActorNodesAndDoesNotDuplicateEffectEvents() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))
        let snapshot = BattleSceneSnapshot(
            actors: [
                BattleActorMarker(
                    id: "player",
                    displayName: "战士",
                    factionName: "队友",
                    visualID: "actor_warrior",
                    facing: .right,
                    baseAction: .idle,
                    position: CGPoint(x: 100, y: 100),
                    health: 10,
                    maxHealth: 12,
                    actionPoints: 3,
                    maxActionPoints: 4,
                    isActive: true,
                    isTargetable: false,
                    isDefeated: false
                )
            ],
            surfaces: [],
            activeActorID: "player",
            selectedAction: .move,
            moveRadius: 84,
            presentationEvents: [
                BattlePresentationEvent(
                    id: 1,
                    actorID: "player",
                    action: .attack,
                    direction: .right,
                    targetActorID: "player",
                    effectPoint: CGPoint(x: 128, y: 100)
                )
            ]
        )

        scene.renderBattle(snapshot)
        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let battleLayer = try XCTUnwrap(worldLayer.childNode(withName: "battleLayer"))
        let actorNode = try XCTUnwrap(battleLayer.childNode(withName: "battleActor_player"))
        let spriteNode = try XCTUnwrap(actorNode.childNode(withName: "battleActorSprite_player"))
        XCTAssertEqual(battleLayer.children.filter { $0.name == "battleActor_player" }.count, 1)
        XCTAssertEqual(battleLayer.children.filter { $0.name == "battleEffect_1" }.count, 1)
        XCTAssertNotNil(spriteNode.action(forKey: "actorAnimation"))

        scene.renderBattle(snapshot)

        let updatedActorNode = try XCTUnwrap(battleLayer.childNode(withName: "battleActor_player"))
        let updatedSpriteNode = try XCTUnwrap(updatedActorNode.childNode(withName: "battleActorSprite_player"))
        XCTAssertTrue(actorNode === updatedActorNode)
        XCTAssertTrue(spriteNode === updatedSpriteNode)
        XCTAssertEqual(battleLayer.children.filter { $0.name == "battleActor_player" }.count, 1)
        XCTAssertEqual(battleLayer.children.filter { $0.name == "battleEffect_1" }.count, 1)
    }
}
