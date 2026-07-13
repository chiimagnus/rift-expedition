import Foundation
import FoundationXML

public struct TiledImageLayer: Equatable, Sendable {
    public var id: Int
    public var name: String
    public var x: Double
    public var y: Double
    public var visible: Bool
    public var source: String
    public var width: Double
    public var height: Double

    public init(
        id: Int,
        name: String,
        x: Double = 0,
        y: Double = 0,
        visible: Bool = true,
        source: String,
        width: Double,
        height: Double
    ) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.visible = visible
        self.source = source
        self.width = width
        self.height = height
    }
}

public struct TiledMap: Equatable, Sendable {
    public var areaID: String
    public var width: Double
    public var height: Double
    public var objectGroups: [String: [TiledObject]]
    public var imageLayers: [TiledImageLayer]
    public var sourceURL: URL?

    public init(
        areaID: String,
        width: Double,
        height: Double,
        objectGroups: [String: [TiledObject]],
        imageLayers: [TiledImageLayer] = [],
        sourceURL: URL? = nil
    ) {
        self.areaID = areaID
        self.width = width
        self.height = height
        self.objectGroups = objectGroups
        self.imageLayers = imageLayers
        self.sourceURL = sourceURL
    }
}

public struct TiledObject: Equatable, Sendable {
    public var tiledID: Int
    public var name: String?
    public var type: String?
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var properties: [String: String]
}

public struct MapValidationIssue: Equatable, Sendable {
    public var message: String
}

public struct MapValidationResult: Equatable, Sendable {
    public var map: TiledMap
    public var issues: [MapValidationIssue]

    public var isValid: Bool { issues.isEmpty }

