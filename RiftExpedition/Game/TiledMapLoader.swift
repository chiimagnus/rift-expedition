import Foundation
import RiftCore
import SKTiled

enum TiledMapLoaderError: Error, Equatable {
    case missingResource(areaID: String)
    case parseFailed(areaID: String)
    case invalidMapFrame(areaID: String)
    case missingObjectGroup(areaID: String, group: String)
    case duplicateObjectGroup(areaID: String, group: String, count: Int)
    case invalidObjectID(areaID: String, group: String, tiledID: Int)
    case duplicateObjectID(areaID: String, tiledID: Int)
    case missingObjectProperty(areaID: String, group: String, tiledID: Int, property: String)
    case emptyObjectProperty(areaID: String, group: String, tiledID: Int, property: String)
    case invalidBooleanProperty(areaID: String, group: String, tiledID: Int, property: String, value: String)
    case invalidNumberProperty(areaID: String, group: String, tiledID: Int, property: String, value: String)
    case invalidObjectPosition(areaID: String, group: String, tiledID: Int)
    case invalidObjectFrame(areaID: String, group: String, tiledID: Int)
    case invalidSurfaceType(areaID: String, tiledID: Int, value: String)
}

struct TiledMapMetadata: Equatable {
    var areaID: String
    var mapFrame: CGRect
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
    /// NPC 在 Tiled 里的实际包围盒。地图作者必须在 Tiled 里把这个对象画成一个有宽高的矩形（而不是
    /// 只标一个点）来控制碰撞箱大小；RiftValidator 会在启动/发布校验时拒绝宽高为 0 的 npc 对象，
    /// 因此这里读到的 frame 总是有效的非零尺寸，调用方无需再做回退处理。
    var frame: CGRect
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
    var surfaceType: SurfaceType
    var frame: CGRect
}

struct MapItem: Equatable {
    var tiledID: Int
    var itemID: String
    var position: CGPoint
}

enum TiledMapLoader {
    /// 加载一张 Tiled 编辑器做的地图，并且所有玩法用的元数据（出生点/NPC/出口……）都是从
    /// 「用来渲染画面的同一份」`SKTilemap` 解析结果里读出来的，这样画面和玩法逻辑用的坐标
    /// 系统才能始终对得上。这替换掉了之前那种「再手写代码把 .tmx 的 XML 解析一遍」的老办法
    /// （老办法算出来的坐标，一直对不上 SKTiled 自己的上下翻转/居中对齐方式）。
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
        return (tilemap, try TiledMapMetadata(areaID: areaID, tilemap: tilemap))
    }

    /// 给那些只需要「玩法用的坐标信息」（比如 session 的 view model），
    /// 不需要整个渲染节点树的调用方，提供一个简便方法。
    // ponytail（有意为之的技术债）：这里为了读元数据，临时解析了一份用完就扔的 SKTilemap；
    // 在这个项目目前 10 张地图的规模下开销可以忽略。如果以后地图数量变多、
    // 或者这个方法被频繁调用，可以考虑按 areaID 加缓存。
    @MainActor
    static func loadMetadata(areaID: String, bundle: Bundle = .main) throws -> TiledMapMetadata {
        try load(areaID: areaID, bundle: bundle).metadata
    }

    @MainActor
    static func loadMetadata(url: URL, areaID: String) throws -> TiledMapMetadata {
        try load(url: url, areaID: areaID).metadata
    }

    static let chapterOneMapSubdirectory = "Maps/chapter1"

    private static func mapURL(areaID: String, bundle: Bundle) throws -> URL {
        guard let url = bundle.url(
            forResource: areaID,
            withExtension: "tmx",
            subdirectory: chapterOneMapSubdirectory
        ) else {
            throw TiledMapLoaderError.missingResource(areaID: areaID)
        }
        return url
    }
}

