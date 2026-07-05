import SpriteKit

final class GameScene: SKScene {
    static let sceneSize = CGSize(width: 1280, height: 720)

    static func makeScene() -> GameScene {
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
    }
}
