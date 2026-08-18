// On-device persistence: your equations are still there next launch.
//
// ponytail: a plain JSON array of {source, colorIndex} in Application Support. The compiled
// form is derived on load, so nothing stale can be persisted.

import Foundation

enum Store {
    private struct Saved: Codable {
        let source: String
        let colorIndex: Int
    }

    private static var fileURL: URL? {
        guard let dir = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else { return nil }
        return dir.appendingPathComponent("equations.json")
    }

    static func load() -> [Equation]? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([Saved].self, from: data),
              !saved.isEmpty else { return nil }
        return saved.map { Equation(source: $0.source, colorIndex: $0.colorIndex) }
    }

    static func save(_ equations: [Equation]) {
        guard let url = fileURL else { return }
        let saved = equations.map { Saved(source: $0.source, colorIndex: $0.colorIndex) }
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
