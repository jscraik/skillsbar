import AppKit
import Foundation
import Vision

let expected = "https://github.com/jscraik/skillsbar"
let paths = CommandLine.arguments.dropFirst()

guard !paths.isEmpty else {
    fputs("Usage: swift verify-skillsbar-qr.swift <png> [<png> ...]\n", stderr)
    exit(2)
}

for path in paths {
    let url = URL(fileURLWithPath: path)
    guard let image = NSImage(contentsOf: url),
          let imageData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: imageData),
          let cgImage = bitmap.cgImage
    else {
        fputs("FAIL \(url.lastPathComponent) could not load bitmap\n", stderr)
        exit(1)
    }

    var decoded = ""
    let request = VNDetectBarcodesRequest { request, _ in
        decoded = request.results?
            .compactMap { ($0 as? VNBarcodeObservation)?.payloadStringValue }
            .first ?? ""
    }
    request.usesCPUOnly = true
    request.symbologies = [.qr]
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    do {
        try handler.perform([request])
    } catch {
        fputs("FAIL \(url.lastPathComponent) decoder error: \(error)\n", stderr)
        exit(1)
    }

    guard decoded == expected else {
        fputs("FAIL \(url.lastPathComponent) decoded: \(decoded)\n", stderr)
        exit(1)
    }
    print("PASS \(url.lastPathComponent) \(decoded)")
}
