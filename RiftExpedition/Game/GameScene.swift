import AppKit
import RiftCore
import SKTiled
import SpriteKit

@MainActor
protocol GameSceneEventHandling: AnyObject {
    func gameSceneDidLoad(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didClickWorld point: CGPoint)
    func gameSceneDidRequestLeaderSwitch(_ scene: GameScene)
    func gameSceneDidRequestDebugToggle(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didAdvance deltaTime: TimeInterval)
}

@MainActor
final class GameScene: SKScene {
    static let sceneSize = CGSize(width: 1280, height: 720)

    weak var eventHandler: (any GameSceneEventHandling)?
    var isWorldInputEnabled = true
    var assetBundle: Bundle = .main
    private let worldLayer = SKNode()
    private var tilemap: SKTilemap?
    private var loadedAreaID: String?
    private var loadedMapMetadata: TiledMapMetadata?
    private var worldPresentation: ExplorationWorldPresentation?
    private var lastUpdateTime: TimeInterval?
    private var partyNodes: [String: SKNode] = [:]
    private var staticObjectLayer: SKNode?
    private var battleLayer: SKNode?
    private var battleActorNodes: [String: SKNode] = [:]
    private var renderedBattleEffectIDs: Set<Int> = []
    private var playedBattleAnimationEventIDs: Set<Int> = []
    private var textureCache: [String: SKTexture] = [:]
    private var animationFrameCache: [String: [SKTexture]] = [:]
    private var nodeAnimationKeys: [String: String] = [:]
    private lazy var actorAnimationCatalog: ActorAnimationCatalog? = ActorAnimationCatalog.load(bundle: assetBundle)
    private var didLogAnimationCatalogFallback = false
    private var loggedMissingActorAnimations: Set<String> = []

    static func makeScene() -> GameScene {
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    override func didMove(to view: SKView) {
        view.window?.makeFirstResponder(view)
        backgroundColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 1)
        preloadAnimationCatalogIfNeeded()
        if worldLayer.parent == nil {
            worldLayer.name = "worldLayer"
            worldLayer.zPosition = 0
            addChild(worldLayer)
        }
        drawGround()
        layoutWorld()
        eventHandler?.gameSceneDidLoad(self)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        drawGround()
        layoutWorld()
    }

    override func mouseDown(with event: NSEvent) {
        guard isWorldInputEnabled else { return }

        let scenePoint = event.location(in: self)
        let point = worldLayer.convert(scenePoint, from: self)
        eventHandler?.gameScene(self, didClickWorld: point)
        markClick(at: point)
    }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers?.lowercased() == "d" {
            eventHandler?.gameSceneDidRequestDebugToggle(self)
            return
        }

        guard isWorldInputEnabled else {
            super.keyDown(with: event)
            return
        }

