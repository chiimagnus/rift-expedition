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
    var size: CGSize
    var navObstacles: [NavigationObstacle]
    var encounterTriggers: [MapEncounterTrigger]
}

struct NavigationObstacle: Equatable {
    var tiledID: Int
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

enum TiledMapLoader {
    @MainActor
    static func load(areaID: String, bundle: Bundle = .main) throws -> SKTilemap {
        let url = try mapURL(areaID: areaID, bundle: bundle)

        guard let tilemap = SKTilemap.load(tmxFile: url.path, loggingLevel: .none) else {
            throw TiledMapLoaderError.parseFailed(areaID: areaID)
        }

        tilemap.name = areaID
        return tilemap
    }

    static func loadMetadata(areaID: String, bundle: Bundle = .main) throws -> TiledMapMetadata {
        try loadMetadata(url: mapURL(areaID: areaID, bundle: bundle), areaID: areaID)
    }

    static func loadMetadata(url: URL, areaID: String) throws -> TiledMapMetadata {
        guard let parser = XMLParser(contentsOf: url) else {
            throw TiledMapLoaderError.unreadableMetadata(areaID: areaID)
        }

        let delegate = TiledMetadataParser(areaID: areaID)
        parser.delegate = delegate

        guard parser.parse() else {
            throw TiledMapLoaderError.invalidMetadata(areaID: areaID)
        }

        return delegate.metadata
    }

    private static func mapURL(areaID: String, bundle: Bundle) throws -> URL {
        if let url = bundle.url(forResource: areaID, withExtension: "tmx", subdirectory: "Maps") {
            return url
        }
        if let url = bundle.url(forResource: areaID, withExtension: "tmx") {
            return url
        }
        throw TiledMapLoaderError.missingResource(areaID: areaID)
    }
}

private final class TiledMetadataParser: NSObject, XMLParserDelegate {
    private let areaID: String
    private var mapWidth = 0.0
    private var mapHeight = 0.0
    private var tileWidth = 1.0
    private var tileHeight = 1.0
    private var currentGroup: String?
    private var currentObject: ParsedObject?
    private var navObstacles: [NavigationObstacle] = []
    private var encounterTriggers: [MapEncounterTrigger] = []

    var metadata: TiledMapMetadata {
        TiledMapMetadata(
            areaID: areaID,
            size: CGSize(width: mapWidth * tileWidth, height: mapHeight * tileHeight),
            navObstacles: navObstacles,
            encounterTriggers: encounterTriggers
        )
    }

    init(areaID: String) {
        self.areaID = areaID
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
            currentGroup = attributeDict["name"]
        case "object":
            currentObject = ParsedObject(
                tiledID: Int(attributeDict["id"] ?? "") ?? -1,
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
            if currentGroup == "navObstacle", let object = currentObject {
                navObstacles.append(NavigationObstacle(
                    tiledID: object.tiledID,
                    frame: CGRect(x: object.x, y: object.y, width: object.width, height: object.height),
                    blocksMovement: object.properties["blocksMovement"] == "true",
                    blocksSight: object.properties["blocksSight"] == "true"
                ))
            }
            if currentGroup == "encounter", let object = currentObject, let encounterID = object.properties["encounterId"] {
                encounterTriggers.append(MapEncounterTrigger(
                    tiledID: object.tiledID,
                    encounterID: encounterID,
                    frame: CGRect(x: object.x, y: object.y, width: object.width, height: object.height),
                    radius: CGFloat(Double(object.properties["radius"] ?? "") ?? 0)
                ))
            }
            currentObject = nil
        case "objectgroup":
            currentGroup = nil
        default:
            break
        }
    }
}

private struct ParsedObject {
    var tiledID: Int
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var properties: [String: String]
}
