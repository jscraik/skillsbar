import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum QRArtifactError: Error, CustomStringConvertible {
    case couldNotCreateImage
    case couldNotCreateBitmap
    case couldNotEncodePNG

    var description: String {
        switch self {
        case .couldNotCreateImage:
            return "Core Image did not produce a QR image."
        case .couldNotCreateBitmap:
            return "Could not create a bitmap for the QR image."
        case .couldNotEncodePNG:
            return "Could not encode the QR image as PNG."
        }
    }
}

let repositoryURL = "https://github.com/jscraik/skillsbar"
let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first
        ?? FileManager.default.currentDirectoryPath
)
let context = CIContext()

func makeQRCode(size: Int, filename: String) throws -> URL {
    let generator = CIFilter.qrCodeGenerator()
    generator.message = Data(repositoryURL.utf8)
    generator.correctionLevel = "H"

    guard let source = generator.outputImage else {
        throw QRArtifactError.couldNotCreateImage
    }

    let moduleScale = max(1, (size - 128) / Int(source.extent.width))
    guard let sourceImage = context.createCGImage(source, from: source.extent) else {
        throw QRArtifactError.couldNotCreateBitmap
    }

    let colorSpace = CGColorSpaceCreateDeviceGray()
    let rowBytes = size
    var pixels = Data(count: rowBytes * size)
    let renderedContext: CGContext? = pixels.withUnsafeMutableBytes {
        (buffer: UnsafeMutableRawBufferPointer) -> CGContext? in
        guard let baseAddress = buffer.baseAddress else { return nil }
        return CGContext(
            data: baseAddress,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: rowBytes,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
    }
    guard let bitmapContext = renderedContext else {
        throw QRArtifactError.couldNotCreateBitmap
    }

    bitmapContext.setFillColor(gray: 1, alpha: 1)
    bitmapContext.fill(CGRect(x: 0, y: 0, width: size, height: size))
    bitmapContext.interpolationQuality = CGInterpolationQuality.none
    let codeSize = CGFloat(Int(source.extent.width) * moduleScale)
    let origin = floor((CGFloat(size) - codeSize) / 2)
    bitmapContext.draw(
        sourceImage,
        in: CGRect(x: origin, y: origin, width: codeSize, height: codeSize)
    )

    guard let cgImage = bitmapContext.makeImage() else {
        throw QRArtifactError.couldNotCreateBitmap
    }
    let bitmap = NSBitmapImageRep(cgImage: cgImage)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw QRArtifactError.couldNotEncodePNG
    }

    let outputURL = outputDirectory.appendingPathComponent(filename)
    try data.write(to: outputURL, options: .atomic)
    return outputURL
}

do {
    try FileManager.default.createDirectory(
        at: outputDirectory,
        withIntermediateDirectories: true
    )
    let outputs = [
        try makeQRCode(size: 1024, filename: "skillsbar-repo-qr-1024.png"),
        try makeQRCode(size: 512, filename: "skillsbar-repo-qr-512.png"),
    ]

    for output in outputs {
        print("GENERATED \(output.lastPathComponent) \(repositoryURL)")
    }
} catch {
    fputs("FAIL \(error)\n", stderr)
    exit(1)
}
