import Foundation

public struct TiledMap: Equatable, Sendable {
    public var areaID: String
    public var width: Double
    public var height: Double
    public var objectGroups: [String: [TiledObject]]
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

    public var isValid: Bool {
        issues.isEmpty
    }

    public func reportMarkdown() -> String {
        var lines = ["# Map Validation: \(map.areaID)", ""]
        if issues.isEmpty {
            lines.append("No issues.")
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
        return maps.map { map in
            MapValidationResult(map: map, issues: collectIssues(in: map, spawnIndex: index))
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
            issues.append(MapValidationIssue(message: "npc object \(npc.tiledID) missing hitbox size: draw it as a rectangle with width/height in Tiled"))
        }

        for exit in map.objectGroups["exit", default: []] {
            guard
                let targetAreaID = exit.properties["targetAreaId"],
                let targetSpawnID = exit.properties["targetSpawnId"]
            else {
                continue
            }
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

        return issues
    }

    private static func spawnIndex(for maps: [TiledMap]) -> [String: Set<String>] {
        Dictionary(uniqueKeysWithValues: maps.map { map in
            (map.areaID, Set(map.objectGroups["spawn", default: []].compactMap { $0.properties["id"] }))
        })
    }
}

extension TiledObject {
    func contains(pointX: Double, y pointY: Double) -> Bool {
        pointX >= x && pointX <= x + width && pointY >= y && pointY <= y + height
    }
}

private final class TiledMapParser: NSObject, XMLParserDelegate {
    private var areaID = ""
    private var mapWidth = 0.0
    private var mapHeight = 0.0
    private var tileWidth = 1.0
    private var tileHeight = 1.0
    private var objectGroups: [String: [TiledObject]] = [:]
    private var currentGroup: String?
    private var currentObject: TiledObject?
    private var parseError: Error?

    static func parse(url: URL, areaID: String) throws -> TiledMap {
        guard let parser = XMLParser(contentsOf: url) else {
            throw MapValidationError.unreadable(url)
        }
        let delegate = TiledMapParser()
        delegate.areaID = areaID
        parser.delegate = delegate

        guard parser.parse() else {
            let message = parser.parserError.map { String(describing: $0) } ?? "unknown XML error"
            throw MapValidationError.xml(message)
        }
        if let parseError = delegate.parseError {
            throw parseError
        }
        return TiledMap(
            areaID: areaID,
            width: delegate.mapWidth * delegate.tileWidth,
            height: delegate.mapHeight * delegate.tileHeight,
            objectGroups: delegate.objectGroups
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
