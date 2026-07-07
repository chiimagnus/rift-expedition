#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Options {
    var input: URL?
    var output: URL?
    var rows = 4
    var columns = 12
    var sourceColumns: Int?
    var duplicateSourceColumn: Int?
    var cellSize = 96
    var trimAlpha = false
    var padding = 0
    var crop: CGRect?
    var autoGrid = false
    var selfTest = false
}

enum NormalizerError: Error, CustomStringConvertible {
    case usage(String)
    case unreadableImage(String)
    case invalidCanvas
    case writeFailed(String)

    var description: String {
        switch self {
        case let .usage(message):
            message
        case let .unreadableImage(path):
            "Unreadable image: \(path)"
        case .invalidCanvas:
            "Invalid rows, columns, or cell size"
        case let .writeFailed(path):
            "Could not write PNG: \(path)"
        }
    }
}

func parseOptions(_ arguments: [String]) throws -> Options {
    var options = Options()
    var index = 1
    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--self-test":
            options.selfTest = true
            index += 1
        case "--input":
            options.input = URL(filePath: try value(after: argument, in: arguments, index: &index))
        case "--output":
            options.output = URL(filePath: try value(after: argument, in: arguments, index: &index))
        case "--rows":
            options.rows = try intValue(after: argument, in: arguments, index: &index)
        case "--columns":
            options.columns = try intValue(after: argument, in: arguments, index: &index)
        case "--source-columns":
            options.sourceColumns = try intValue(after: argument, in: arguments, index: &index)
        case "--duplicate-source-column":
            options.duplicateSourceColumn = try intValue(after: argument, in: arguments, index: &index)
        case "--cell-size":
            options.cellSize = try intValue(after: argument, in: arguments, index: &index)
        case "--trim-alpha":
            options.trimAlpha = true
            index += 1
        case "--padding":
            options.padding = try intValue(after: argument, in: arguments, index: &index)
        case "--crop":
            options.crop = try cropValue(after: argument, in: arguments, index: &index)
        case "--auto-grid":
            options.autoGrid = true
            index += 1
        default:
            throw NormalizerError.usage("Unknown option: \(argument)")
        }
    }
    return options
}

func value(after option: String, in arguments: [String], index: inout Int) throws -> String {
    guard index + 1 < arguments.count else {
        throw NormalizerError.usage("Missing value for \(option)")
    }
    index += 2
    return arguments[index - 1]
}

func intValue(after option: String, in arguments: [String], index: inout Int) throws -> Int {
    let rawValue = try value(after: option, in: arguments, index: &index)
    guard let value = Int(rawValue) else {
        throw NormalizerError.usage("Invalid integer for \(option): \(rawValue)")
    }
    return value
}

func cropValue(after option: String, in arguments: [String], index: inout Int) throws -> CGRect {
    let rawValue = try value(after: option, in: arguments, index: &index)
    let parts = rawValue.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    guard parts.count == 4 else {
        throw NormalizerError.usage("Invalid crop for \(option): \(rawValue)")
    }
    return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
}

func normalize(image: CGImage, options: Options) throws -> CGImage {
    guard options.rows > 0, options.columns > 0, options.cellSize > 0 else {
        throw NormalizerError.invalidCanvas
    }

    let sourceRect = options.crop ?? CGRect(x: 0, y: 0, width: image.width, height: image.height)
    let sourceColumns = options.sourceColumns ?? options.columns
    let sourceCellWidth = sourceRect.width / CGFloat(sourceColumns)
    let sourceCellHeight = sourceRect.height / CGFloat(options.rows)
    let outputWidth = options.columns * options.cellSize
    let outputHeight = options.rows * options.cellSize

    guard let context = CGContext(
        data: nil,
        width: outputWidth,
        height: outputHeight,
        bitsPerComponent: 8,
        bytesPerRow: outputWidth * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NormalizerError.invalidCanvas
    }
    context.clear(CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))
    context.interpolationQuality = .high

    if options.autoGrid {
        return try normalizeAutoGrid(image: image, options: options, context: context)
    }

    for row in 0..<options.rows {
        for column in 0..<options.columns {
            let sourceColumn = sourceColumn(forOutputColumn: column, sourceColumns: sourceColumns, options: options)
            let cellRect = CGRect(
                x: sourceRect.minX + CGFloat(sourceColumn) * sourceCellWidth,
                y: sourceRect.minY + CGFloat(row) * sourceCellHeight,
                width: sourceCellWidth,
                height: sourceCellHeight
            ).integral
            guard let cellImage = image.cropping(to: cellRect) else { continue }
            let contentRect = options.trimAlpha ? alphaBounds(in: cellImage) : CGRect(x: 0, y: 0, width: cellImage.width, height: cellImage.height)
            guard !contentRect.isNull, let contentImage = cellImage.cropping(to: contentRect.integral) else { continue }
            let destination = fittedRect(
                contentSize: CGSize(width: contentImage.width, height: contentImage.height),
                row: row,
                column: column,
                options: options
            )
            context.draw(contentImage, in: destination)
        }
    }

    guard let normalized = context.makeImage() else {
        throw NormalizerError.invalidCanvas
    }
    return normalized
}

