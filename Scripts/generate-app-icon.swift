import AppKit
import Foundation

let arguments = CommandLine.arguments
let outputPath = arguments.dropFirst().first ?? "Resources/AppIcon.icns"
let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let outputURL = URL(fileURLWithPath: outputPath, relativeTo: rootURL)
let iconsetURL = rootURL.appendingPathComponent(".build/AppIcon.iconset")

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

struct IconImage {
    let filename: String
    let pixels: Int
}

let images = [
    IconImage(filename: "icon_16x16.png", pixels: 16),
    IconImage(filename: "icon_16x16@2x.png", pixels: 32),
    IconImage(filename: "icon_32x32.png", pixels: 32),
    IconImage(filename: "icon_32x32@2x.png", pixels: 64),
    IconImage(filename: "icon_128x128.png", pixels: 128),
    IconImage(filename: "icon_128x128@2x.png", pixels: 256),
    IconImage(filename: "icon_256x256.png", pixels: 256),
    IconImage(filename: "icon_256x256@2x.png", pixels: 512),
    IconImage(filename: "icon_512x512.png", pixels: 512),
    IconImage(filename: "icon_512x512@2x.png", pixels: 1024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawIcon(pixels: Int) throws -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [.alphaFirst],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "WindowCycleIcon", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(pixels)
    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    bounds.fill()

    let background = roundedRect(bounds.insetBy(dx: size * 0.075, dy: size * 0.075), radius: size * 0.19)
    let gradient = NSGradient(colors: [
        color(0.12, 0.42, 0.95),
        color(0.04, 0.74, 0.78)
    ])!
    gradient.draw(in: background, angle: 315)

    color(1, 1, 1, 0.20).setStroke()
    background.lineWidth = max(1, size * 0.018)
    background.stroke()

    let cardStroke = color(0.06, 0.16, 0.26, 0.26)
    let cardFill = color(1, 1, 1, 0.92)
    let shadow = NSShadow()
    shadow.shadowBlurRadius = size * 0.025
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.012)
    shadow.shadowColor = color(0, 0, 0, 0.22)

    func drawCard(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, alpha: CGFloat) {
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let path = roundedRect(rect, radius: size * 0.045)
        shadow.set()
        cardFill.withAlphaComponent(alpha).setFill()
        path.fill()
        NSShadow().set()
        cardStroke.setStroke()
        path.lineWidth = max(1, size * 0.012)
        path.stroke()
    }

    drawCard(
        x: size * 0.25,
        y: size * 0.50,
        width: size * 0.44,
        height: size * 0.26,
        alpha: 0.64
    )
    drawCard(
        x: size * 0.34,
        y: size * 0.39,
        width: size * 0.44,
        height: size * 0.26,
        alpha: 0.78
    )
    drawCard(
        x: size * 0.20,
        y: size * 0.28,
        width: size * 0.46,
        height: size * 0.28,
        alpha: 0.95
    )

    let arrowPath = NSBezierPath()
    arrowPath.move(to: CGPoint(x: size * 0.30, y: size * 0.37))
    arrowPath.curve(
        to: CGPoint(x: size * 0.63, y: size * 0.64),
        controlPoint1: CGPoint(x: size * 0.30, y: size * 0.61),
        controlPoint2: CGPoint(x: size * 0.52, y: size * 0.68)
    )
    color(1, 1, 1, 0.95).setStroke()
    arrowPath.lineWidth = max(2, size * 0.055)
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()

    let head = NSBezierPath()
    head.move(to: CGPoint(x: size * 0.65, y: size * 0.64))
    head.line(to: CGPoint(x: size * 0.54, y: size * 0.66))
    head.line(to: CGPoint(x: size * 0.62, y: size * 0.53))
    head.close()
    color(1, 1, 1, 0.95).setFill()
    head.fill()

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "WindowCycleIcon", code: 2)
    }
    return data
}

for image in images {
    let data = try drawIcon(pixels: image.pixels)
    try data.write(to: iconsetURL.appendingPathComponent(image.filename))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c", "icns",
    iconsetURL.path,
    "-o", outputURL.path
]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "WindowCycleIcon", code: Int(process.terminationStatus))
}

print("Generated \(outputURL.path)")
