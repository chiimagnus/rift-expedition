import SpriteKit

@MainActor
protocol GameSceneEventHandling: AnyObject {
    func gameSceneDidLoad(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didClickWorld point: CGPoint)
}

@MainActor
final class GameScene: SKScene {
    static let sceneSize = CGSize(width: 1280, height: 720)

    weak var eventHandler: (any GameSceneEventHandling)?

    static func makeScene() -> GameScene {
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 1)
        eventHandler?.gameSceneDidLoad(self)
        drawGround()
    }

    override func mouseDown(with event: NSEvent) {
        let point = event.location(in: self)
        eventHandler?.gameScene(self, didClickWorld: point)
        markClick(at: point)
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
}
