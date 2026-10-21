import Foundation

/// Read-only inventory, not proof of host activation or SDK admission.
enum InstalledSkillDiscovery {
    struct MenuGroup: Identifiable {
        let id: String
        let title: String
        let paths: [String]
    }

    static func menuGroups(paths: [String]) -> [MenuGroup] {
        var entries: [String: [String]] = [:]
        var titles: [String: String] = [:]
        for path in Set(paths) {
            let identity: (key: String, title: String)
            if let range = path.range(of: "/.codex/plugins/cache/") {
                let parts = path[range.upperBound...].split(separator: "/")
                guard parts.count >= 3 else { continue }
                identity = ("3/\(parts[0])/\(parts[1])/\(parts[2])", "\(parts[1]) \(parts[2])")
            } else if path.contains("/.codex/skills/") {
                identity = ("1/codex", "Codex skills")
            } else if path.contains("/.agents/skills/") {
                identity = ("2/agents", "Shared agent skills")
            } else {
                identity = ("0/source", "Source checkout")
            }
            entries[identity.key, default: []].append(path)
            titles[identity.key] = identity.title
        }
        return entries.keys.sorted().map { key in
            MenuGroup(id: key, title: titles[key] ?? key, paths: (entries[key] ?? []).sorted {
                displayName(path: $0).localizedStandardCompare(displayName(path: $1)) == .orderedAscending
            })
        }
    }

    static func paths(home: URL) -> [String] {
        let manager = FileManager.default
        let standaloneRoots = [".codex/skills", ".codex/skills/.system", ".agents/skills"]
            .map { home.appendingPathComponent($0) }
        let cache = home.appendingPathComponent(".codex/plugins/cache")
        // Only inspect plugin skills, not bundled dependencies or assets.
        let pluginRoots = directories(in: cache).flatMap { provider in
            directories(in: provider).flatMap { plugin in
                directories(in: plugin).map { $0.appendingPathComponent("skills") }
            }
        }
        var visited = Set<String>()
        var seenFiles = Set<String>()
        var result: [String] = []
        func visit(_ directory: URL, depth: Int) {
            guard depth < 32 else { return }
            let resolved = directory.resolvingSymlinksInPath().standardizedFileURL
            guard visited.insert(resolved.path).inserted,
                  let children = try? manager.contentsOfDirectory(
                    at: directory, includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                    options: [.skipsHiddenFiles]
                  ) else { return }
            for child in children.sorted(by: { $0.path < $1.path }) {
                let target = child.resolvingSymlinksInPath().standardizedFileURL
                guard let values = try? target.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey]) else { continue }
                if child.lastPathComponent == "SKILL.md", values.isRegularFile == true {
                    if seenFiles.insert(target.path).inserted { result.append(child.standardizedFileURL.path) }
                } else if values.isDirectory == true {
                    visit(child, depth: depth + 1)
                }
            }
        }
        for directory in standaloneRoots + pluginRoots { visit(directory, depth: 0) }
        return result.sorted()
    }

    static func skillURL(path: String, root: URL) -> URL {
        path.hasPrefix("/") ? URL(fileURLWithPath: path) : root.appendingPathComponent(path)
    }

    static func displayName(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let name = url.deletingLastPathComponent().lastPathComponent
        if let range = path.range(of: "/.codex/plugins/cache/") {
            let components = path[range.upperBound...].split(separator: "/")
            if components.count >= 3 { return "\(name) · \(components[1]) \(components[2])" }
        }
        if path.contains("/.codex/skills/") { return "\(name) · Codex" }
        if path.contains("/.agents/skills/") { return "\(name) · Agents" }
        return name.isEmpty ? path : name
    }

    private static func directories(in parent: URL) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(
            at: parent, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        )) ?? []).filter {
            (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }.sorted { $0.path < $1.path }
    }
}
