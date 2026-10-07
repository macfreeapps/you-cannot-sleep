import AppKit
import Foundation

enum IconGenerationError: Error, CustomStringConvertible {
    case bitmapCreationFailed(Int)
    case pngEncodingFailed(URL)

    var description: String {
        switch self {
        case let .bitmapCreationFailed(size):
            return "Could not create a \(size) × \(size) bitmap."
        case let .pngEncodingFailed(url):
            return "Could not encode PNG at \(url.path)."
        }
    }
}

let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let assetRoot = repositoryRoot.appendingPathComponent("YouCannotSleep/Resources/Assets.xcassets")

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func polygon(_ points: [NSPoint]) -> NSBezierPath {
    let path = NSBezierPath()
    guard let first = points.first else { return path }
    path.move(to: first)
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    return path
}

func fill(_ path: NSBezierPath, with fillColor: NSColor) {
    fillColor.setFill()
    path.fill()
}

func stroke(_ path: NSBezierPath, with strokeColor: NSColor, width: CGFloat) {
    strokeColor.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func iconPNG(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw IconGenerationError.bitmapCreationFailed(size)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    graphics.imageInterpolation = .high
    graphics.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)

    let background = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 1024, height: 1024), xRadius: 225, yRadius: 225)
    let backdrop = NSGradient(colors: [color(0.10, 0.23, 0.35), color(0.035, 0.09, 0.17)])
    backdrop?.draw(in: background, angle: 90)

    // Two warm beams make the beacon read clearly at small sizes.
    fill(polygon([
        NSPoint(x: 454, y: 703), NSPoint(x: 477, y: 772), NSPoint(x: 92, y: 906), NSPoint(x: 92, y: 560)
    ]), with: color(1.0, 0.68, 0.27, alpha: 0.32))
    fill(polygon([
        NSPoint(x: 570, y: 703), NSPoint(x: 547, y: 772), NSPoint(x: 932, y: 906), NSPoint(x: 932, y: 560)
    ]), with: color(1.0, 0.68, 0.27, alpha: 0.32))

    // A few quiet stars add depth without competing with the lighthouse.
    for (x, y, radius): (CGFloat, CGFloat, CGFloat) in [(238, 776, 7), (786, 826, 6), (271, 648, 5), (760, 622, 5)] {
        fill(NSBezierPath(ovalIn: NSRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: color(0.92, 0.95, 0.96, alpha: 0.72))
    }

    // Lighthouse body.
    fill(polygon([
        NSPoint(x: 366, y: 166), NSPoint(x: 658, y: 166), NSPoint(x: 585, y: 620), NSPoint(x: 439, y: 620)
    ]), with: color(0.91, 0.93, 0.91))
    fill(polygon([
        NSPoint(x: 399, y: 378), NSPoint(x: 624, y: 378), NSPoint(x: 605, y: 490), NSPoint(x: 417, y: 490)
    ]), with: color(0.95, 0.37, 0.20))
    fill(polygon([
        NSPoint(x: 427, y: 205), NSPoint(x: 598, y: 205), NSPoint(x: 584, y: 292), NSPoint(x: 440, y: 292)
    ]), with: color(0.95, 0.37, 0.20))
    fill(NSBezierPath(roundedRect: NSRect(x: 475, y: 166, width: 74, height: 142), xRadius: 34, yRadius: 34), with: color(0.08, 0.19, 0.29))

    // Lantern room and roof.
    fill(polygon([
        NSPoint(x: 385, y: 616), NSPoint(x: 639, y: 616), NSPoint(x: 609, y: 654), NSPoint(x: 415, y: 654)
    ]), with: color(0.94, 0.95, 0.91))
    fill(NSBezierPath(roundedRect: NSRect(x: 420, y: 648, width: 184, height: 126), xRadius: 15, yRadius: 15), with: color(0.90, 0.93, 0.92))
    fill(NSBezierPath(roundedRect: NSRect(x: 447, y: 665, width: 130, height: 83), xRadius: 10, yRadius: 10), with: color(0.08, 0.19, 0.29))
    fill(NSBezierPath(ovalIn: NSRect(x: 474, y: 681, width: 76, height: 52)), with: color(1.0, 0.70, 0.27))
    fill(polygon([
        NSPoint(x: 380, y: 776), NSPoint(x: 644, y: 776), NSPoint(x: 607, y: 824), NSPoint(x: 417, y: 824)
    ]), with: color(0.95, 0.37, 0.20))
    fill(polygon([
        NSPoint(x: 460, y: 824), NSPoint(x: 564, y: 824), NSPoint(x: 546, y: 854), NSPoint(x: 478, y: 854)
    ]), with: color(0.94, 0.95, 0.91))

    // Simplified water lines anchor the tower and keep the silhouette legible.
    let water = color(0.66, 0.83, 0.87, alpha: 0.9)
    for (y, left, right): (CGFloat, CGFloat, CGFloat) in [(118, 212, 812), (76, 330, 694)] {
        let line = NSBezierPath()
        line.move(to: NSPoint(x: left, y: y))
        line.curve(to: NSPoint(x: right, y: y), controlPoint1: NSPoint(x: left + 90, y: y + 24), controlPoint2: NSPoint(x: right - 90, y: y - 22))
        stroke(line, with: water, width: 13)
    }

    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw IconGenerationError.pngEncodingFailed(assetRoot)
    }
    return data
}

func writePNG(_ data: Data, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}

let appIconFolder = assetRoot.appendingPathComponent("AppIcon.appiconset")
let iconFiles: [(String, Int)] = [
    ("icon-16.png", 16), ("icon-16@2x.png", 32),
    ("icon-32.png", 32), ("icon-32@2x.png", 64),
    ("icon-128.png", 128), ("icon-128@2x.png", 256),
    ("icon-256.png", 256), ("icon-256@2x.png", 512),
    ("icon-512.png", 512), ("icon-512@2x.png", 1024)
]

for (filename, size) in iconFiles {
    try writePNG(iconPNG(size: size), to: appIconFolder.appendingPathComponent(filename))
}
try writePNG(iconPNG(size: 256), to: assetRoot.appendingPathComponent("BeaconMark.imageset/beacon-mark.png"))
print("Generated \(iconFiles.count + 1) original lighthouse icon images.")
