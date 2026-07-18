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
draw("by brAInwav", in: CGRect(x: 134, y: 780, width: 160, height: 20), font: font(size: 12, weight: .medium), color: color(0x6d6b66), tracking: 0.25)

draw("OPENAI HACKATHON · BUILT WITH CODEX", in: CGRect(x: 62, y: 691, width: 510, height: 22), font: font(name: "SFMono-Semibold", size: 12, weight: .semibold), color: color(0x55575b), tracking: 1.3)
draw("When evidence\ngoes stale.", in: CGRect(x: 58, y: 350, width: 600, height: 310), font: font(name: "SF Pro Display", size: 92, weight: .bold), color: paperInk, lineHeight: 91, tracking: -4.2)
draw("A changed Skill can still look healthy when its registry score belongs to yesterday’s candidate.", in: CGRect(x: 62, y: 236, width: 548, height: 90), font: font(size: 23, weight: .regular), color: color(0x4f5155), lineHeight: 33)
draw("CONCEPT MOCKUP · NOT RUNTIME EVIDENCE", in: CGRect(x: 62, y: 64, width: 470, height: 22), font: font(name: "SFMono-Regular", size: 11), color: color(0x6f6c67), tracking: 1.25)

let technicalX: CGFloat = 720
draw("SKILLS SDK · LOCAL · v0.2.0", in: CGRect(x: technicalX + 62, y: 815, width: 380, height: 20), font: font(name: "SFMono-Semibold", size: 12, weight: .semibold), color: muted, tracking: 1.1)
draw("jscraik/improve-agent-native", in: CGRect(x: technicalX + 62, y: 779, width: 520, height: 30), font: font(size: 22, weight: .semibold), color: ink)
draw("LOCAL CANDIDATE CHANGED", in: CGRect(x: technicalX + 62, y: 718, width: 320, height: 22), font: font(name: "SFMono-Semibold", size: 12, weight: .semibold), color: orange, tracking: 1.2)
draw("canonical digest missing", in: CGRect(x: 1440, y: 718, width: 220, height: 22), font: font(name: "SFMono-Regular", size: 12), color: muted, alignment: .right)

let trackY: CGFloat = 648
let trackStart: CGFloat = technicalX + 72
let trackEnd: CGFloat = 1660
line(from: CGPoint(x: trackStart, y: trackY), to: CGPoint(x: trackEnd, y: trackY), color: rule, width: 2)
line(from: CGPoint(x: trackStart, y: trackY), to: CGPoint(x: trackStart + 72, y: trackY), color: orange, width: 5)
fill(CGRect(x: trackStart + 64, y: trackY - 8, width: 16, height: 16), orange, radius: 8)
draw("CANDIDATE", in: CGRect(x: trackStart, y: trackY + 16, width: 140, height: 18), font: font(name: "SFMono-Regular", size: 10), color: muted, tracking: 1)
draw("REQUIRED", in: CGRect(x: trackStart + 35, y: trackY - 35, width: 100, height: 18), font: font(name: "SFMono-Semibold", size: 10), color: orange, alignment: .center, tracking: 1)
draw("HUMAN DECISION", in: CGRect(x: 1510, y: trackY + 16, width: 150, height: 18), font: font(name: "SFMono-Regular", size: 10), color: muted, alignment: .right, tracking: 1)

let cards: [(String, String, CGFloat, CGFloat)] = [
    ("01", "Build", 782, 248),
    ("02", "Prove", 1048, 318),
    ("03", "Ship", 1384, 276),
]
for (number, title, x, width) in cards {
    let rect = CGRect(x: x, y: 322, width: width, height: 245)
    fill(rect, surface, radius: 18)
    stroke(rect, rule, radius: 18, width: 2)
    fill(CGRect(x: x + 20, y: 504, width: 38, height: 38), color(0x1d2127), radius: 19)
    stroke(CGRect(x: x + 20, y: 504, width: 38, height: 38), color(0x4a515c), radius: 19)
    draw(number, in: CGRect(x: x + 20, y: 516, width: 38, height: 16), font: font(name: "SFMono-Semibold", size: 10), color: blue, alignment: .center)
    draw(title, in: CGRect(x: x + 72, y: 503, width: width - 94, height: 38), font: font(size: 27, weight: .semibold), color: ink)
}

draw("1  Candidate identity", in: CGRect(x: 806, y: 437, width: 200, height: 26), font: font(size: 16, weight: .semibold), color: color(0xffc15a))
draw("digest missing", in: CGRect(x: 806, y: 405, width: 190, height: 24), font: font(name: "SFMono-Semibold", size: 12), color: orange)
draw("2  Mechanical validation", in: CGRect(x: 806, y: 362, width: 210, height: 24), font: font(size: 14, weight: .medium), color: muted)

let proveRows = ["3  Security & guardrails", "4  Eval preparation", "5  Eval local proof", "6  Eval cloud proof"]
for (index, row) in proveRows.enumerated() {
    draw(row, in: CGRect(x: 1072, y: 443 - CGFloat(index * 35), width: 250, height: 24), font: font(size: 14, weight: .medium), color: muted)
}
let shipRows = ["7  Tessl staging", "8  Publication & registry", "9  Runtime truth"]
for (index, row) in shipRows.enumerated() {
    draw(row, in: CGRect(x: 1408, y: 433 - CGFloat(index * 43), width: 225, height: 26), font: font(size: 14, weight: .medium), color: muted)
}

let verdict = CGRect(x: technicalX + 62, y: 154, width: 885, height: 112)
fill(verdict, color(0x18130c), radius: 15)
stroke(verdict, color(0x74501c), radius: 15, width: 2)
draw("CANDIDATE IDENTITY REQUIRED", in: CGRect(x: verdict.minX + 22, y: verdict.maxY - 43, width: 360, height: 22), font: font(name: "SFMono-Semibold", size: 12), color: orange, tracking: 1)
draw("Downstream proof held", in: CGRect(x: verdict.minX + 22, y: verdict.minY + 25, width: 360, height: 35), font: font(size: 24, weight: .semibold), color: ink)
draw("registry baseline remains separate", in: CGRect(x: verdict.maxX - 350, y: verdict.minY + 34, width: 326, height: 22), font: font(name: "SFMono-Regular", size: 11), color: muted, alignment: .right)

draw("current candidate · observed baseline separate · release decision human", in: CGRect(x: technicalX + 62, y: 70, width: 885, height: 22), font: font(name: "SFMono-Regular", size: 10), color: muted, alignment: .right, tracking: 0.8)

context?.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    throw CoverError.pngEncodingFailed
}
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL, options: .atomic)
print("GENERATED \(outputURL.path)")
