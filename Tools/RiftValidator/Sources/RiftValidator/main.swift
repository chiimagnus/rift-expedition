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

    return Arguments(
        resourcesRoot: root,
        areaID: areaID,
        chapterID: chapterID ?? inferredChapterID(previewDirectory: previewDirectory, reportPath: reportPath),
        previewDirectory: previewDirectory,
        reportPath: reportPath
    )
}

func inferredChapterID(previewDirectory: URL?, reportPath: URL?) -> String? {
    let paths = [previewDirectory, reportPath].compactMap { $0?.pathComponents }
    for components in paths where components.contains("chapter1") {
        return "chapter1"
    }
    if reportPath?.lastPathComponent.contains("chapter1") == true {
        return "chapter1"
    }
    return nil
}

enum ValidationCLIError: Error, CustomStringConvertible {
    case usage
    case noMaps(URL)

    var description: String {
        switch self {
        case .usage:
            "Usage: RiftValidator <resourcesRoot> [--area <areaId>] [--chapter <chapterId>] [--write-preview <dir>] [--write-report <path>]"
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

func chapterAreaIDs(resourcesRoot: URL, chapterID: String?) throws -> Set<String>? {
    guard let chapterID else { return nil }
    let url = resourcesRoot.appending(path: "Data/worlds/\(chapterID).json")
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let graph = try JSONDecoder().decode(ChapterWorldGraph.self, from: Data(contentsOf: url))
    return Set(graph.areas.map(\.id))
}

func scopedMapResults(_ allResults: [MapValidationResult], chapterAreaIDs: Set<String>?) -> [MapValidationResult] {
    guard let chapterAreaIDs else { return allResults }
    return allResults.filter { chapterAreaIDs.contains($0.map.areaID) }
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
    let urls = try mapURLs(resourcesRoot: arguments.resourcesRoot, areaID: nil)
    let allResults = try MapValidator.validate(urls: urls)
    let chapterAreaIDs = try chapterAreaIDs(resourcesRoot: arguments.resourcesRoot, chapterID: arguments.chapterID)
    let scopedResults = scopedMapResults(allResults, chapterAreaIDs: chapterAreaIDs)
    let results = if let areaID = arguments.areaID {
        scopedResults.filter { $0.map.areaID == areaID }
    } else {
        scopedResults
    }
    let assetManifest = arguments.resourcesRoot.appending(path: "Assets/assets-manifest.json")
    let assetResult = FileManager.default.fileExists(atPath: assetManifest.path)
        ? try AssetValidator.validate(resourcesRoot: arguments.resourcesRoot)
        : nil
    let worldResults = try WorldGraphValidator.validateIfPresent(resourcesRoot: arguments.resourcesRoot, maps: allResults.map(\.map))
    let mapReferenceResult = try MapReferenceValidator.validateIfPresent(resourcesRoot: arguments.resourcesRoot, maps: allResults.map(\.map))
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
        "- 首章任务流程检查：\(chapterFlowResult == nil ? "未配置" : "已执行")",
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