private extension TiledMapMetadata {
    @MainActor
    init(areaID: String, tilemap: SKTilemap) throws {
        let requiredGroupNames = [
            "spawn", "npc", "encounter", "trigger", "exit", "navObstacle", "surface", "item"
        ]
        var objectsByGroup: [String: [SKTileObject]] = [:]
        for groupName in requiredGroupNames {
            let groups = tilemap.objectGroups(named: groupName)
            guard !groups.isEmpty else {
                throw TiledMapLoaderError.missingObjectGroup(areaID: areaID, group: groupName)
            }
            guard groups.count == 1 else {
                throw TiledMapLoaderError.duplicateObjectGroup(
                    areaID: areaID,
                    group: groupName,
                    count: groups.count
                )
            }
            objectsByGroup[groupName] = groups[0].getObjects()
        }

        var seenObjectIDs: Set<Int> = []
        for groupName in requiredGroupNames {
            for object in objectsByGroup[groupName, default: []] {
                let tiledID = Int(object.id)
                guard tiledID > 0 else {
                    throw TiledMapLoaderError.invalidObjectID(
                        areaID: areaID,
                        group: groupName,
                        tiledID: tiledID
                    )
                }
                guard seenObjectIDs.insert(tiledID).inserted else {
                    throw TiledMapLoaderError.duplicateObjectID(areaID: areaID, tiledID: tiledID)
                }
            }
        }

        func requiredProperty(_ name: String, on object: SKTileObject, group: String) throws -> String {
            let tiledID = Int(object.id)
            guard let rawValue = object.properties[name] else {
                throw TiledMapLoaderError.missingObjectProperty(
                    areaID: areaID,
                    group: group,
                    tiledID: tiledID,
                    property: name
                )
            }
            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else {
                throw TiledMapLoaderError.emptyObjectProperty(
                    areaID: areaID,
                    group: group,
                    tiledID: tiledID,
                    property: name
                )
            }
            return value
        }

        func booleanProperty(_ name: String, on object: SKTileObject, group: String) throws -> Bool {
            let value = try requiredProperty(name, on: object, group: group)
            switch value {
            case "true":
                return true
            case "false":
                return false
            default:
                throw TiledMapLoaderError.invalidBooleanProperty(
                    areaID: areaID,
                    group: group,
                    tiledID: Int(object.id),
                    property: name,
                    value: value
                )
            }
        }

        func nonnegativeNumberProperty(_ name: String, on object: SKTileObject, group: String) throws -> CGFloat {
            let value = try requiredProperty(name, on: object, group: group)
            guard let number = Double(value), number.isFinite, number >= 0 else {
                throw TiledMapLoaderError.invalidNumberProperty(
                    areaID: areaID,
                    group: group,
                    tiledID: Int(object.id),
                    property: name,
                    value: value
                )
            }
            return CGFloat(number)
        }

        func point(for object: SKTileObject, group: String) throws -> CGPoint {
            let position: CGPoint
            if let layer = object.layer {
                position = tilemap.convert(object.position, from: layer)
            } else {
                position = object.position
            }
            guard position.x.isFinite, position.y.isFinite else {
                throw TiledMapLoaderError.invalidObjectPosition(
                    areaID: areaID,
                    group: group,
                    tiledID: Int(object.id)
                )
            }
            return position
        }

        func frame(for object: SKTileObject, group: String) throws -> CGRect {
            let result: CGRect
            if let layer = object.layer {
                let bottomLeftInGroup = CGPoint(x: object.position.x, y: object.position.y - object.size.height)
                let bottomLeftInTilemap = tilemap.convert(bottomLeftInGroup, from: layer)
                result = CGRect(origin: bottomLeftInTilemap, size: object.size)
            } else {
                result = CGRect(origin: object.position, size: object.size)
            }
            guard result.origin.x.isFinite,
                  result.origin.y.isFinite,
                  result.width.isFinite,
                  result.height.isFinite,
                  result.width > 0,
                  result.height > 0
            else {
                throw TiledMapLoaderError.invalidObjectFrame(
                    areaID: areaID,
                    group: group,
                    tiledID: Int(object.id)
                )
            }
            return result
        }

        self.areaID = areaID
        mapFrame = tilemap.frame
        guard mapFrame.origin.x.isFinite,
              mapFrame.origin.y.isFinite,
              mapFrame.width.isFinite,
              mapFrame.height.isFinite,
              mapFrame.width > 0,
              mapFrame.height > 0
        else {
            throw TiledMapLoaderError.invalidMapFrame(areaID: areaID)
        }

        spawns = try objectsByGroup["spawn", default: []].map { object in
            MapSpawn(
                tiledID: Int(object.id),
                id: try requiredProperty("id", on: object, group: "spawn"),
                position: try point(for: object, group: "spawn")
            )
        }

        npcs = try objectsByGroup["npc", default: []].map { object in
            MapNPC(
                tiledID: Int(object.id),
                actorID: try requiredProperty("actorId", on: object, group: "npc"),
                dialogID: try requiredProperty("dialogId", on: object, group: "npc"),
                position: try point(for: object, group: "npc"),
                frame: try frame(for: object, group: "npc")
            )
        }

        navObstacles = try objectsByGroup["navObstacle", default: []].map { object in
            NavigationObstacle(
                tiledID: Int(object.id),
                name: object.name,
                frame: try frame(for: object, group: "navObstacle"),
                blocksMovement: try booleanProperty("blocksMovement", on: object, group: "navObstacle"),
                blocksSight: try booleanProperty("blocksSight", on: object, group: "navObstacle")
            )
        }

        encounterTriggers = try objectsByGroup["encounter", default: []].map { object in
            MapEncounterTrigger(
                tiledID: Int(object.id),
                encounterID: try requiredProperty("encounterId", on: object, group: "encounter"),
                frame: try frame(for: object, group: "encounter"),
                radius: try nonnegativeNumberProperty("radius", on: object, group: "encounter")
            )
        }

        triggers = try objectsByGroup["trigger", default: []].map { object in
            MapTrigger(
                tiledID: Int(object.id),
                name: object.name,
                triggerID: try requiredProperty("triggerId", on: object, group: "trigger"),
                action: try requiredProperty("action", on: object, group: "trigger"),
                frame: try frame(for: object, group: "trigger")
            )
        }

        exits = try objectsByGroup["exit", default: []].map { object in
            MapExit(
                tiledID: Int(object.id),
                name: object.name,
                targetAreaID: try requiredProperty("targetAreaId", on: object, group: "exit"),
                targetSpawnID: try requiredProperty("targetSpawnId", on: object, group: "exit"),
                frame: try frame(for: object, group: "exit")
            )
        }

        surfaces = try objectsByGroup["surface", default: []].map { object in
            let value = try requiredProperty("surfaceType", on: object, group: "surface")
            guard let surfaceType = SurfaceType(rawValue: value) else {
                throw TiledMapLoaderError.invalidSurfaceType(
                    areaID: areaID,
                    tiledID: Int(object.id),
                    value: value
                )
            }
            return MapSurface(
                tiledID: Int(object.id),
                surfaceType: surfaceType,
                frame: try frame(for: object, group: "surface")
            )
        }

        items = try objectsByGroup["item", default: []].map { object in
            MapItem(
                tiledID: Int(object.id),
                itemID: try requiredProperty("itemId", on: object, group: "item"),
                position: try point(for: object, group: "item")
            )
        }
    }
}
