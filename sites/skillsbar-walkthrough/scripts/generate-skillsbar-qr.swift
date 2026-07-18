import Foundation

let scriptURL = URL(fileURLWithPath: #filePath)
let siteRoot = scriptURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let generatorURL = siteRoot
    .appendingPathComponent("scripts")
    .appendingPathComponent("generate-skillsbar-qr.mjs")
let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first
        ?? siteRoot.appendingPathComponent("public").path
)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["node", generatorURL.path, outputDirectory.path]
process.currentDirectoryURL = siteRoot

do {
    try process.run()
    process.waitUntilExit()
    exit(process.terminationStatus)
} catch {
    fputs("FAIL Could not run the project-local QR generator: \(error)\n", stderr)
    exit(1)
}