        if event.charactersIgnoringModifiers == "\t" {
            eventHandler?.gameSceneDidRequestLeaderSwitch(self)
            return
        }
        super.keyDown(with: event)
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard let lastUpdateTime else { return }

        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 15.0)
        eventHandler?.gameScene(self, didAdvance: deltaTime)
    }

    func renderParty(_ members: [PartyMemberPosition], leaderID: String?) {
        let memberIDs = Set(members.map(\.actorID))
        let staleActorIDs = partyNodes.keys.filter { !memberIDs.contains($0) }
        for actorID in staleActorIDs {
            partyNodes[actorID]?.removeFromParent()
            partyNodes[actorID] = nil
            nodeAnimationKeys["party:\(actorID)"] = nil
        }

        for member in members {
            let node = partyNodes[member.actorID] ?? makePartyNode(for: member)
            node.position = member.position
            // 队长用头顶的小箭头标记来区分，而不是脚下套一圈圆圈；这样探索时的角色本体
            // 和战斗时看起来完全一致（同样的精灵尺寸、没有额外的底盘和描边圈）。
            node.childNode(withName: "partyLeaderMarker_\(member.actorID)")?.isHidden = member.actorID != leaderID
            if let sprite = node.childNode(withName: "partySprite_\(member.actorID)") as? SKSpriteNode {
                let visualID = partyVisualID(for: member)
                playActorAnimation(
                    on: sprite,
                    nodeKey: "party:\(member.actorID)",
                    visualID: visualID,
                    action: member.target == nil ? .idle : .walk,
                    direction: member.facing
                )
            }
            partyNodes[member.actorID] = node
        }
    }

    func renderBattle(_ snapshot: BattleSceneSnapshot?) {
        guard let snapshot else {
            battleLayer?.removeFromParent()
            battleLayer = nil
            battleActorNodes.removeAll()
            renderedBattleEffectIDs.removeAll()
            playedBattleAnimationEventIDs.removeAll()
            return
        }

        let layer = battleLayer ?? makeBattleLayer()
        for child in layer.children
        where child.name?.hasPrefix("battleActor_") != true
            && child.name?.hasPrefix("battleEffect_") != true {
            child.removeFromParent()
        }

        for surface in snapshot.surfaces {
            layer.addChild(makeSurfaceNode(surface))
        }
        if let activeActor = snapshot.actors.first(where: { $0.id == snapshot.activeActorID }) {
            layer.addChild(makeMoveRangeNode(center: activeActor.position, radius: snapshot.moveRadius))
        }

        let actorIDs = Set(snapshot.actors.map(\.id))
        for staleID in battleActorNodes.keys where !actorIDs.contains(staleID) {
            battleActorNodes[staleID]?.removeFromParent()
            battleActorNodes[staleID] = nil
        }
        for actor in snapshot.actors {
            let node = battleActorNodes[actor.id] ?? makeBattleActorNode(actor)
            updateBattleActorNode(node, actor: actor)
            if node.parent == nil {
                layer.addChild(node)
            }
            battleActorNodes[actor.id] = node
        }
        for event in snapshot.presentationEvents {
            playBattlePresentationEvent(event, actors: snapshot.actors)
            guard !renderedBattleEffectIDs.contains(event.id),
                  let effectNode = makeBattleEffectNode(for: event)
            else {
                continue
            }
            renderedBattleEffectIDs.insert(event.id)
            layer.addChild(effectNode)
        }
    }

    private func makeBattleLayer() -> SKNode {
        let layer = SKNode()
        layer.name = "battleLayer"
        // 这里把数值调得比 SKTiled 内部图层可能用到的 zPosition 都高很多
        // （具体原因见下面 staticObjectLayer / 队伍节点相关的注释）。
        layer.zPosition = 700
        worldLayer.addChild(layer)
        battleLayer = layer
        return layer
    }

    func renderExplorationWorld(_ presentation: ExplorationWorldPresentation) {
        worldPresentation = presentation
        guard presentation.areaID == loadedAreaID, let loadedMapMetadata else {
            return
        }
        renderStaticObjects(metadata: loadedMapMetadata, presentation: presentation)
    }

    func loadMap(areaID: String) {
        guard loadedAreaID != areaID else { return }

        tilemap?.removeFromParent()
        tilemap = nil
        staticObjectLayer?.removeFromParent()
        staticObjectLayer = nil
        loadedMapMetadata = nil

        do {
            let (loadedMap, metadata) = try TiledMapLoader.load(areaID: areaID, bundle: assetBundle)
            loadedMap.position = .zero
            loadedMap.zPosition = 1
            configureMapArtLayers(in: loadedMap)
            worldLayer.addChild(loadedMap)
            tilemap = loadedMap
            loadedAreaID = areaID
            loadedMapMetadata = metadata
            let presentation = worldPresentation?.areaID == areaID ? worldPresentation : nil
            renderStaticObjects(metadata: metadata, presentation: presentation)
            layoutWorld()
        } catch {
            loadedAreaID = nil
            layoutWorld()
            GameLog.map.error("\(areaID, privacy: .public).tmx 加载失败")
        }
    }

    private func configureMapArtLayers(in tilemap: SKTilemap) {
        for imageLayer in tilemap.imageLayers() {
            switch imageLayer.layerName {
            case "background_art":
                imageLayer.zPosition = -10
            case let name where name.hasPrefix("foreground_"):
                // Foreground art is authored as a transparent image layer and can
                // occlude actors without changing collision or interaction data.
                imageLayer.zPosition = 760
            default:
                break
            }
        }
    }

    private func drawGround() {
        childNode(withName: "ground")?.removeFromParent()

        let ground = SKShapeNode(rectOf: size)
        ground.name = "ground"
        ground.fillColor = SKColor(red: 0.14, green: 0.19, blue: 0.12, alpha: 1)
        ground.strokeColor = SKColor(red: 0.38, green: 0.32, blue: 0.20, alpha: 1)
        ground.lineWidth = 6
        ground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ground.zPosition = -100
        addChild(ground)
    }

    private func layoutWorld() {
        // tilemap 在 worldLayer 里的坐标是 (0, 0)，所以 tilemap.boundingRect 用的
        // 已经是 worldLayer 自己的坐标系。这里用地图的「实际中心点」来居中，
        // 而不是假设左下角是 (0, 0)，因为 SKTiled 默认的 `.center` 对齐方式是
        // 以地图自己的原点为中心铺开，而不是以左下角为准。
        guard let tilemap else {
            worldLayer.setScale(1)
            worldLayer.position = .zero
            return
        }

        let mapRect = tilemap.boundingRect
        let mapWidth = abs(mapRect.width)
        let mapHeight = abs(mapRect.height)
        guard mapWidth > 0, mapHeight > 0 else {
            worldLayer.setScale(1)
            worldLayer.position = .zero
            return
        }

        let fitScale = min(size.width / mapWidth, size.height / mapHeight) * 0.94
        let scale = min(max(fitScale, 0.35), 2.0)
        worldLayer.setScale(scale)
        worldLayer.position = CGPoint(
            x: size.width / 2 - mapRect.midX * scale,
            y: size.height / 2 - mapRect.midY * scale
        )
    }

    private func markClick(at point: CGPoint) {
        worldLayer.childNode(withName: "clickMarker")?.removeFromParent()

        let marker = SKNode()
        marker.name = "clickMarker"
        marker.position = point
        marker.zPosition = 560

        let outerRing = SKShapeNode(circleOfRadius: 13)
        outerRing.fillColor = .clear
        outerRing.strokeColor = SKColor(red: 0.20, green: 0.82, blue: 1.0, alpha: 0.95)
        outerRing.lineWidth = 2
        outerRing.glowWidth = 5
        marker.addChild(outerRing)

        let innerDiamond = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 1)
        innerDiamond.zRotation = .pi / 4
        innerDiamond.fillColor = SKColor(red: 0.66, green: 0.34, blue: 1.0, alpha: 0.9)
        innerDiamond.strokeColor = .white.withAlphaComponent(0.85)
        innerDiamond.lineWidth = 1
        marker.addChild(innerDiamond)

        outerRing.run(.group([
            .scale(to: 2.25, duration: 0.42),
            .fadeOut(withDuration: 0.42)
        ]))
        innerDiamond.run(.sequence([
            .scale(to: 1.35, duration: 0.10),
            .scale(to: 0.75, duration: 0.22),
            .fadeOut(withDuration: 0.10)
        ]))
        marker.run(.sequence([.wait(forDuration: 0.46), .removeFromParent()]))
        worldLayer.addChild(marker)
    }

    private func makePartyNode(for member: PartyMemberPosition) -> SKNode {
        let node = SKNode()
        node.name = "party_\(member.actorID)"
        // 参考 renderStaticObjects 里 staticObjectLayer.zPosition 的注释：这里把数值从
        // 10 调高了不少，确保队伍角色不会被地图图层挡住。
        node.zPosition = 550
        worldLayer.addChild(node)

        // 探索场景的角色本体与战斗场景保持一致：同样用 58×58 的精灵图，不再套脚下的
        // 圆形底盘和白色描边圈（旧的 SKShapeNode 队伍标记已删除）。
        let sprite = makeActorSprite(name: "partySprite_\(member.actorID)", size: CGSize(width: 58, height: 58))
        sprite.zPosition = 1
        node.addChild(sprite)

        // 队长标记：头顶一个金色小箭头，仅队长可见（renderParty 里按 leaderID 切换显隐）。
        let leaderMarker = SKLabelNode(text: "\u{25BC}")
        leaderMarker.name = "partyLeaderMarker_\(member.actorID)"
        leaderMarker.fontName = "Helvetica-Bold"
        leaderMarker.fontSize = 16
        leaderMarker.fontColor = SKColor(red: 0.88, green: 0.68, blue: 0.24, alpha: 1)
        leaderMarker.verticalAlignmentMode = .center
        leaderMarker.horizontalAlignmentMode = .center
        leaderMarker.position = CGPoint(x: 0, y: 40)
        leaderMarker.zPosition = 2
        leaderMarker.isHidden = true
        node.addChild(leaderMarker)

        return node
    }

    private func partyVisualID(for member: PartyMemberPosition) -> String {
        switch member.classID {
        case "archer":
            "actor_archer"
        case "mage":
            "actor_mage"
        case "rogue":
            "actor_rogue"
        default:
            "actor_warrior"
        }
    }

    private func renderStaticObjects(
        metadata: TiledMapMetadata,
        presentation: ExplorationWorldPresentation?
    ) {
        staticObjectLayer?.removeFromParent()
        nodeAnimationKeys = nodeAnimationKeys.filter { !$0.key.hasPrefix("npc:") }
        let layer = SKNode()
        layer.name = "staticObjectLayer"
        // SKTiled 的 `SKTilemap` 会给它从 .tmx 文件里解析出来的每个图层自己分配一个内部
        // zPosition，按文件里出现的顺序往上叠。这套机制 SKTiled 官方没有公开说明、属于它内部
        // 实现细节，所以与其猜一个「应该够用」的数值，这里干脆调得比它内部可能用到的任何数值
        // 都高很多，确保 staticObjectLayer（以及同级的队伍标记、点击标记、战斗层）
        // 不会被地图瓦片挡住。同时配合 GameRootView 里 SpriteView 的 `ignoresSiblingOrder`
        // 开关，让 zPosition 变成全局排序，而不是一层层按父子��系排。
        layer.zPosition = 500
        worldLayer.addChild(layer)
        staticObjectLayer = layer

        for surface in metadata.surfaces {
            layer.addChild(
                makeStaticSurfaceNode(
                    frame: surface.frame,
                    color: SurfaceTypeColor(surface.surfaceType).color
                )
            )
        }
        for exit in metadata.exits {
            layer.addChild(makeExitMarker(exit))
        }
        for trigger in metadata.triggers where presentation?.shows(trigger: trigger) != false {
            layer.addChild(makeTriggerMarker(trigger))
        }
        // 遭遇触发区（伏击点）必须始终显示，没有例外。这个项目的设计里没有「隐藏伏击」这种
        // 玩法（所有遭遇战都是地图上固定安排好的，不是随机出现的——见 Docs/chapter1-worldgraph.md），
        // 所以如果触发区完全看不见，那是渲染上的 bug，不是故意藏起来防剧透。
        for encounter in metadata.encounterTriggers where presentation?.shows(encounter: encounter) != false {
            layer.addChild(makeEncounterMarker(encounter))
        }
        for npc in metadata.npcs {
            layer.addChild(makeNPCSprite(npc))
        }
        for item in metadata.items where presentation?.shows(item: item) != false {
            let node = makeMapSprite(
                name: spriteName(forMapItem: item),
                position: item.position,
                size: CGSize(width: 48, height: 48)
            )
            node.name = "mapItem_\(item.tiledID)"
            layer.addChild(node)
        }
    }

    private func makeBattleActorNode(_ actor: BattleActorMarker) -> SKNode {
        let container = SKNode()
        container.name = "battleActor_\(actor.id)"

        let sprite = makeActorSprite(name: "battleActorSprite_\(actor.id)", size: CGSize(width: 58, height: 58))
        sprite.zPosition = 1
        container.addChild(sprite)
        return container
    }

    private func updateBattleActorNode(_ container: SKNode, actor: BattleActorMarker) {
        container.position = actor.position
        container.alpha = actor.isDefeated ? 0.72 : 1
        for child in container.children where child.name?.hasPrefix("battleActorSprite_") != true {
            child.removeFromParent()
        }
        if let sprite = container.childNode(withName: "battleActorSprite_\(actor.id)") as? SKSpriteNode {
            sprite.size = CGSize(width: 58, height: 58)
            sprite.zPosition = 1
            let nodeKey = "battle:\(actor.id)"
            if actor.isDefeated {
                applyDefeatedPose(to: sprite, nodeKey: nodeKey, actor: actor)
            } else {
                sprite.position = .zero
                sprite.zRotation = 0
                sprite.alpha = 1
                if nodeAnimationKeys[nodeKey]?.hasPrefix("event:") != true {
                    playActorAnimation(
                        on: sprite,
                        nodeKey: nodeKey,
                        visualID: actor.visualID,
                        action: actor.baseAction,
                        direction: actor.facing
                    )
                }
            }
        }

        let ring = SKShapeNode(circleOfRadius: actor.isActive ? 34 : 30)
        ring.name = "battleActorRing_\(actor.id)"
        ring.fillColor = actor.isActive
            ? SKColor(red: 0.84, green: 0.73, blue: 0.42, alpha: 0.20)
            : SKColor.black.withAlphaComponent(0.28)
        ring.strokeColor = actor.isTargetable
            ? SKColor(red: 0.92, green: 0.24, blue: 0.18, alpha: 1)
            : actor.isActive ? SKColor(red: 0.84, green: 0.73, blue: 0.42, alpha: 1) : .white.withAlphaComponent(0.35)
        ring.lineWidth = actor.isTargetable || actor.isActive ? 4 : 2
        ring.zPosition = -1
        if actor.isActive {
            ring.run(.repeatForever(.sequence([
                .group([.scale(to: 1.12, duration: 0.48), .fadeAlpha(to: 0.56, duration: 0.48)]),
                .group([.scale(to: 1.0, duration: 0.48), .fadeAlpha(to: 1.0, duration: 0.48)])
            ])))
        }
        container.addChild(ring)

        let healthBack = SKShapeNode(rectOf: CGSize(width: 52, height: 6), cornerRadius: 3)
        healthBack.name = "battleActorHealthBack_\(actor.id)"
        healthBack.position = CGPoint(x: 0, y: -40)
        healthBack.fillColor = SKColor.black.withAlphaComponent(0.65)
        healthBack.strokeColor = .clear
        container.addChild(healthBack)

        let healthRatio = CGFloat(max(0, actor.health)) / CGFloat(max(actor.maxHealth, 1))
        let health = SKShapeNode(rect: CGRect(x: -26, y: -43, width: 52 * healthRatio, height: 6), cornerRadius: 3)
        health.name = "battleActorHealth_\(actor.id)"
        health.fillColor = SKColor(red: 0.76, green: 0.18, blue: 0.16, alpha: 1)
        health.strokeColor = .clear
        container.addChild(health)

        let label = SKLabelNode(text: actor.displayName)
        label.name = "battleActorLabel_\(actor.id)"
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 12
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 42)
        label.verticalAlignmentMode = .center
        container.addChild(label)
    }

    private func playBattlePresentationEvent(_ event: BattlePresentationEvent, actors: [BattleActorMarker]) {
        guard !playedBattleAnimationEventIDs.contains(event.id),
              let actor = actors.first(where: { $0.id == event.actorID }),
              let node = battleActorNodes[event.actorID],
              let sprite = node.childNode(withName: "battleActorSprite_\(event.actorID)") as? SKSpriteNode
        else {
            return
        }
        playedBattleAnimationEventIDs.insert(event.id)
        let nodeKey = "battle:\(event.actorID)"
        guard let frames = animationFrames(visualID: actor.visualID, action: event.action, direction: event.direction) else {
            playActorAnimation(on: sprite, nodeKey: nodeKey, visualID: actor.visualID, action: .idle, direction: actor.facing)
            return
        }

        nodeAnimationKeys[nodeKey] = "event:\(event.id)"
        sprite.xScale = abs(sprite.xScale)
        sprite.removeAction(forKey: "actorAnimation")
        sprite.texture = frames.first
        sprite.run(.sequence([
            .animate(with: frames, timePerFrame: 0.12),
            .run { [weak self, weak sprite] in
                guard let self, let sprite else { return }
                if actor.isDefeated {
                    self.applyDefeatedPose(to: sprite, nodeKey: nodeKey, actor: actor)
                } else {
                    self.playActorAnimation(
                        on: sprite,
                        nodeKey: nodeKey,
                        visualID: actor.visualID,
                        action: .idle,
                        direction: actor.facing
                    )
                }
            }
        ]), withKey: "actorAnimation")

        if event.action == .hurt {
            sprite.run(.sequence([
                .colorize(with: .white, colorBlendFactor: 1, duration: 0.02),
                .wait(forDuration: 0.045),
                .colorize(withColorBlendFactor: 0, duration: 0.08)
            ]), withKey: "impactFlash")

            node.run(.sequence([
                .moveBy(x: -4, y: 1, duration: 0.025),
                .moveBy(x: 7, y: -2, duration: 0.035),
                .moveBy(x: -3, y: 1, duration: 0.04)
            ]), withKey: "impactRecoil")

        }
    }

    private func makeMoveRangeNode(center: CGPoint, radius: CGFloat) -> SKNode {
        let node = SKShapeNode(circleOfRadius: max(0, radius))
        node.name = "moveRange"
        node.position = center
        node.fillColor = SKColor(red: 0.25, green: 0.72, blue: 0.52, alpha: 0.08)
        node.strokeColor = SKColor(red: 0.42, green: 0.95, blue: 0.64, alpha: 0.42)
        node.lineWidth = 2
        node.zPosition = -4
        return node
    }

    private func makeBattleEffectNode(for event: BattlePresentationEvent) -> SKNode? {
        guard event.effectPoint != nil || event.feedback != nil else { return nil }

        let container = SKNode()
        container.name = "battleEffect_\(event.id)"
        container.zPosition = 20

        let impactPoint = event.effectPoint ?? event.sourcePoint ?? .zero
        let travelDuration = projectileTravelDuration(for: event)
        if travelDuration > 0,
           let sourcePoint = event.sourcePoint,
           let effectPoint = event.effectPoint {
            let projectile = makeProjectileNode(style: event.effectStyle, eventID: event.id)
            projectile.position = sourcePoint
            projectile.zRotation = atan2(effectPoint.y - sourcePoint.y, effectPoint.x - sourcePoint.x)
            projectile.run(.sequence([
                .move(to: effectPoint, duration: travelDuration),
                .removeFromParent()
            ]))
            container.addChild(projectile)
        }

        let shouldShowImpact: Bool
        if case .some(.dodge) = event.feedback {
            shouldShowImpact = false
        } else {
            shouldShowImpact = event.effectPoint != nil
        }

        if shouldShowImpact {
            if travelDuration > 0 {
                container.run(.sequence([
                    .wait(forDuration: travelDuration),
                    .run { [weak self, weak container] in
                        guard let self, let container else { return }
                        container.addChild(self.makeImpactNode(at: impactPoint, style: event.effectStyle))
                    }
                ]), withKey: "impact")
            } else {
                container.addChild(makeImpactNode(at: impactPoint, style: event.effectStyle))
            }
        }

        if let feedback = event.feedback {
            let feedbackNode = makeFeedbackNode(
                feedback,
                at: impactPoint,
                eventID: event.id,
                delay: travelDuration
            )
            container.addChild(feedbackNode)
            let shake = SKAction.run { [weak self] in
                self?.runImpactShake(for: feedback)
            }
            container.run(.sequence([.wait(forDuration: travelDuration), shake]), withKey: "feedbackImpact")
        }

        container.run(.sequence([
            .wait(forDuration: travelDuration + 0.72),
            .removeFromParent()
        ]))
        return container
    }

    private func projectileTravelDuration(for event: BattlePresentationEvent) -> TimeInterval {
        guard let sourcePoint = event.sourcePoint,
              let effectPoint = event.effectPoint,
              sourcePoint != effectPoint
        else {
            return 0
        }
        switch event.effectStyle {
        case .projectile, .arcane, .fire, .poison:
            let distance = hypot(effectPoint.x - sourcePoint.x, effectPoint.y - sourcePoint.y)
            return min(max(TimeInterval(distance / 720), 0.12), 0.34)
        case .strike, .heal, .none:
            return 0
        }
    }

    private func makeProjectileNode(style: BattleEffectStyle?, eventID: Int) -> SKNode {
        let node = SKNode()
        node.name = "battleProjectile_\(eventID)"
        let palette = effectPalette(for: style)

        let trail = SKShapeNode(rectOf: CGSize(width: 22, height: 4), cornerRadius: 2)
        trail.position = CGPoint(x: -9, y: 0)
        trail.fillColor = palette.ring.withAlphaComponent(0.52)
        trail.strokeColor = .clear
        trail.glowWidth = 3
        node.addChild(trail)

        let core = SKShapeNode(circleOfRadius: style == .projectile ? 4 : 6)
        core.fillColor = palette.core
        core.strokeColor = palette.stroke
        core.lineWidth = 1
        core.glowWidth = 5
        node.addChild(core)
        return node
    }

    private func makeImpactNode(at point: CGPoint, style: BattleEffectStyle?) -> SKNode {
        let container = SKNode()
        container.position = point

        let palette = effectPalette(for: style)
        let coreRadius: CGFloat = style == .projectile ? 7 : 9
        let ringRadius: CGFloat = style == .heal ? 16 : 18

        let core = SKShapeNode(circleOfRadius: coreRadius)
        core.fillColor = palette.core
        core.strokeColor = palette.stroke
        core.lineWidth = 1
        core.glowWidth = 6
        container.addChild(core)

        let ring = SKShapeNode(circleOfRadius: ringRadius)
        ring.fillColor = .clear
        ring.strokeColor = palette.ring
        ring.lineWidth = style == .heal ? 2 : 3
        ring.glowWidth = 4
        container.addChild(ring)

        core.run(.group([
            .scale(to: style == .heal ? 0.35 : 0.2, duration: 0.20),
            .fadeOut(withDuration: 0.20)
        ]))
        ring.run(.group([
            .scale(to: style == .projectile ? 1.9 : 2.35, duration: 0.24),
            .fadeOut(withDuration: 0.24)
        ]))

        for index in 0..<8 {
            let spark = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 2.4 : 1.5)
            spark.fillColor = index.isMultiple(of: 2) ? palette.sparkA : palette.sparkB
            spark.strokeColor = .clear
            let angle = CGFloat(index) / 8 * .pi * 2
            let distance: CGFloat = style == .heal ? (index.isMultiple(of: 2) ? 28 : 22) : (index.isMultiple(of: 2) ? 34 : 25)
            let movement = style == .projectile
                ? CGVector(dx: cos(angle) * distance * 0.8, dy: sin(angle) * distance * 0.55)
                : CGVector(dx: cos(angle) * distance, dy: sin(angle) * distance)
            spark.run(.sequence([
                .group([
                    .moveBy(x: movement.dx, y: movement.dy, duration: 0.22),
                    .scale(to: 0.15, duration: 0.22),
                    .fadeOut(withDuration: 0.22)
                ]),
                .removeFromParent()
            ]))
            container.addChild(spark)
        }

        if style == .heal {
            for index in 0..<2 {
                let bar = SKShapeNode(rectOf: CGSize(width: index == 0 ? 12 : 4, height: index == 0 ? 4 : 12), cornerRadius: 1)
                bar.fillColor = palette.stroke
                bar.strokeColor = .clear
                container.addChild(bar)
                bar.run(.sequence([.fadeOut(withDuration: 0.22), .removeFromParent()]))
            }
        }
        return container
    }

    private func makeFeedbackNode(
        _ feedback: BattleFeedback,
        at point: CGPoint,
        eventID: Int,
        delay: TimeInterval
    ) -> SKLabelNode {
        let label = SKLabelNode()
        label.name = "battleFeedback_\(eventID)"
        label.position = CGPoint(x: point.x, y: point.y + 42)
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 18
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 28

        switch feedback {
        case let .damage(amount, defeated):
            label.text = defeated ? "−\(amount) · 击倒" : "−\(amount)"
            label.fontColor = SKColor(red: 1.0, green: 0.42, blue: 0.28, alpha: 1)
        case let .healing(amount):
            label.text = "+\(amount)"
            label.fontColor = SKColor(red: 0.42, green: 1.0, blue: 0.72, alpha: 1)
        case .dodge:
            label.text = "闪避"
            label.fontColor = SKColor(red: 0.72, green: 0.90, blue: 1.0, alpha: 1)
        }

        label.alpha = 0
        label.run(.sequence([
            .wait(forDuration: delay),
            .fadeIn(withDuration: 0.01),
            .group([
                .moveBy(x: 0, y: 24, duration: 0.42),
                .sequence([.wait(forDuration: 0.20), .fadeOut(withDuration: 0.22)])
            ])
        ]))
        return label
    }

    private func runImpactShake(for feedback: BattleFeedback) {
        guard case let .damage(amount, _) = feedback else { return }
        let strength = min(max(CGFloat(amount) / 5, 1), 3.2)
        worldLayer.removeAction(forKey: "impactShake")
        worldLayer.run(.sequence([
            .moveBy(x: strength, y: strength * 0.35, duration: 0.025),
            .moveBy(x: -strength * 2, y: -strength * 0.7, duration: 0.035),
            .moveBy(x: strength, y: strength * 0.35, duration: 0.045)
        ]), withKey: "impactShake")
    }

    private func applyDefeatedPose(to sprite: SKSpriteNode, nodeKey: String, actor: BattleActorMarker) {
        sprite.removeAction(forKey: "actorAnimation")
        sprite.removeAction(forKey: "impactFlash")
        sprite.position = CGPoint(x: 0, y: -18)
        sprite.zRotation = -.pi / 2
        sprite.alpha = 0.62
        if let frames = animationFrames(visualID: actor.visualID, action: .hurt, direction: actor.facing),
           let finalFrame = frames.last {
            sprite.texture = finalFrame
        }
        nodeAnimationKeys[nodeKey] = "defeated"
    }

    private func effectPalette(for style: BattleEffectStyle?) -> (core: SKColor, stroke: SKColor, ring: SKColor, sparkA: SKColor, sparkB: SKColor) {
        switch style ?? .strike {
        case .strike:
            return (
                SKColor(red: 1.0, green: 0.88, blue: 0.62, alpha: 0.92),
                .white,
                SKColor(red: 1.0, green: 0.42, blue: 0.16, alpha: 0.95),
                SKColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 0.95),
                SKColor(red: 0.42, green: 0.84, blue: 1.0, alpha: 0.9)
            )
        case .projectile:
            return (
                SKColor(red: 0.72, green: 0.92, blue: 1.0, alpha: 0.92),
                .white,
                SKColor(red: 0.33, green: 0.73, blue: 1.0, alpha: 0.95),
                SKColor(red: 0.82, green: 0.95, blue: 1.0, alpha: 0.95),
                SKColor(red: 0.32, green: 0.72, blue: 1.0, alpha: 0.9)
            )
        case .arcane:
            return (
                SKColor(red: 0.88, green: 0.75, blue: 1.0, alpha: 0.94),
                .white,
                SKColor(red: 0.62, green: 0.42, blue: 1.0, alpha: 0.95),
                SKColor(red: 0.95, green: 0.86, blue: 1.0, alpha: 0.95),
                SKColor(red: 0.50, green: 0.72, blue: 1.0, alpha: 0.9)
            )
        case .fire:
            return (
                SKColor(red: 1.0, green: 0.78, blue: 0.32, alpha: 0.94),
                .white,
                SKColor(red: 1.0, green: 0.36, blue: 0.14, alpha: 0.96),
                SKColor(red: 1.0, green: 0.55, blue: 0.20, alpha: 0.95),
                SKColor(red: 1.0, green: 0.86, blue: 0.42, alpha: 0.9)
            )
        case .poison:
            return (
                SKColor(red: 0.72, green: 0.94, blue: 0.50, alpha: 0.94),
                .white,
                SKColor(red: 0.36, green: 0.78, blue: 0.28, alpha: 0.96),
                SKColor(red: 0.60, green: 0.94, blue: 0.42, alpha: 0.95),
                SKColor(red: 0.90, green: 1.0, blue: 0.62, alpha: 0.9)
            )
        case .heal:
            return (
                SKColor(red: 0.62, green: 1.0, blue: 0.86, alpha: 0.94),
                .white,
                SKColor(red: 0.22, green: 0.82, blue: 0.68, alpha: 0.96),
                SKColor(red: 0.72, green: 1.0, blue: 0.90, alpha: 0.95),
                SKColor(red: 0.42, green: 0.94, blue: 0.82, alpha: 0.9)
            )
        }
    }

    private func makeSurfaceNode(_ surface: BattleSurfaceMarker) -> SKNode {
        makeStaticSurfaceNode(frame: surface.frame, color: SurfaceTypeColor(surface.surfaceType).color)
    }

    private func makeStaticSurfaceNode(frame: CGRect, color: SKColor) -> SKNode {
        let node = SKShapeNode(rect: frame, cornerRadius: 8)
        node.fillColor = color.withAlphaComponent(0.42)
        node.strokeColor = color.withAlphaComponent(0.82)
        node.lineWidth = 2
        node.zPosition = -5
        return node
    }

    private func makeExitMarker(_ exit: MapExit) -> SKNode {
        let node = SKNode()
        node.name = "exitMarker_\(exit.tiledID)"
        node.position = CGPoint(x: exit.frame.midX, y: exit.frame.midY)
        node.zPosition = 8

        let plate = SKShapeNode(rectOf: CGSize(width: max(exit.frame.width + 28, 72), height: max(exit.frame.height + 20, 64)), cornerRadius: 12)
        plate.fillColor = SKColor(red: 0.93, green: 0.62, blue: 0.18, alpha: 0.20)
        plate.strokeColor = SKColor(red: 0.97, green: 0.75, blue: 0.30, alpha: 0.92)
        plate.lineWidth = 3
        node.addChild(plate)

        let arrow = SKLabelNode(text: arrowText(for: exit.frame))
        arrow.fontName = "PingFangSC-Semibold"
        arrow.fontSize = 22
        arrow.fontColor = SKColor(red: 1.0, green: 0.86, blue: 0.42, alpha: 1)
        arrow.verticalAlignmentMode = .center
        arrow.position = CGPoint(x: 0, y: 13)
        node.addChild(arrow)

        let label = SKLabelNode(text: exit.name ?? "出口")
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -15)
        node.addChild(label)
        return node
    }

    private func makeTriggerMarker(_ trigger: MapTrigger) -> SKNode {
        let node = SKNode()
        node.name = "triggerMarker_\(trigger.tiledID)"
        node.position = CGPoint(x: trigger.frame.midX, y: trigger.frame.midY)
        node.zPosition = 7

        let pin = SKShapeNode(circleOfRadius: 12)
        pin.fillColor = SKColor(red: 0.38, green: 0.72, blue: 0.78, alpha: 0.72)
        pin.strokeColor = .white
        pin.lineWidth = 2
        node.addChild(pin)

        let label = SKLabelNode(text: trigger.name ?? "线索")
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 11
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -24)
        node.addChild(label)
        return node
    }

    private func makeEncounterMarker(_ encounter: MapEncounterTrigger) -> SKNode {
        // 始终可见——这个项目没有隐藏伏击的设计，所以遭遇区域要和出口、剧情触发点一样清楚地
        // 显示出来，不能等玩家走进去才突然出现。
        let node = SKNode()
        node.name = "encounterMarker_\(encounter.tiledID)"
        node.position = encounter.center
        node.zPosition = 7

        let pin = SKShapeNode(circleOfRadius: 14)
        pin.fillColor = SKColor(red: 0.82, green: 0.20, blue: 0.16, alpha: 0.78)
        pin.strokeColor = .white
        pin.lineWidth = 2
        node.addChild(pin)

        let glyph = SKLabelNode(text: "⚔")
        glyph.fontSize = 14
        glyph.verticalAlignmentMode = .center
        node.addChild(glyph)

        return node
    }

    private func arrowText(for frame: CGRect) -> String {
        guard let tilemap else { return "→" }
        let mapRect = tilemap.boundingRect
        let mapWidth = mapRect.maxX - mapRect.minX
        let mapHeight = mapRect.maxY - mapRect.minY
        if frame.midX <= mapRect.minX + mapWidth * 0.2 { return "←" }
        if frame.midX >= mapRect.maxX - mapWidth * 0.2 { return "→" }
        if frame.midY <= mapRect.minY + mapHeight * 0.2 { return "↑" }
        if frame.midY >= mapRect.maxY - mapHeight * 0.2 { return "↓" }
        return "→"
    }

    private func makeMapSprite(name: String, position: CGPoint, size: CGSize) -> SKNode {
        let sprite = SKSpriteNode(texture: texture(named: name))
        sprite.name = name
        sprite.position = position
        sprite.size = size
        return sprite
    }

    private func makeNPCSprite(_ npc: MapNPC) -> SKNode {
        let visualID = ActorVisualIDResolver.npcVisualID(actorID: npc.actorID)
        let sprite = makeActorSprite(name: "npc_\(npc.actorID)", size: CGSize(width: 52, height: 52))
        sprite.position = npc.position
        playActorAnimation(
            on: sprite,
            nodeKey: "npc:\(npc.tiledID)",
            visualID: visualID,
            action: .idle,
            direction: .down
        )
        return sprite
    }

    private func texture(named name: String) -> SKTexture? {
        if let texture = textureCache[name] {
            return texture
        }
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Sprites")
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Icons")
        guard let url, let image = NSImage(contentsOf: url) else {
            return nil
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        textureCache[name] = texture
        return texture
    }

    private func preloadAnimationCatalogIfNeeded() {
        guard actorAnimationCatalog == nil, !didLogAnimationCatalogFallback else { return }
        didLogAnimationCatalogFallback = true
        GameLog.assets.notice("Actor animation catalog unavailable; using minimal actor placeholders")
    }

    private func makeActorSprite(name: String, size: CGSize) -> SKSpriteNode {
        let sprite = SKSpriteNode(
            color: SKColor(red: 0.72, green: 0.28, blue: 0.72, alpha: 0.85),
            size: size
        )
        sprite.name = name
        sprite.colorBlendFactor = 1
        return sprite
    }

    private func animationFrames(
        visualID: String,
        action: ActorAnimationKind,
        direction: ActorAnimationDirection
    ) -> [SKTexture]? {
        let cacheKey = "\(visualID)/\(action.rawValue)/\(direction.rawValue)"
        if let frames = animationFrameCache[cacheKey] {
            return frames
        }
        guard
            let catalog = actorAnimationCatalog,
            let sheetPath = catalog.sheetPath(for: visualID),
            let sheetTexture = texture(sheetPath: sheetPath)
        else {
            return nil
        }

        let frames = catalog.frames(for: visualID, action: action, direction: direction).map { rect in
            let texture = SKTexture(rect: rect, in: sheetTexture)
            texture.filteringMode = .nearest
            return texture
        }
        guard !frames.isEmpty else {
            return nil
        }
        animationFrameCache[cacheKey] = frames
        return frames
    }

    private func playActorAnimation(
        on sprite: SKSpriteNode,
        nodeKey: String,
        visualID: String,
        action: ActorAnimationKind,
        direction: ActorAnimationDirection
    ) {
        let animationKey = "\(visualID)/\(action.rawValue)/\(direction.rawValue)"
        if let frames = animationFrames(visualID: visualID, action: action, direction: direction) {
            sprite.xScale = abs(sprite.xScale)
            guard nodeAnimationKeys[nodeKey] != animationKey else { return }
            nodeAnimationKeys[nodeKey] = animationKey
            sprite.removeAction(forKey: "actorAnimation")
            sprite.colorBlendFactor = 0
            sprite.texture = frames.first
            sprite.run(.repeatForever(.animate(with: frames, timePerFrame: 0.16)), withKey: "actorAnimation")
            return
        }

        nodeAnimationKeys[nodeKey] = nil
        sprite.removeAction(forKey: "actorAnimation")
        logMissingActorAnimation(visualID: visualID, action: action, direction: direction)
        sprite.texture = nil
        sprite.color = SKColor(red: 0.72, green: 0.28, blue: 0.72, alpha: 0.85)
        sprite.colorBlendFactor = 1
        sprite.xScale = direction == .left ? -abs(sprite.xScale) : abs(sprite.xScale)
        sprite.position = .zero
    }

    private func logMissingActorAnimation(
        visualID: String,
        action: ActorAnimationKind,
        direction: ActorAnimationDirection
    ) {
        let key = "\(visualID)/\(action.rawValue)/\(direction.rawValue)"
        guard !loggedMissingActorAnimations.contains(key) else { return }
        loggedMissingActorAnimations.insert(key)
        GameLog.assets.warning("Actor animation missing: \(key, privacy: .public)")
    }

    private func texture(sheetPath: String) -> SKTexture? {
        let cacheKey = "sheet:\(sheetPath)"
        if let texture = textureCache[cacheKey] {
            return texture
        }
        let path = NSString(string: sheetPath)
        let resource = path.deletingPathExtension
        let ext = path.pathExtension
        guard
            let url = assetBundle.url(forResource: resource, withExtension: ext.isEmpty ? nil : ext),
            let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        textureCache[cacheKey] = texture
        return texture
    }

    private func spriteName(forMapItem item: MapItem) -> String {
        switch item.itemID {
        case "minor_healing_draught":
            "icon_potion"
        case "element_ore_ledger", "rift_shard_amulet":
            "icon_element_ore"
        default:
            "prop_chest"
        }
    }
}

private enum SurfaceTypeColor: String {
    case water
    case oil
    case poison
    case fire

    init(_ surfaceType: SurfaceType) {
        switch surfaceType {
        case .water:
            self = .water
        case .oil:
            self = .oil
        case .poison:
            self = .poison
        case .fire:
            self = .fire
        }
    }

    var color: SKColor {
        switch self {
        case .water:
            SKColor(red: 0.20, green: 0.58, blue: 0.72, alpha: 1)
        case .oil:
            SKColor(red: 0.11, green: 0.10, blue: 0.08, alpha: 1)
        case .poison:
            SKColor(red: 0.42, green: 0.78, blue: 0.22, alpha: 1)
        case .fire:
            SKColor(red: 0.95, green: 0.28, blue: 0.08, alpha: 1)
        }
    }
}