struct PixelBuffer {
    var width: Int
    var height: Int
    var pixels: [UInt8]

    func alphaAt(x: Int, y: Int) -> UInt8 {
        pixels[(y * width + x) * 4 + 3]
    }
}

struct Band {
    var start: Int
    var end: Int

    var midpoint: Int {
        (start + end) / 2
    }
}

func normalizeAutoGrid(image: CGImage, options: Options, context: CGContext) throws -> CGImage {
    let buffer = try pixelBuffer(for: image)
    let sourceRect = options.crop ?? CGRect(x: 0, y: 0, width: image.width, height: image.height)
    let rowBands = try projectionBands(
        counts: alphaRowCounts(in: buffer, rect: sourceRect),
        offset: Int(sourceRect.minY),
        targetCount: options.rows,
        minimumCount: 20,
        mergeGap: 12,
        label: "rows"
    )

    for row in 0..<options.rows {
        let rowBand = rowBands[row]
        let rowRect = CGRect(
            x: sourceRect.minX,
            y: CGFloat(max(rowBand.start - 4, Int(sourceRect.minY))),
            width: sourceRect.width,
            height: CGFloat(min(rowBand.end + 4, Int(sourceRect.maxY)) - max(rowBand.start - 4, Int(sourceRect.minY)) + 1)
        )
        let columnBands = try projectionBands(
            counts: alphaColumnCounts(in: buffer, rect: rowRect),
            offset: Int(sourceRect.minX),
        targetCount: options.sourceColumns ?? options.columns,
            minimumCount: 8,
            mergeGap: 10,
            label: "columns in row \(row)"
        )

        for column in 0..<options.columns {
            let sourceColumn = sourceColumn(forOutputColumn: column, sourceColumns: columnBands.count, options: options)
            let columnBand = columnBands[sourceColumn]
            let cropRect = CGRect(
                x: CGFloat(max(columnBand.start - 4, Int(sourceRect.minX))),
                y: rowRect.minY,
                width: CGFloat(min(columnBand.end + 4, Int(sourceRect.maxX)) - max(columnBand.start - 4, Int(sourceRect.minX)) + 1),
                height: rowRect.height
            ).integral
            guard let cellImage = image.cropping(to: cropRect) else { continue }
            let contentRect = options.trimAlpha ? alphaBounds(in: cellImage) : CGRect(x: 0, y: 0, width: cellImage.width, height: cellImage.height)
            guard !contentRect.isNull, let contentImage = cellImage.cropping(to: contentRect.integral) else { continue }
            context.draw(contentImage, in: fittedRect(
                contentSize: CGSize(width: contentImage.width, height: contentImage.height),
                row: row,
                column: column,
                options: options
            ))
        }
    }

    guard let normalized = context.makeImage() else {
        throw NormalizerError.invalidCanvas
    }
    return normalized
}

func sourceColumn(forOutputColumn column: Int, sourceColumns: Int, options: Options) -> Int {
    guard
        sourceColumns < options.columns,
        let duplicateSourceColumn = options.duplicateSourceColumn
    else {
        return min(column, sourceColumns - 1)
    }
    if column <= duplicateSourceColumn {
        return column
    }
    if column == duplicateSourceColumn + 1 {
        return duplicateSourceColumn
    }
    return min(column - 1, sourceColumns - 1)
}

func pixelBuffer(for image: CGImage) throws -> PixelBuffer {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NormalizerError.invalidCanvas
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return PixelBuffer(width: width, height: height, pixels: pixels)
}

func alphaRowCounts(in buffer: PixelBuffer, rect: CGRect) -> [Int] {
    let minX = max(Int(rect.minX), 0)
    let maxX = min(Int(rect.maxX), buffer.width)
    let minY = max(Int(rect.minY), 0)
    let maxY = min(Int(rect.maxY), buffer.height)
    return (minY..<maxY).map { y in
        (minX..<maxX).reduce(0) { count, x in
            count + (buffer.alphaAt(x: x, y: y) > 12 ? 1 : 0)
        }
    }
}

func alphaColumnCounts(in buffer: PixelBuffer, rect: CGRect) -> [Int] {
    let minX = max(Int(rect.minX), 0)
    let maxX = min(Int(rect.maxX), buffer.width)
    let minY = max(Int(rect.minY), 0)
    let maxY = min(Int(rect.maxY), buffer.height)
    return (minX..<maxX).map { x in
        (minY..<maxY).reduce(0) { count, y in
            count + (buffer.alphaAt(x: x, y: y) > 12 ? 1 : 0)
        }
    }
}

