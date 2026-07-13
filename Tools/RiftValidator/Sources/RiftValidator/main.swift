import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

struct Arguments {
    var resourcesRoot: URL
    var areaID: String?
    var chapterID: String?
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
    var chapterID: String?
    var previewDirectory: URL?
    var reportPath: URL?

    while !args.isEmpty {
        let flag = args.removeFirst()
        guard !args.isEmpty else { throw ValidationCLIError.usage }
        let value = args.removeFirst()
        switch flag {
        case "--area":
            areaID = value
        case "--chapter":
            chapterID = value
        case "--write-preview":
            previewDirectory = URL(filePath: value)
        case "--write-report":
            reportPath = URL(filePath: value)
        default:
            throw ValidationCLIError.usage
        }
    }

    if areaID != nil, chapterID == nil {
        throw ValidationCLIError.areaRequiresChapter
    }

    return Arguments(
        resourcesRoot: root,
        areaID: areaID,
        chapterID: chapterID,
        previewDirectory: previewDirectory,
        reportPath: reportPath
    )
}

enum ValidationCLIError: Error, CustomStringConvertible {
    case usage
    case areaRequiresChapter
    case noMaps(URL)
    case unknownChapter(String, URL)
    case mismatchedChapterID(expected: String, actual: String, URL)
    case unknownArea(areaID: String, chapterID: String)
    case missingChapterMap(areaID: String, URL)
    case invalidChapterMapPath(areaID: String, String)

    var description: String {
        switch self {
        case .usage:
            "Usage: RiftValidator <resourcesRoot> [--chapter <chapterId> [--area <areaId>]] [--write-preview <dir>] [--write-report <path>]"
        case .areaRequiresChapter:
            "--area requires an explicit --chapter so cross-map exits and chapter references are validated in the correct scope"
        case let .noMaps(url):
            "No .tmx maps found under \(url.path)"
        case let .unknownChapter(chapterID, url):
            "Unknown chapter \(chapterID): missing world graph at \(url.path)"
        case let .mismatchedChapterID(expected, actual, url):
            "World graph ID mismatch at \(url.path): expected \(expected), found \(actual)"
        case let .unknownArea(areaID, chapterID):
            "Unknown area \(areaID) in chapter \(chapterID)"
        case let .missingChapterMap(areaID, url):
            "Chapter area \(areaID) references missing map at \(url.path)"
        case let .invalidChapterMapPath(areaID, mapPath):
            "Chapter area \(areaID) has invalid map path outside resources root: \(mapPath)"
        }
    }
}

func allMapURLs(mapsRoot: URL) throws -> [URL] {
    var result: [URL] = []
    var pending = [mapsRoot]
    let keys: Set<URLResourceKey> = [.isDirectoryKey, .isRegularFileKey]

    while let directory = pending.popLast() {
        let children = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        )
        for child in children {
            let values = try child.resourceValues(forKeys: keys)
            if values.isDirectory == true {
                pending.append(child)
            } else if values.isRegularFile == true, child.pathExtension == "tmx" {
                result.append(child)
            }
        }
    }
    return result.sorted { $0.path < $1.path }
}

func loadChapterGraph(resourcesRoot: URL, chapterID: String) throws -> ChapterWorldGraph {
    let url = resourcesRoot.appending(path: "Data/worlds/\(chapterID).json")
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw ValidationCLIError.unknownChapter(chapterID, url)
    }
    let graph = try JSONDecoder().decode(ChapterWorldGraph.self, from: Data(contentsOf: url))
    guard graph.id == chapterID else {
        throw ValidationCLIError.mismatchedChapterID(expected: chapterID, actual: graph.id, url)
    }
    return graph
}

func chapterMapURLs(resourcesRoot: URL, graph: ChapterWorldGraph, selectedAreaID: String?) throws -> [URL] {
    if let selectedAreaID, !graph.areas.contains(where: { $0.id == selectedAreaID }) {
        throw ValidationCLIError.unknownArea(areaID: selectedAreaID, chapterID: graph.id)
    }

    let rootPath = resourcesRoot.standardizedFileURL.path
    let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
    var urls: [URL] = []

    for area in graph.areas {
        let url = resourcesRoot.appending(path: area.mapPath).standardizedFileURL
        guard url.path.hasPrefix(rootPrefix) else {
            throw ValidationCLIError.invalidChapterMapPath(areaID: area.id, area.mapPath)
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationCLIError.missingChapterMap(areaID: area.id, url)
        }
        urls.append(url)
    }

    guard !urls.isEmpty else {
        throw ValidationCLIError.noMaps(resourcesRoot.appending(path: "Maps"))
    }
    return urls
}

