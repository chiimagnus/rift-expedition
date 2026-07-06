import AppKit
import RiftCore
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
    private let worldLayer = SKNode()
    private var tilemap: SKNode?
    private var loadedAreaID: String?
    private var currentMapSize: CGSize?
    private var lastUpdateTime: TimeInterval?
    private var partyNodes: [String: SKShapeNode] = [:]
    private var staticObjectLayer: SKNode?
    private var battleLayer: SKNode?
    private var textureCache: [String: SKTexture] = [:]

    static func makeScene() -> GameScene {
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    override func didMove(to view: SKView) {
        view.window?.makeFirstResponder(view)
        backgroundColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 1)
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
        }

        for member in members {
            let node = partyNodes[member.actorID] ?? makePartyNode(for: member)
            node.position = member.position
            node.fillColor = member.actorID == leaderID
                ? SKColor(red: 0.88, green: 0.68, blue: 0.24, alpha: 1)
                : SKColor(red: 0.38, green: 0.72, blue: 0.78, alpha: 1)
            partyNodes[member.actorID] = node
        }
    }

    func renderBattle(_ snapshot: BattleSceneSnapshot?) {
        battleLayer?.removeFromParent()
        battleLayer = nil
        guard let snapshot else { return }

        let layer = SKNode()
        layer.name = "battleLayer"
        layer.zPosition = 30
        worldLayer.addChild(layer)
        battleLayer = layer

        // ponytail: P2 battles contain only a few actors, so rebuilding the overlay is clearer than keyed diffing.
        for surface in snapshot.surfaces {
            layer.addChild(makeSurfaceNode(surface))
        }
        if let activeActor = snapshot.actors.first(where: { $0.id == snapshot.activeActorID }) {
            layer.addChild(makeMoveRangeNode(center: activeActor.position, radius: snapshot.moveRadius))
        }
        for actor in snapshot.actors {
            layer.addChild(makeBattleActorNode(actor))
        }
        if let point = snapshot.lastEffectPoint {
            layer.addChild(makeEffectNode(at: point))
        }
    }

    func loadMap(areaID: String) {
        guard loadedAreaID != areaID else { return }

        tilemap?.removeFromParent()
        tilemap = nil
        staticObjectLayer?.removeFromParent()
        staticObjectLayer = nil

        do {
            let metadata = try TiledMapLoader.loadMetadata(areaID: areaID)
            let loadedMap = try TiledMapLoader.load(areaID: areaID)
            loadedMap.position = .zero
            loadedMap.zPosition = 1
            worldLayer.addChild(loadedMap)
            tilemap = loadedMap
            currentMapSize = metadata.size
            loadedAreaID = areaID
            renderStaticObjects(metadata: metadata)
            layoutWorld()
        } catch {
            loadedAreaID = nil
            currentMapSize = nil
            layoutWorld()
            GameLog.map.error("\(areaID, privacy: .public).tmx 加载失败")
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
        guard let currentMapSize, currentMapSize.width > 0, currentMapSize.height > 0 else {
            worldLayer.setScale(1)
            worldLayer.position = .zero
            return
        }

        let fitScale = min(size.width / currentMapSize.width, size.height / currentMapSize.height) * 0.94
        let scale = min(max(fitScale, 0.35), 2.0)
        worldLayer.setScale(scale)
        worldLayer.position = CGPoint(
            x: (size.width - currentMapSize.width * scale) / 2,
            y: (size.height - currentMapSize.height * scale) / 2
        )
    }

    private func markClick(at point: CGPoint) {
        worldLayer.childNode(withName: "clickMarker")?.removeFromParent()

        let marker = SKShapeNode(circleOfRadius: 10)
        marker.name = "clickMarker"
        marker.position = point
        marker.fillColor = SKColor(red: 0.86, green: 0.73, blue: 0.34, alpha: 0.85)
        marker.strokeColor = .white
        marker.lineWidth = 2
        worldLayer.addChild(marker)
    }

    private func makePartyNode(for member: PartyMemberPosition) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 14)
        node.name = "party_\(member.actorID)"
        node.strokeColor = .white
        node.lineWidth = 2
        node.zPosition = 10
        worldLayer.addChild(node)
        return node
    }

    private func renderStaticObjects(metadata: TiledMapMetadata) {
        staticObjectLayer?.removeFromParent()
        let layer = SKNode()
        layer.name = "staticObjectLayer"
        layer.zPosition = 12
        worldLayer.addChild(layer)
        staticObjectLayer = layer

        for surface in metadata.surfaces {
            guard let type = SurfaceTypeColor(rawValue: surface.surfaceType) else { continue }
            layer.addChild(makeStaticSurfaceNode(frame: surface.frame, color: type.color))
        }
        for obstacle in metadata.navObstacles where obstacle.blocksMovement {
            if let node = makeVisibleObstacleNode(obstacle) {
                layer.addChild(node)
            }
        }
        for exit in metadata.exits {
            layer.addChild(makeExitMarker(exit))
        }
        for trigger in metadata.triggers {
            layer.addChild(makeTriggerMarker(trigger))
        }
        for npc in metadata.npcs {
            layer.addChild(makeMapSprite(name: spriteName(forNPC: npc), position: npc.position, size: CGSize(width: 52, height: 52)))
        }
        for item in metadata.items {
            layer.addChild(makeMapSprite(name: item.itemID == "rusted_sword" ? "prop_chest" : "prop_chest", position: item.position, size: CGSize(width: 48, height: 48)))
        }
    }

    private func makeBattleActorNode(_ actor: BattleActorMarker) -> SKNode {
        let container = SKNode()
        container.name = "battleActor_\(actor.id)"
        container.position = actor.position
        container.alpha = actor.isDefeated ? 0.42 : 1

        let ring = SKShapeNode(circleOfRadius: actor.isActive ? 34 : 30)
        ring.fillColor = actor.isActive
            ? SKColor(red: 0.84, green: 0.73, blue: 0.42, alpha: 0.20)
            : SKColor.black.withAlphaComponent(0.28)
        ring.strokeColor = actor.isTargetable
            ? SKColor(red: 0.92, green: 0.24, blue: 0.18, alpha: 1)
            : actor.isActive ? SKColor(red: 0.84, green: 0.73, blue: 0.42, alpha: 1) : .white.withAlphaComponent(0.35)
        ring.lineWidth = actor.isTargetable || actor.isActive ? 4 : 2
        ring.zPosition = -1
        container.addChild(ring)

        let sprite = SKSpriteNode(texture: texture(named: actor.spriteName))
        sprite.size = CGSize(width: 58, height: 58)
        sprite.zPosition = 1
        container.addChild(sprite)

        let healthBack = SKShapeNode(rectOf: CGSize(width: 52, height: 6), cornerRadius: 3)
        healthBack.position = CGPoint(x: 0, y: -40)
        healthBack.fillColor = SKColor.black.withAlphaComponent(0.65)
        healthBack.strokeColor = .clear
        container.addChild(healthBack)

        let healthRatio = CGFloat(max(0, actor.health)) / CGFloat(max(actor.maxHealth, 1))
        let health = SKShapeNode(rect: CGRect(x: -26, y: -43, width: 52 * healthRatio, height: 6), cornerRadius: 3)
        health.fillColor = SKColor(red: 0.76, green: 0.18, blue: 0.16, alpha: 1)
        health.strokeColor = .clear
        container.addChild(health)

        let label = SKLabelNode(text: actor.displayName)
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 12
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 42)
        label.verticalAlignmentMode = .center
        container.addChild(label)
        return container
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

    private func makeEffectNode(at point: CGPoint) -> SKNode {
        let node = SKShapeNode(circleOfRadius: 18)
        node.name = "battleEffect"
        node.position = point
        node.fillColor = SKColor(red: 1.0, green: 0.46, blue: 0.14, alpha: 0.42)
        node.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.38, alpha: 0.9)
        node.lineWidth = 3
        node.run(.sequence([
            .group([
                .scale(to: 2.0, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))
        return node
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

    private func makeVisibleObstacleNode(_ obstacle: NavigationObstacle) -> SKNode? {
        guard shouldRenderAsProp(obstacle) else { return nil }

        let sprite = SKSpriteNode(texture: texture(named: "prop_woodpile"))
        sprite.name = "obstacleProp_\(obstacle.tiledID)"
        sprite.size = CGSize(width: max(obstacle.frame.width, 42), height: max(obstacle.frame.height, 42))
        sprite.position = CGPoint(x: obstacle.frame.midX, y: obstacle.frame.midY)
        return sprite
    }

    private func shouldRenderAsProp(_ obstacle: NavigationObstacle) -> Bool {
        guard obstacle.frame.width <= 192, obstacle.frame.height <= 96 else { return false }
        guard let name = obstacle.name else { return false }
        return name.localizedStandardContains("倒木")
            || name.localizedStandardContains("木料")
            || name.localizedStandardContains("篱笆")
            || name.localizedStandardContains("货车")
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

    private func arrowText(for frame: CGRect) -> String {
        guard let currentMapSize else { return "→" }
        if frame.midX <= currentMapSize.width * 0.2 { return "←" }
        if frame.midX >= currentMapSize.width * 0.8 { return "→" }
        if frame.midY <= currentMapSize.height * 0.2 { return "↑" }
        if frame.midY >= currentMapSize.height * 0.8 { return "↓" }
        return "→"
    }

    private func makeMapSprite(name: String, position: CGPoint, size: CGSize) -> SKNode {
        let sprite = SKSpriteNode(texture: texture(named: name))
        sprite.name = name
        sprite.position = position
        sprite.size = size
        return sprite
    }

    private func texture(named name: String) -> SKTexture? {
        if let texture = textureCache[name] {
            return texture
        }
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Sprites")
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Characters")
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets/Icons")
        guard let url, let image = NSImage(contentsOf: url) else {
            return nil
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        textureCache[name] = texture
        return texture
    }

    private func spriteName(forNPC npc: MapNPC) -> String {
        switch npc.actorID {
        case "elder", "mayor":
            "npc_elder"
        default:
            "npc_elder"
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
