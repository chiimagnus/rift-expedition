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
        return (tilemap, TiledMapMetadata(areaID: areaID, tilemap: tilemap))
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
    /// 直接基于 SKTiled 自己解析出来的图层/对象来生成元数据，复用 SKTiled 自带的坐标转换，
    /// 而不是自己再手写一套 Tiled「左上角为原点、Y 轴向下」的换算规则（之前手写的那套换算
    /// 正是「地图和物体对不上」这个 bug 的根源：它一直没对上 SKTiled 自己的上下翻转
    /// 和居中对齐布局方式）。
    @MainActor
    init(areaID: String, tilemap: SKTilemap) {
        // 这里不是只取第一个（.first），而是把所有同名的对象组都汇总起来，这是为了保持和
        // 之前手写 XML 解析器一样的行为——把每一个同名 `<objectgroup>` 里的对象都收集进来
        // （目前每张地图每个名字只有一个对象组，但不能保证以后新做的地图也一定是这样）。
        func objects(in groupName: String) -> [SKTileObject] {
            tilemap.objectGroups(named: groupName).flatMap { $0.getObjects() }
        }

        // ponytail: 这批第一章地图都是正交图，直接把 SKTiled 内部的翻转坐标还原回 TMX 坐标系就够了。
        func point(for object: SKTileObject) -> CGPoint {
            object.position.invertedY
        }

        func frame(for object: SKTileObject) -> CGRect {
            CGRect(origin: object.position.invertedY, size: object.size)
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