func validationMapURLs(resourcesRoot: URL, chapterID: String?, areaID: String?) throws -> [URL] {
    if let chapterID {
        let graph = try loadChapterGraph(resourcesRoot: resourcesRoot, chapterID: chapterID)
        return try chapterMapURLs(resourcesRoot: resourcesRoot, graph: graph, selectedAreaID: areaID)
    }

    let mapsRoot = resourcesRoot.appending(path: "Maps")
    let maps = try allMapURLs(mapsRoot: mapsRoot)
    if maps.isEmpty {
        throw ValidationCLIError.noMaps(mapsRoot)
    }
    return maps
}

func reportedMapResults(_ allResults: [MapValidationResult], areaID: String?, chapterID: String?) throws -> [MapValidationResult] {
    guard let areaID else { return allResults }
    let results = allResults.filter { $0.map.areaID == areaID }
    guard !results.isEmpty else {
        throw ValidationCLIError.unknownArea(areaID: areaID, chapterID: chapterID ?? "<unspecified>")
    }
    return results
}

func scopeTitle(arguments: Arguments) -> String {
    if let areaID = arguments.areaID {
        return "区域 \(areaID)"
    }
    if arguments.chapterID == "chapter1" {
        return "首章全地图"
    }
    if let chapterID = arguments.chapterID {
        return "\(chapterID) 全地图"
    }
    return "全部地图"
}

do {
    let arguments = try parseArguments(CommandLine.arguments)
    let urls = try validationMapURLs(
        resourcesRoot: arguments.resourcesRoot,
        chapterID: arguments.chapterID,
        areaID: arguments.areaID
    )
    let scopedResults = try MapValidator.validate(urls: urls)
    let results = try reportedMapResults(
        scopedResults,
        areaID: arguments.areaID,
        chapterID: arguments.chapterID
    )
    let assetManifest = arguments.resourcesRoot.appending(path: "Assets/assets-manifest.json")
    let assetResult = FileManager.default.fileExists(atPath: assetManifest.path)
        ? try AssetValidator.validate(resourcesRoot: arguments.resourcesRoot)
        : nil
    let worldResults = try WorldGraphValidator.validateIfPresent(
        resourcesRoot: arguments.resourcesRoot,
        maps: scopedResults.map(\.map),
        worldID: arguments.chapterID
    )
    let mapReferenceResult = try MapReferenceValidator.validateIfPresent(
        resourcesRoot: arguments.resourcesRoot,
        maps: scopedResults.map(\.map)
    )
    let chapterFlowResult = try ChapterFlowValidator.validateIfPresent(
        resourcesRoot: arguments.resourcesRoot,
        maps: scopedResults.map(\.map),
        chapterID: arguments.chapterID
    )

    if let previewDirectory = arguments.previewDirectory {
        for result in results {
            try MapPreview.writePreview(for: result, to: previewDirectory)
        }
    }

    let mapIssueCount = results.reduce(0) { partial, result in
        partial + result.issues.count
    }
    let worldIssueCount = worldResults.reduce(0) { partial, result in
        partial + result.issues.count
    }
    let referenceIssueCount = mapReferenceResult?.issues.count ?? 0
    let assetIssueCount = assetResult?.issues.count ?? 0
    let chapterFlowIssueCount = chapterFlowResult?.issues.count ?? 0
    let issueCount = mapIssueCount + worldIssueCount + referenceIssueCount + assetIssueCount + chapterFlowIssueCount
    let scopeTitle = scopeTitle(arguments: arguments)
    let summary = [
        "# \(scopeTitle)校验总览",
        "",
        "- 地图数量：\(results.count)",
        "- 世界图谱检查：\(worldResults.isEmpty ? "未配置" : "已执行")",
        "- 地图数据引用检查：\(mapReferenceResult == nil ? "未配置" : "已执行")",
        "- 章节任务流程检查：\(chapterFlowResult == nil ? "未配置" : "已执行")",
        "- 资源授权检查：\(assetResult == nil ? "未配置" : "已执行")",
        "- 问题数量：\(issueCount)",
        "- 结论：\(issueCount == 0 ? "全部通过" : "存在问题，详见下方分项")",
        ""
    ].joined(separator: "\n")

    var reportSections = [summary]
    reportSections.append(contentsOf: results.map { $0.reportMarkdown() })
    reportSections.append(contentsOf: worldResults.map { $0.reportMarkdown() })
    if let mapReferenceResult {
        reportSections.append(mapReferenceResult.reportMarkdown())
    }
    if let chapterFlowResult {
        reportSections.append(chapterFlowResult.reportMarkdown())
    }
    if let assetResult {
        reportSections.append(assetResult.reportMarkdown())
    }
    let report = reportSections.joined(separator: "\n")
    if let reportPath = arguments.reportPath {
        try FileManager.default.createDirectory(at: reportPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try report.write(to: reportPath, atomically: true, encoding: String.Encoding.utf8)
    } else {
        print(report)
    }

    if issueCount > 0 {
        exit(EXIT_FAILURE)
    }
} catch {
    FileHandle.standardError.write((String(describing: error) + "\n").data(using: .utf8) ?? Data())
    exit(EXIT_FAILURE)
}
