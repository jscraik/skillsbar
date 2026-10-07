import AppKit
import Foundation

enum CoverError: Error {
    case bitmapCreationFailed
    case pngEncodingFailed
    case missingIcon
}

let canvas = CGSize(width: 1729, height: 910)
let outputPath = CommandLine.arguments.dropFirst().first ?? "public/og.png"
let outputURL = URL(fileURLWithPath: outputPath)
let iconURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("public/skillsbar-icon.png")

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width),
    pixelsHigh: Int(canvas.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .calibratedRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    throw CoverError.bitmapCreationFailed
}

guard let icon = NSImage(contentsOf: iconURL) else {
    throw CoverError.missingIcon
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func fill(_ rect: CGRect, _ fillColor: NSColor, radius: CGFloat = 0) {
    fillColor.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func stroke(_ rect: CGRect, _ strokeColor: NSColor, radius: CGFloat, width: CGFloat = 1) {
    strokeColor.setStroke()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    path.stroke()
}

func line(from: CGPoint, to: CGPoint, color lineColor: NSColor, width: CGFloat) {
    lineColor.setStroke()
    let path = NSBezierPath()
    path.move(to: from)
    path.line(to: to)
    path.lineWidth = width
    path.stroke()
}

func font(name: String? = nil, size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    if let name, let namedFont = NSFont(name: name, size: size) { return namedFont }
    return NSFont.systemFont(ofSize: size, weight: weight)
}

func draw(
    _ text: String,
    in rect: CGRect,
    font textFont: NSFont,
    color textColor: NSColor,
    alignment: NSTextAlignment = .left,
    lineHeight: CGFloat? = nil,
    tracking: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }
    (text as NSString).draw(
        in: rect,
        withAttributes: [
            .font: textFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph,
            .kern: tracking,
        ]
    )
}

let warm = color(0xeee9df)
let paperInk = color(0x191a1c)
let dark = color(0x090b0e)
let surface = color(0x121519)
let rule = color(0x30353d)
let ink = color(0xf5f3ee)
let secondary = color(0xaeb3bd)
let muted = color(0x757d89)
let blue = color(0x5b9cff)
let orange = color(0xffac18)

let context = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

fill(CGRect(origin: .zero, size: canvas), dark)
fill(CGRect(x: 0, y: 0, width: 720, height: canvas.height), warm)

icon.draw(in: CGRect(x: 62, y: 790, width: 52, height: 52))
draw("SkillsBar", in: CGRect(x: 132, y: 800, width: 220, height: 34), font: font(size: 25, weight: .semibold), color: paperInk)
draw("by jscraik", in: CGRect(x: 134, y: 780, width: 160, height: 20), font: font(size: 12, weight: .medium), color: color(0x6d6b66), tracking: 0.25)

draw("OPENAI HACKATHON · BUILT WITH CODEX", in: CGRect(x: 62, y: 691, width: 510, height: 22), font: font(name: "SFMono-Semibold", size: 12, weight: .semibold), color: color(0x55575b), tracking: 1.3)
draw("Know what your\nskill needs next.", in: CGRect(x: 58, y: 350, width: 600, height: 310), font: font(name: "SF Pro Display", size: 92, weight: .bold), color: paperInk, lineHeight: 91, tracking: -4.2)
draw("Inspect nine evidence gates, see what needs attention, and copy the next command.", in: CGRect(x: 62, y: 236, width: 548, height: 90), font: font(size: 23, weight: .regular), color: color(0x4f5155), lineHeight: 33)
draw("APP-RENDERED FIXTURE · NOT LIVE EVIDENCE", in: CGRect(x: 62, y: 64, width: 470, height: 22), font: font(name: "SFMono-Regular", size: 11), color: color(0x6f6c67), tracking: 1.25)

let captureURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("public/skillsbar-demo-render.png")
guard let capture = NSImage(contentsOf: captureURL) else { throw CoverError.missingIcon }
capture.draw(in: CGRect(x: 934, y: 84, width: 552, height: 703.2))
draw("NATIVE MACOS APP · NINE EVIDENCE GATES", in: CGRect(x: 840, y: 815, width: 760, height: 24), font: font(name: "SFMono-Semibold", size: 15), color: secondary, alignment: .center)
draw("SUPPORTED DEMO FIXTURE · APP-RENDERED SNAPSHOT", in: CGRect(x: 820, y: 36, width: 800, height: 22), font: font(name: "SFMono-Regular", size: 12), color: muted, alignment: .center)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    throw CoverError.pngEncodingFailed
}
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL, options: .atomic)
print("GENERATED \(outputURL.path)")
