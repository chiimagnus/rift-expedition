import SpriteKit

@MainActor
protocol GameSceneEventHandling: AnyObject {
    func gameSceneDidLoad(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didClickWorld point: CGPoint)
    func gameSceneDidRequestLeaderSwitch(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didAdvance deltaTime: TimeInterval)
}

@MainActor
final class GameScene: SKScene {
    static let sceneSize = CGSize(width: 1280, height: 720)

    weak var eventHandler: (any GameSceneEventHandling)?
    private var tilemap: SKNode?
    private var lastUpdateTime: TimeInterval?
    private var partyNodes: [String: SKShapeNode] = [:]

    static func makeScene() -> GameScene {
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    override func didMove(to view: SKView) {
        view.window?.makeFirstResponder(view)
        backgroundColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 1)
        drawGround()
        loadInitialMap()
        eventHandler?.gameSceneDidLoad(self)
    }

    override func mouseDown(with event: NSEvent) {
        let point = event.location(in: self)
        eventHandler?.gameScene(self, didClickWorld: point)
        markClick(at: point)
    }

    override func keyDown(with event: NSEvent) {
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

    private func drawGround() {
        guard childNode(withName: "ground") == nil else { return }

        let ground = SKShapeNode(rectOf: size)
        ground.name = "ground"
        ground.fillColor = SKColor(red: 0.14, green: 0.19, blue: 0.12, alpha: 1)
        ground.strokeColor = SKColor(red: 0.38, green: 0.32, blue: 0.20, alpha: 1)
        ground.lineWidth = 6
        ground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(ground)
    }

    private func markClick(at point: CGPoint) {
        childNode(withName: "clickMarker")?.removeFromParent()

        let marker = SKShapeNode(circleOfRadius: 10)
        marker.name = "clickMarker"
        marker.position = point
        marker.fillColor = SKColor(red: 0.86, green: 0.73, blue: 0.34, alpha: 0.85)
        marker.strokeColor = .white
        marker.lineWidth = 2
        addChild(marker)
    }

    private func makePartyNode(for member: PartyMemberPosition) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 14)
        node.name = "party_\(member.actorID)"
        node.strokeColor = .white
        node.lineWidth = 2
        node.zPosition = 10
        addChild(node)
        return node
    }

    private func loadInitialMap() {
        guard tilemap == nil else { return }

        do {
            let loadedMap = try TiledMapLoader.load(areaID: "vertical_slice")
            loadedMap.position = .zero
            loadedMap.zPosition = 1
            addChild(loadedMap)
            tilemap = loadedMap
        } catch {
            GameLog.map.error("vertical_slice.tmx 加载失败")
        }
    }
}