func projectionBands(
    counts: [Int],
    offset: Int,
    targetCount: Int,
    minimumCount: Int,
    mergeGap: Int,
    label: String
) throws -> [Band] {
    var bands: [Band] = []
    var start: Int?
    var lastActive: Int?

    for (index, count) in counts.enumerated() {
        if count >= minimumCount {
            if start == nil {
                start = index
            }
            lastActive = index
        } else if let currentStart = start, let currentEnd = lastActive, index - currentEnd > mergeGap {
            bands.append(Band(start: currentStart + offset, end: currentEnd + offset))
            start = nil
            lastActive = nil
        }
    }
    if let currentStart = start, let currentEnd = lastActive {
        bands.append(Band(start: currentStart + offset, end: currentEnd + offset))
    }

    while bands.count > targetCount {
        guard let mergeIndex = closestBandGapIndex(in: bands) else { break }
        let merged = Band(start: bands[mergeIndex].start, end: bands[mergeIndex + 1].end)
        bands.replaceSubrange(mergeIndex...(mergeIndex + 1), with: [merged])
    }

    guard bands.count == targetCount else {
        throw NormalizerError.usage("Auto-grid expected \(targetCount) \(label), found \(bands.count)")
    }
    return bands
}

func closestBandGapIndex(in bands: [Band]) -> Int? {
    guard bands.count > 1 else { return nil }
    return (0..<(bands.count - 1)).min { left, right in
        bands[left + 1].start - bands[left].end < bands[right + 1].start - bands[right].end
    }
}

func fittedRect(contentSize: CGSize, row: Int, column: Int, options: Options) -> CGRect {
    let maxSide = CGFloat(max(options.cellSize - options.padding * 2, 1))
    let scale = min(maxSide / contentSize.width, maxSide / contentSize.height)
    let width = contentSize.width * scale
    let height = contentSize.height * scale
    return CGRect(
        x: CGFloat(column * options.cellSize) + (CGFloat(options.cellSize) - width) / 2,
        y: CGFloat((options.rows - row - 1) * options.cellSize) + (CGFloat(options.cellSize) - height) / 2,
        width: width,
        height: height
    )
}

func alphaBounds(in image: CGImage) -> CGRect {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return .null
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1
    for y in 0..<height {
        for x in 0..<width {
            let alpha = pixels[(y * width + x) * 4 + 3]
            guard alpha > 0 else { continue }
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
    guard maxX >= minX, maxY >= minY else {
        return .null
    }
    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

func readImage(url: URL) throws -> CGImage {
    guard
        let data = try? Data(contentsOf: url),
        let source = CGImageSourceCreateWithData(data as CFData, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw NormalizerError.unreadableImage(url.path)
    }
    return image
}

func writePNG(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else {
        throw NormalizerError.writeFailed(url.path)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NormalizerError.writeFailed(url.path)
    }
}

func makeSelfTestImage(rows: Int, columns: Int, cellSize: Int) throws -> CGImage {
    let width = columns * cellSize
    let height = rows * cellSize
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NormalizerError.invalidCanvas
    }
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    for row in 0..<rows {
        for column in 0..<columns {
            let hue = CGFloat(row * columns + column) / CGFloat(rows * columns)
            context.setFillColor(NSColor(calibratedHue: hue, saturation: 0.8, brightness: 0.9, alpha: 1).cgColor)
            context.fill(CGRect(
                x: column * cellSize + 20,
                y: (rows - row - 1) * cellSize + 24,
                width: 42,
                height: 36
            ))
        }
    }
    guard let image = context.makeImage() else {
        throw NormalizerError.invalidCanvas
    }
    return image
}

func hasTransparentPixel(_ image: CGImage) -> Bool {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return false
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] == 0 }
}

func runSelfTest() throws {
    var options = Options()
    options.rows = 4
    options.columns = 12
    options.cellSize = 96
    options.trimAlpha = true
    options.padding = 4
    let source = try makeSelfTestImage(rows: options.rows, columns: options.columns, cellSize: options.cellSize)
    let normalized = try normalize(image: source, options: options)
    guard normalized.width == 1152, normalized.height == 384, hasTransparentPixel(normalized) else {
        throw NormalizerError.usage("Self-test failed")
    }
    print("self-test pass: output size \(normalized.width)x\(normalized.height)")
}

do {
    let options = try parseOptions(CommandLine.arguments)
    if options.selfTest {
        try runSelfTest()
        exit(EXIT_SUCCESS)
    }
    guard let input = options.input, let output = options.output else {
        throw NormalizerError.usage("Usage: normalize_sprite_sheet.swift --input <png> --output <png> [--rows 4] [--columns 12] [--source-columns 11] [--duplicate-source-column 7] [--cell-size 96] [--trim-alpha] [--padding 4] [--crop x,y,width,height] [--auto-grid] [--self-test]")
    }
    let image = try readImage(url: input)
    let normalized = try normalize(image: image, options: options)
    try writePNG(normalized, to: output)
    print("wrote \(output.path) \(normalized.width)x\(normalized.height)")
} catch {
    FileHandle.standardError.write((String(describing: error) + "\n").data(using: .utf8) ?? Data())
    exit(EXIT_FAILURE)
}
