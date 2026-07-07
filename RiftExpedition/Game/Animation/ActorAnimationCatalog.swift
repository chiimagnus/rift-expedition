import CoreGraphics
import Foundation

struct ActorAnimationCatalog: Decodable, Equatable, Sendable {
    var version: Int
    var frameSize: ActorAnimationFrameSize
    var directions: [ActorAnimationDirection]
    var actions: [String: ActorAnimationAction]
    var sprites: [ActorAnimationSprite]

    static func resourceURL(bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: "actor-animations", withExtension: "json", subdirectory: "Assets")
    }

    static func load(bundle: Bundle = .main) -> ActorAnimationCatalog? {
        guard let url = resourceURL(bundle: bundle) else {
            return nil
        }
        do {
            return try decode(data: Data(contentsOf: url))
        } catch {
            GameLog.assets.error("Failed to load actor animation catalog: \(error.localizedDescription)")
            return nil
        }
    }

    static func decode(data: Data) throws -> ActorAnimationCatalog {
        try JSONDecoder().decode(ActorAnimationCatalog.self, from: data)
    }

    func sprite(for visualID: String) -> ActorAnimationSprite? {
        sprites.first { $0.visualID == visualID }
    }

    func sheetPath(for visualID: String) -> String? {
        sprite(for: visualID)?.sheet
    }

    func frames(
        for visualID: String,
        action: ActorAnimationKind,
        direction: ActorAnimationDirection
    ) -> [CGRect] {
        guard
            sprite(for: visualID) != nil,
            let action = actions[action.rawValue],
            let rowIndex = directions.firstIndex(of: direction)
        else {
            return []
        }

        let columns = 1152 / frameSize.width
        let rows = 384 / frameSize.height
        let textureRow = rows - rowIndex - 1
        return (0..<action.frameCount).map { frameOffset in
            let column = action.startColumn + frameOffset
            return CGRect(
                x: CGFloat(column) / CGFloat(columns),
                y: CGFloat(textureRow) / CGFloat(rows),
                width: CGFloat(frameSize.width) / 1152,
                height: CGFloat(frameSize.height) / 384
            )
        }
    }
}

struct ActorAnimationSprite: Decodable, Equatable, Sendable {
    var visualID: String
    var sheet: String
}

struct ActorAnimationAction: Decodable, Equatable, Sendable {
    var startColumn: Int
    var frameCount: Int
}

struct ActorAnimationFrameSize: Decodable, Equatable, Sendable {
    var width: Int
    var height: Int
}

enum ActorAnimationDirection: String, Decodable, Equatable, Sendable {
    case down
    case left
    case right
    case up
}

enum ActorAnimationKind: String, Decodable, Equatable, Sendable {
    case idle
    case walk
    case attack
    case hurt
}
