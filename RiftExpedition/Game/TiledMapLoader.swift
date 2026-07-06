import Foundation
import SKTiled

enum TiledMapLoaderError: Error, Equatable {
    case missingResource(areaID: String)
    case parseFailed(areaID: String)
    case unreadableMetadata(areaID: String)
    case invalidMetadata(areaID: String)
}

struct TiledMapMetadata: Equatable {
    var areaID: String
    var spawns: [MapSpawn]
    var npcs: [MapNPC]
    var navObstacles: [NavigationObstacle]
    var encounterTriggers: [MapEncounterTrigger]
    var triggers: [MapTrigger]
    var exits: [MapExit]
    var surfaces: [MapSurface]
    var items: [MapItem]
}

struct MapSpawn: Equatable {
    var tiledID: Int
    var id: String
    var position: CGPoint
}

struct MapNPC: Equatable {
    var tiledID: Int
    var actorID: String
    var dialogID: String
    var position: CGPoint
}

struct NavigationObstacle: Equatable {
    var tiledID: Int
    var name: String? = nil
    var frame: CGRect
    var blocksMovement: Bool
    var blocksSight: Bool
}

struct MapEncounterTrigger: Equatable {
    var tiledID: Int
    var encounterID: String
    var frame: CGRect
    var radius: CGFloat

    var center: CGPoint {
        CGPoint(x: frame.midX, y: frame.midY)
    }

    func contains(_ point: CGPoint) -> Bool {
        frame.contains(point) || hypot(point.x - center.x, point.y - center.y) <= radius
    }
}

struct MapTrigger: Equatable {
    var tiledID: Int
    var name: String? = nil
    var triggerID: String
    var action: String
    var frame: CGRect

    func contains(_ point: CGPoint) -> Bool {
        frame.contains(point)
    }
}

struct MapExit: Equatable {
    var tiledID: Int
    var name: String? = nil
    var targetAreaID: String
    var targetSpawnID: String
    var frame: CGRect

    func contains(_ point: CGPoint) -> Bool {
        frame.contains(point)
    }
}

struct MapSurface: Equatable {
    var tiledID: Int
    var surfaceType: String
    var frame: CGRect
}

struct MapItem: Equatable {
    var tiledID: Int
    var itemID: String
    var position: CGPoint
}

enum TiledMapLoader {
    /// Loads a Tiled map and derives all gameplay metadata (spawn/npc/exit/...) from the
    /// SAME parsed `SKTilemap` that renders it, so rendering and gameplay logic always agree
    /// on one coordinate space. This replaces the old approach of hand-parsing the .tmx XML
    /// a second time (which never matched SKTiled's Y-flip / anchor-centered layout).
    @MainActor
    static func load(areaID: String, bundle: Bundle = .main) throws -> (tilemap: SKTilemap, metadata: TiledMapMetadata) {
        try load(url: mapURL(areaID: areaID, bundle: bundle), areaID: areaID)
    }

    @MainActor
    static func load(url: URL, areaID: String) throws -> (tilemap: SKTilemap, metadata: TiledMapMetadata) {
        guard let tilemap = SKTilemap.load(tmxFile: url.path, loggingLevel: .none) else {
            throw TiledMapLoaderError.parseFailed(areaID: areaID)
        }

        tilemap.name = areaID
        return (tilemap, TiledMapMetadata(areaID: areaID, tilemap: tilemap))
    }

    /// Convenience for callers that only need gameplay positions (e.g. the session view model),
    /// not the rendered node tree.
    // ponytail: this parses a throwaway SKTilemap just to read metadata; fine at this project's
    // 10-map scale, revisit (e.g. cache by areaID) if map count or load frequency grows.
    @MainActor
    static func loadMetadata(areaID: String, bundle: Bundle = .main) throws -> TiledMapMetadata {
        try load(areaID: areaID, bundle: bundle).metadata
    }

    @MainActor
    static func loadMetadata(url: URL, areaID: String) throws -> TiledMapMetadata {
        try load(url: url, areaID: areaID).metadata
    }

    private static func mapURL(areaID: String, bundle: Bundle) throws -> URL {
        if let url = bundle.url(forResource: areaID, withExtension: "tmx", subdirectory: "Maps") {
            return url
        }
        if let url = bundle.url(forResource: areaID, withExtension: "tmx", subdirectory: "Maps/chapter1") {
            return url
        }
        if let url = bundle.url(forResource: areaID, withExtension: "tmx") {
            return url
        }
        throw TiledMapLoaderError.missingResource(areaID: areaID)
    }
}

