import Foundation
import Darwin

struct Arguments {
    var resourcesRoot: URL
    var areaID: String?
    var previewDirectory: URL?
    var reportPath: URL?
}

func parseArguments(_ raw: [String]) throws -> Arguments {
    guard raw.count >= 2 else {
        throw ValidationCLIError.usage
    }

    var args = Array(raw.dropFirst())
    let root = URL(filePath: args.removeFirst())
    var areaID: String?
    var previewDirectory: URL?
    var reportPath: URL?

    while !args.isEmpty {
        let flag = args.removeFirst()
        guard !args.isEmpty else { throw ValidationCLIError.usage }
        let value = args.removeFirst()
        switch flag {
        case "--area":
            areaID = value
        case "--write-preview":
            previewDirectory = URL(filePath: value)
        case "--write-report":
            reportPath = URL(filePath: value)
        default:
            throw ValidationCLIError.usage
        }
    }

    return Arguments(resourcesRoot: root, areaID: areaID, previewDirectory: previewDirectory, reportPath: reportPath)
}

enum ValidationCLIError: Error, CustomStringConvertible {
    case usage
    case noMaps(URL)

    var description: String {
        switch self {
        case .usage:
            "Usage: RiftValidator <resourcesRoot> [--area <areaId>] [--write-preview <dir>] [--write-report <path>]"
        case let .noMaps(url):
            "No .tmx maps found under \(url.path)"
        }
    }
}

func mapURLs(resourcesRoot: URL, areaID: String?) throws -> [URL] {
    let mapsRoot = resourcesRoot.appending(path: "Maps")
    if let areaID {
        let url = try allMapURLs(mapsRoot: mapsRoot)
            .first { $0.deletingPathExtension().lastPathComponent == areaID }
        return [url ?? mapsRoot.appending(path: "\(areaID).tmx")]
    }

    let maps = try allMapURLs(mapsRoot: mapsRoot)
    if maps.isEmpty {
        throw ValidationCLIError.noMaps(mapsRoot)
    }
    return maps
}

func allMapURLs(mapsRoot: URL) throws -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
        at: mapsRoot,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    ) else {
        return []
    }

    return enumerator
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "tmx" }
        .sorted { $0.path < $1.path }
}

do {
    let arguments = try parseArguments(CommandLine.arguments)
    let urls = try mapURLs(resourcesRoot: arguments.resourcesRoot, areaID: nil)
    let allResults = try MapValidator.validate(urls: urls)
    let results = if let areaID = arguments.areaID {
        allResults.filter { $0.map.areaID == areaID }
    } else {
        allResults
    }
    let assetManifest = arguments.resourcesRoot.appending(path: "Assets/assets-manifest.json")
    let assetResult = FileManager.default.fileExists(atPath: assetManifest.path)
        ? try AssetValidator.validate(resourcesRoot: arguments.resourcesRoot)
        : nil
    let worldResults = try WorldGraphValidator.validateIfPresent(resourcesRoot: arguments.resourcesRoot, maps: allResults.map(\.map))
    let mapReferenceResult = try MapReferenceValidator.validateIfPresent(resourcesRoot: arguments.resourcesRoot, maps: allResults.map(\.map))

    if let previewDirectory = arguments.previewDirectory {
        for result in results {
            try MapPreview.writePreview(for: result, to: previewDirectory)
        }
    }

    var reportSections = results.map { $0.reportMarkdown() }
    reportSections.append(contentsOf: worldResults.map { $0.reportMarkdown() })
    if let mapReferenceResult {
        reportSections.append(mapReferenceResult.reportMarkdown())
    }
    if let assetResult {
        reportSections.append(assetResult.reportMarkdown())
    }
    let report = reportSections.joined(separator: "\n")
    if let reportPath = arguments.reportPath {
        try FileManager.default.createDirectory(at: reportPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try report.write(to: reportPath, atomically: true, encoding: .utf8)
    } else {
        print(report)
    }

    let issueCount = results.reduce(0) { $0 + $1.issues.count }
        + worldResults.reduce(0) { $0 + $1.issues.count }
        + (mapReferenceResult?.issues.count ?? 0)
        + (assetResult?.issues.count ?? 0)
    if issueCount > 0 {
        exit(EXIT_FAILURE)
    }
} catch {
    FileHandle.standardError.write((String(describing: error) + "\n").data(using: .utf8) ?? Data())
    exit(EXIT_FAILURE)
}
