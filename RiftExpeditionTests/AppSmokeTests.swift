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

    func testSceneUsesConfiguredAssetBundleForMapLoading() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.assetBundle = Bundle(for: Self.self)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))

        scene.loadMap(areaID: "village_square")

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        XCTAssertNil(worldLayer.childNode(withName: "village_square"))
        XCTAssertEqual(TiledMapLoader.chapterOneMapSubdirectory, "Maps/chapter1")
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
        // 正式章节地图只使用 background_art / foreground_* 美术层。
        // navObstacle 是纯玩法数据，不再生成通用木堆占位物。
        XCTAssertFalse(staticLayer.children.contains { $0.name?.hasPrefix("obstacleProp_") == true })
    }

    func testUnresolvedEncounterTriggersRenderVisibleMarkers() throws {
        // 未解决遭遇是地图上固定安排的内容，必须清晰可见；解决后则由世界表现状态移除。
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))

        scene.loadMap(areaID: "village_outskirts")

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let staticLayer = try XCTUnwrap(worldLayer.childNode(withName: "staticObjectLayer"))
        XCTAssertNotNil(staticLayer.childNode(withName: "encounterMarker_11"))
    }

    func testWorldPresentationRemovesResolvedStaticObjects() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))

        scene.loadMap(areaID: "village_square")
        scene.renderExplorationWorld(
            ExplorationWorldPresentation(
                areaID: "village_square",
                hiddenItemTiledIDs: [],
                hiddenTriggerTiledIDs: [15],
                hiddenEncounterTiledIDs: []
            )
        )
        var worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        var staticLayer = try XCTUnwrap(worldLayer.childNode(withName: "staticObjectLayer"))
        XCTAssertNil(staticLayer.childNode(withName: "triggerMarker_15"))

        scene.loadMap(areaID: "village_outskirts")
        scene.renderExplorationWorld(
            ExplorationWorldPresentation(
                areaID: "village_outskirts",
                hiddenItemTiledIDs: [],
                hiddenTriggerTiledIDs: [],
                hiddenEncounterTiledIDs: [11]
            )
        )
        worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        staticLayer = try XCTUnwrap(worldLayer.childNode(withName: "staticObjectLayer"))
        XCTAssertNil(staticLayer.childNode(withName: "encounterMarker_11"))

        scene.loadMap(areaID: "wilds_road")
        scene.renderExplorationWorld(
            ExplorationWorldPresentation(
                areaID: "wilds_road",
                hiddenItemTiledIDs: [14],
                hiddenTriggerTiledIDs: [],
                hiddenEncounterTiledIDs: []
            )
        )
        worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        staticLayer = try XCTUnwrap(worldLayer.childNode(withName: "staticObjectLayer"))
        XCTAssertNil(staticLayer.childNode(withName: "mapItem_14"))
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
                    sourcePoint: nil,
                    effectPoint: CGPoint(x: 128, y: 100),
                    effectStyle: nil,
                    feedback: nil
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

    func testBattleProjectileAndFeedbackNodesDoNotDuplicate() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))
        let snapshot = BattleSceneSnapshot(
            actors: [
                BattleActorMarker(
                    id: "archer",
                    displayName: "弓手",
                    factionName: "队友",
                    visualID: "actor_archer",
                    facing: .right,
                    baseAction: .idle,
                    position: CGPoint(x: 100, y: 100),
                    health: 12,
                    maxHealth: 12,
                    actionPoints: 3,
                    maxActionPoints: 4,
                    isActive: true,
                    isTargetable: false,
                    isDefeated: false
                ),
                BattleActorMarker(
                    id: "target",
                    displayName: "目标",
                    factionName: "敌人",
                    visualID: "enemy_human_melee",
                    facing: .left,
                    baseAction: .idle,
                    position: CGPoint(x: 260, y: 100),
                    health: 6,
                    maxHealth: 12,
                    actionPoints: 4,
                    maxActionPoints: 4,
                    isActive: false,
                    isTargetable: true,
                    isDefeated: false
                )
            ],
            surfaces: [],
            activeActorID: "archer",
            selectedAction: .skill("test_shot"),
            moveRadius: 0,
            presentationEvents: [
                BattlePresentationEvent(
                    id: 7,
                    actorID: "archer",
                    action: .attack,
                    direction: .right,
                    targetActorID: "target",
                    sourcePoint: CGPoint(x: 100, y: 100),
                    effectPoint: CGPoint(x: 260, y: 100),
                    effectStyle: .projectile,
                    feedback: .damage(amount: 6, defeated: false)
                )
            ]
        )

        scene.renderBattle(snapshot)
        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let battleLayer = try XCTUnwrap(worldLayer.childNode(withName: "battleLayer"))
        let effect = try XCTUnwrap(battleLayer.childNode(withName: "battleEffect_7"))
        XCTAssertNotNil(effect.childNode(withName: "battleProjectile_7"))
        let feedback = try XCTUnwrap(effect.childNode(withName: "battleFeedback_7") as? SKLabelNode)
        XCTAssertEqual(feedback.text, "−6")

        scene.renderBattle(snapshot)

        XCTAssertEqual(battleLayer.children.filter { $0.name == "battleEffect_7" }.count, 1)
    }

    func testDefeatedBattleActorUsesCollapsedPose() throws {
        let scene = GameScene(size: GameScene.sceneSize)
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))
        let snapshot = BattleSceneSnapshot(
            actors: [
                BattleActorMarker(
                    id: "fallen",
                    displayName: "倒下的敌人",
                    factionName: "敌人",
                    visualID: "enemy_human_melee",
                    facing: .left,
                    baseAction: .idle,
                    position: CGPoint(x: 220, y: 140),
                    health: 0,
                    maxHealth: 12,
                    actionPoints: 0,
                    maxActionPoints: 4,
                    isActive: false,
                    isTargetable: false,
                    isDefeated: true
                )
            ],
            surfaces: [],
            activeActorID: nil,
            selectedAction: .move,
            moveRadius: 0,
            presentationEvents: []
        )

        scene.renderBattle(snapshot)

        let worldLayer = try XCTUnwrap(scene.childNode(withName: "worldLayer"))
        let battleLayer = try XCTUnwrap(worldLayer.childNode(withName: "battleLayer"))
        let actorNode = try XCTUnwrap(battleLayer.childNode(withName: "battleActor_fallen"))
        let sprite = try XCTUnwrap(actorNode.childNode(withName: "battleActorSprite_fallen") as? SKSpriteNode)
        XCTAssertEqual(sprite.zRotation, -.pi / 2, accuracy: 0.001)
        XCTAssertEqual(sprite.position.y, -18, accuracy: 0.001)
        XCTAssertEqual(sprite.alpha, 0.62, accuracy: 0.001)
        XCTAssertNil(sprite.action(forKey: "actorAnimation"))
    }

}
