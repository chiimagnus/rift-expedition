import Foundation
import SKTiled

enum TiledMapLoaderError: Error, Equatable {
    case missingResource(areaID: String)
    case parseFailed(areaID: String)
}

@MainActor
enum TiledMapLoader {
    static func load(areaID: String, bundle: Bundle = .main) throws -> SKTilemap {
        guard let url = bundle.url(forResource: areaID, withExtension: "tmx", subdirectory: "Maps") else {
            throw TiledMapLoaderError.missingResource(areaID: areaID)
        }

        guard let tilemap = SKTilemap.load(tmxFile: url.path, loggingLevel: .none) else {
            throw TiledMapLoaderError.parseFailed(areaID: areaID)
        }

        tilemap.name = areaID
        return tilemap
    }
}