private extension TiledMapMetadata {
    /// Builds metadata straight from SKTiled's own parsed object layers/objects, reusing
    /// SKTiled's coordinate conversion instead of re-deriving Tiled's top-left/Y-down
    /// convention by hand (that hand-rolled math was the root cause of the map/object
    /// misalignment: it never matched SKTiled's Y-flip or its center-anchored tilemap layout).
    @MainActor
    init(areaID: String, tilemap: SKTilemap) {
        // Not just `.first`: aggregate every object group with this name, matching the old
        // hand-rolled XML parser's behavior of collecting objects from every `<objectgroup>`
        // with a given name (current maps only ever have one per name, but nothing guarantees
        // that stays true as more maps are authored).
        func objects(in groupName: String) -> [SKTileObject] {
            tilemap.objectGroups(named: groupName).flatMap { $0.getObjects() }
        }

        // Every object's `.position` is already in its owning object-group's local space
        // (SKTiled applies the Tiled -> SpriteKit Y-flip when it adds the object to the group).
        // Converting through `tilemap.convert(_:from:)` normalizes it into the tilemap's own
        // space, which is exactly the space the rendered tile layers live in.
        func point(for object: SKTileObject) -> CGPoint {
            guard let group = object.layer else { return object.position }
            return tilemap.convert(object.position, from: group)
        }

        func frame(for object: SKTileObject) -> CGRect {
            guard let group = object.layer else {
                return CGRect(origin: object.position, size: object.size)
            }
            // SKTileObject's local bounding box is (0, 0, width, -height): `.position` is the
            // object's top-left corner post Y-flip, so the rect's bottom-left corner (the CGRect
            // origin convention) sits `size.height` below it.
            let bottomLeftInGroup = CGPoint(x: object.position.x, y: object.position.y - object.size.height)
            let bottomLeftInTilemap = tilemap.convert(bottomLeftInGroup, from: group)
            return CGRect(origin: bottomLeftInTilemap, size: object.size)
        }

        self.areaID = areaID

        spawns = objects(in: "spawn").compactMap { object in
            guard let id = object.properties["id"] else { return nil }
            return MapSpawn(tiledID: Int(object.id), id: id, position: point(for: object))
        }

        npcs = objects(in: "npc").compactMap { object in
            guard let actorID = object.properties["actorId"],
                  let dialogID = object.properties["dialogId"] else { return nil }
            return MapNPC(tiledID: Int(object.id), actorID: actorID, dialogID: dialogID, position: point(for: object))
        }

        navObstacles = objects(in: "navObstacle").map { object in
            NavigationObstacle(
                tiledID: Int(object.id),
                name: object.name,
                frame: frame(for: object),
                blocksMovement: object.properties["blocksMovement"] == "true",
                blocksSight: object.properties["blocksSight"] == "true"
            )
        }

        encounterTriggers = objects(in: "encounter").compactMap { object in
            guard let encounterID = object.properties["encounterId"] else { return nil }
            return MapEncounterTrigger(
                tiledID: Int(object.id),
                encounterID: encounterID,
                frame: frame(for: object),
                radius: CGFloat(Double(object.properties["radius"] ?? "") ?? 0)
            )
        }

        triggers = objects(in: "trigger").compactMap { object in
            guard let triggerID = object.properties["triggerId"],
                  let action = object.properties["action"] else { return nil }
            return MapTrigger(
                tiledID: Int(object.id),
                name: object.name,
                triggerID: triggerID,
                action: action,
                frame: frame(for: object)
            )
        }

        exits = objects(in: "exit").compactMap { object in
            guard let targetAreaID = object.properties["targetAreaId"],
                  let targetSpawnID = object.properties["targetSpawnId"] else { return nil }
            return MapExit(
                tiledID: Int(object.id),
                name: object.name,
                targetAreaID: targetAreaID,
                targetSpawnID: targetSpawnID,
                frame: frame(for: object)
            )
        }

        surfaces = objects(in: "surface").compactMap { object in
            guard let surfaceType = object.properties["surfaceType"] else { return nil }
            return MapSurface(tiledID: Int(object.id), surfaceType: surfaceType, frame: frame(for: object))
        }

        items = objects(in: "item").compactMap { object in
            guard let itemID = object.properties["itemId"] else { return nil }
            return MapItem(tiledID: Int(object.id), itemID: itemID, position: point(for: object))
        }
    }
}
