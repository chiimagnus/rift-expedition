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
        return [mapsRoot.appending(path: "\(areaID).tmx")]
    }

    let contents = (try? FileManager.default.contentsOfDirectory(at: mapsRoot, includingPropertiesForKeys: nil)) ?? []
    let maps = contents.filter { $0.pathExtension == "tmx" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    if maps.isEmpty {
        throw ValidationCLIError.noMaps(mapsRoot)
    }
    return maps
}

do {
    let arguments = try parseArguments(CommandLine.arguments)
    let results = try mapURLs(resourcesRoot: arguments.resourcesRoot, areaID: arguments.areaID).map { url in
        try MapValidator.validate(url: url, areaID: arguments.areaID)
    }

    if let previewDirectory = arguments.previewDirectory {
        for result in results {
            try MapPreview.writePreview(for: result, to: previewDirectory)
        }
    }

    let report = results.map { $0.reportMarkdown() }.joined(separator: "\n")
    if let reportPath = arguments.reportPath {
        try FileManager.default.createDirectory(at: reportPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try report.write(to: reportPath, atomically: true, encoding: .utf8)
    } else {
        print(report)
    }

    let issueCount = results.reduce(0) { $0 + $1.issues.count }
    if issueCount > 0 {
        exit(EXIT_FAILURE)
    }
} catch {
    FileHandle.standardError.write((String(describing: error) + "\n").data(using: .utf8) ?? Data())
    exit(EXIT_FAILURE)
}