    public func reportMarkdown() -> String {
        var lines = ["# Map Validation: \(map.areaID)", ""]
        if map.imageLayers.isEmpty {
            lines.append("- Art layers: none")
        } else {
            lines.append("- Art layers: \(map.imageLayers.map(\.name).joined(separator: ", "))")
        }
        if issues.isEmpty {
            lines.append("- Validation: passed")
        } else {
            for issue in issues {
                lines.append("- \(issue.message)")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

public enum MapValidationError: Error, CustomStringConvertible {
    case unreadable(URL)
    case xml(String)

    public var description: String {
        switch self {
        case let .unreadable(url):
            "Unreadable TMX: \(url.path)"
        case let .xml(message):
            "TMX parse failed: \(message)"
        }
    }
}

public enum MapValidator {
    public static let requiredProperties: [String: [String]] = [
        "spawn": ["id"],
        "npc": ["actorId", "dialogId"],
        "encounter": ["encounterId", "radius"],
        "trigger": ["triggerId", "action"],
        "exit": ["targetAreaId", "targetSpawnId"],
        "navObstacle": ["blocksMovement", "blocksSight"],
        "surface": ["surfaceType"],
        "item": ["itemId"]
    ]

    public static func validate(url: URL, areaID: String? = nil) throws -> MapValidationResult {
        let map = try TiledMapParser.parse(url: url, areaID: areaID ?? url.deletingPathExtension().lastPathComponent)
        return MapValidationResult(map: map, issues: collectIssues(in: map, spawnIndex: spawnIndex(for: [map])))
    }

    public static func validate(urls: [URL]) throws -> [MapValidationResult] {
        let maps = try urls.map { url in
            try TiledMapParser.parse(url: url, areaID: url.deletingPathExtension().lastPathComponent)
        }
        let index = spawnIndex(for: maps)
        let duplicateAreaIDs = Set(Dictionary(grouping: maps, by: \.areaID)
            .filter { $0.value.count > 1 }
            .keys)
        return maps.map { map in
            var issues = collectIssues(in: map, spawnIndex: index)
            if duplicateAreaIDs.contains(map.areaID) {
                issues.append(MapValidationIssue(message: "Duplicate map area id: \(map.areaID)"))
            }
            return MapValidationResult(map: map, issues: issues)
        }
    }

    private static func collectIssues(in map: TiledMap, spawnIndex: [String: Set<String>]) -> [MapValidationIssue] {
        var issues: [MapValidationIssue] = []

        for layer in requiredProperties.keys.sorted() where map.objectGroups[layer] == nil {
            issues.append(MapValidationIssue(message: "Missing object layer: \(layer)"))
        }

        var seenObjectIDs: Set<Int> = []
        for objects in map.objectGroups.values {
            for object in objects where !seenObjectIDs.insert(object.tiledID).inserted {
                issues.append(MapValidationIssue(message: "Duplicate Tiled object id: \(object.tiledID)"))
            }
        }

        for (layer, properties) in requiredProperties {
            for object in map.objectGroups[layer, default: []] {
                for property in properties where object.properties[property]?.isEmpty ?? true {
                    issues.append(MapValidationIssue(message: "\(layer) object \(object.tiledID) missing property: \(property)"))
                }
            }
        }

        for npc in map.objectGroups["npc", default: []] where npc.width <= 0 || npc.height <= 0 {
            issues.append(MapValidationIssue(message: "npc object \(npc.tiledID) missing hitbox size: draw it as a rectangle with width/height"))
        }

        for exit in map.objectGroups["exit", default: []] {
            guard let targetAreaID = exit.properties["targetAreaId"],
                  let targetSpawnID = exit.properties["targetSpawnId"] else { continue }
            if !(spawnIndex[targetAreaID]?.contains(targetSpawnID) ?? false) {
                issues.append(MapValidationIssue(message: "exit object \(exit.tiledID) targets missing spawn: \(targetAreaID).\(targetSpawnID)"))
            }
        }

        let movementObstacles = map.objectGroups["navObstacle", default: []]
            .filter { $0.properties["blocksMovement"] == "true" }
        for spawn in map.objectGroups["spawn", default: []] {
            if movementObstacles.contains(where: { $0.contains(pointX: spawn.x, y: spawn.y) }) {
                issues.append(MapValidationIssue(message: "spawn object \(spawn.tiledID) is inside movement obstacle"))
            }
        }

        for layerName in ["npc", "item", "encounter", "trigger"] {
            for object in map.objectGroups[layerName, default: []] {
                let pointX = object.width > 0 ? object.x + object.width / 2 : object.x
                let pointY = object.height > 0 ? object.y + object.height / 2 : object.y
                if movementObstacles.contains(where: { $0.contains(pointX: pointX, y: pointY) }) {
                    issues.append(MapValidationIssue(
                        message: "\(layerName) object \(object.tiledID) center is inside movement obstacle"
                    ))
                }
            }
        }

        issues.append(contentsOf: imageLayerIssues(in: map))
        issues.append(contentsOf: reachabilityIssues(in: map))
        return issues
    }

    private static func imageLayerIssues(in map: TiledMap) -> [MapValidationIssue] {
        var issues: [MapValidationIssue] = []
        var seenNames: Set<String> = []

        for layer in map.imageLayers {
            if !seenNames.insert(layer.name).inserted {
                issues.append(MapValidationIssue(message: "Duplicate image layer name: \(layer.name)"))
            }
            guard layer.name == "background_art" || layer.name.hasPrefix("foreground_") else { continue }
            if layer.source.isEmpty {
                issues.append(MapValidationIssue(message: "Image layer \(layer.name) has no source"))
            }
            if layer.width != map.width || layer.height != map.height {
                issues.append(MapValidationIssue(
                    message: "Image layer \(layer.name) must match map size \(Int(map.width))x\(Int(map.height)), got \(Int(layer.width))x\(Int(layer.height))"
                ))
            }
            if layer.x != 0 || layer.y != 0 {
                issues.append(MapValidationIssue(message: "Image layer \(layer.name) must start at 0,0"))
            }
            if !layer.visible {
                issues.append(MapValidationIssue(message: "Image layer \(layer.name) is hidden"))
            }
            if let sourceURL = map.sourceURL {
                let resolved = URL(filePath: layer.source, relativeTo: sourceURL.deletingLastPathComponent()).standardizedFileURL
                if !FileManager.default.fileExists(atPath: resolved.path) {
                    issues.append(MapValidationIssue(message: "Image layer \(layer.name) file is missing: \(layer.source)"))
                }
            }
        }
        return issues
    }

    private static func reachabilityIssues(in map: TiledMap) -> [MapValidationIssue] {
        let spawns = map.objectGroups["spawn", default: []]
        guard let firstSpawn = spawns.first else { return [] }

        let cellSize = 16.0
        let agentPadding = 8.0
        let columns = max(Int(ceil(map.width / cellSize)), 1)
        let rows = max(Int(ceil(map.height / cellSize)), 1)
        let obstacles = map.objectGroups["navObstacle", default: []]
            .filter { $0.properties["blocksMovement"] == "true" }

        func isBlocked(_ point: GridPoint) -> Bool {
            let x = (Double(point.x) + 0.5) * cellSize
            let y = (Double(point.y) + 0.5) * cellSize
            if x < 0 || y < 0 || x >= map.width || y >= map.height { return true }
            return obstacles.contains { obstacle in
                x >= obstacle.x - agentPadding
                    && x <= obstacle.x + obstacle.width + agentPadding
                    && y >= obstacle.y - agentPadding
                    && y <= obstacle.y + obstacle.height + agentPadding
            }
        }

        func gridPoint(x: Double, y: Double) -> GridPoint {
            GridPoint(
                x: min(max(Int(x / cellSize), 0), columns - 1),
                y: min(max(Int(y / cellSize), 0), rows - 1)
            )
        }

        func nearestOpen(to requested: GridPoint) -> GridPoint? {
            if !isBlocked(requested) { return requested }
            for radius in 1...4 {
                for dx in -radius...radius {
                    for dy in -radius...radius where abs(dx) == radius || abs(dy) == radius {
                        let candidate = GridPoint(x: requested.x + dx, y: requested.y + dy)
                        guard candidate.x >= 0, candidate.y >= 0, candidate.x < columns, candidate.y < rows else { continue }
                        if !isBlocked(candidate) { return candidate }
                    }
                }
            }
            return nil
        }

        guard let start = nearestOpen(to: gridPoint(x: firstSpawn.x, y: firstSpawn.y)) else {
            return [MapValidationIssue(message: "No navigable cell near first spawn")]
        }

        var visited: Set<GridPoint> = [start]
        var queue = [start]
        var readIndex = 0
        let directions = [GridPoint(x: 1, y: 0), GridPoint(x: -1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 0, y: -1)]
        while readIndex < queue.count {
            let current = queue[readIndex]
            readIndex += 1
            for direction in directions {
                let next = GridPoint(x: current.x + direction.x, y: current.y + direction.y)
                guard next.x >= 0, next.y >= 0, next.x < columns, next.y < rows else { continue }
                guard !isBlocked(next), visited.insert(next).inserted else { continue }
                queue.append(next)
            }
        }

        var issues: [MapValidationIssue] = []
        let spawnTargets = spawns.dropFirst().map { spawn in
            (label: "spawn \(spawn.properties["id"] ?? String(spawn.tiledID))", x: spawn.x, y: spawn.y)
        }
        let exitTargets = map.objectGroups["exit", default: []].map { exit in
            (
                label: "exit \(exit.properties["targetAreaId"] ?? String(exit.tiledID))",
                x: exit.x + exit.width / 2,
                y: exit.y + exit.height / 2
            )
        }
        for target in spawnTargets + exitTargets {
            guard let openTarget = nearestOpen(to: gridPoint(x: target.x, y: target.y)), visited.contains(openTarget) else {
                issues.append(MapValidationIssue(message: "Unreachable \(target.label) from first spawn"))
                continue
            }
        }
        return issues
    }

    private static func spawnIndex(for maps: [TiledMap]) -> [String: Set<String>] {
        Dictionary(grouping: maps, by: \.areaID).mapValues { maps in
            Set(maps.flatMap { $0.objectGroups["spawn", default: []].compactMap { $0.properties["id"] } })
        }
    }
}

extension TiledObject {
    func contains(pointX: Double, y pointY: Double) -> Bool {
        pointX >= x && pointX <= x + width && pointY >= y && pointY <= y + height
    }
}

private struct GridPoint: Hashable {
    var x: Int
    var y: Int
}

private final class TiledMapParser: NSObject, XMLParserDelegate {
    private var areaID = ""
    private var sourceURL: URL?
    private var mapWidth = 0.0
    private var mapHeight = 0.0
    private var tileWidth = 1.0
    private var tileHeight = 1.0
    private var objectGroups: [String: [TiledObject]] = [:]
    private var imageLayers: [TiledImageLayer] = []
    private var currentGroup: String?
    private var currentObject: TiledObject?
    private var currentImageLayer: TiledImageLayer?
    private var parseError: Error?

    static func parse(url: URL, areaID: String) throws -> TiledMap {
        guard let parser = XMLParser(contentsOf: url) else {
            throw MapValidationError.unreadable(url)
        }
        let delegate = TiledMapParser()
        delegate.areaID = areaID
        delegate.sourceURL = url
        parser.delegate = delegate

        guard parser.parse() else {
            let message = parser.parserError.map { String(describing: $0) } ?? "unknown XML error"
            throw MapValidationError.xml(message)
        }
        if let parseError = delegate.parseError { throw parseError }
        return TiledMap(
            areaID: areaID,
            width: delegate.mapWidth * delegate.tileWidth,
            height: delegate.mapHeight * delegate.tileHeight,
            objectGroups: delegate.objectGroups,
            imageLayers: delegate.imageLayers,
            sourceURL: url
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "map":
            mapWidth = Double(attributeDict["width"] ?? "") ?? 0
            mapHeight = Double(attributeDict["height"] ?? "") ?? 0
            tileWidth = Double(attributeDict["tilewidth"] ?? "") ?? 1
            tileHeight = Double(attributeDict["tileheight"] ?? "") ?? 1
        case "imagelayer":
            currentImageLayer = TiledImageLayer(
                id: Int(attributeDict["id"] ?? "") ?? -1,
                name: attributeDict["name"] ?? "",
                x: Double(attributeDict["x"] ?? "") ?? 0,
                y: Double(attributeDict["y"] ?? "") ?? 0,
                visible: attributeDict["visible"] != "0",
                source: "",
                width: 0,
                height: 0
            )
        case "image":
            guard currentImageLayer != nil else { return }
            currentImageLayer?.source = attributeDict["source"] ?? ""
            currentImageLayer?.width = Double(attributeDict["width"] ?? "") ?? 0
            currentImageLayer?.height = Double(attributeDict["height"] ?? "") ?? 0
        case "objectgroup":
            let name = attributeDict["name"] ?? ""
            currentGroup = name
            objectGroups[name, default: []] = objectGroups[name, default: []]
        case "object":
            currentObject = TiledObject(
                tiledID: Int(attributeDict["id"] ?? "") ?? -1,
                name: attributeDict["name"],
                type: attributeDict["type"],
                x: Double(attributeDict["x"] ?? "") ?? 0,
                y: Double(attributeDict["y"] ?? "") ?? 0,
                width: Double(attributeDict["width"] ?? "") ?? 0,
                height: Double(attributeDict["height"] ?? "") ?? 0,
                properties: [:]
            )
        case "property":
            guard currentObject != nil, let name = attributeDict["name"] else { return }
            currentObject?.properties[name] = attributeDict["value"] ?? ""
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "imagelayer":
            if let currentImageLayer { imageLayers.append(currentImageLayer) }
            currentImageLayer = nil
        case "object":
            if let currentGroup, let currentObject {
                objectGroups[currentGroup, default: []].append(currentObject)
            }
            currentObject = nil
        case "objectgroup":
            currentGroup = nil
        default:
            break
        }
    }
}
