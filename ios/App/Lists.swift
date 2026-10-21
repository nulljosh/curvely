// Lists, Desmos style. Port of src/utils/lists.js.
// `L = [1, 2, 3]` defines a list. A row that uses a list, or holds a literal like
// `sin(x) + [0, 1, 2]`, draws once per element with the list bound to that element.
// A list of points `[(1, 2), (2, 4)]` becomes two lists and one point row.

import Foundation

private let maxListItems = 1000

/// `1, 2, 3` or `1...10`, or nil when it is not a plain list of numbers.
private func parseItems(_ inner: String) -> [Double]? {
    if let m = inner.wholeMatch(of: #/\s*(-?\d+(?:\.\d+)?)\s*\.\.\.\s*(-?\d+(?:\.\d+)?)\s*/#),
       let a = Double(m.1), let b = Double(m.2) {
        guard b >= a, b - a < Double(maxListItems) else { return nil }
        return (0...Int((b - a).rounded(.down))).map { a + Double($0) }
    }
    let parts = inner.split(separator: ",", omittingEmptySubsequences: false)
        .map { $0.trimmingCharacters(in: .whitespaces) }
    let numbers = parts.compactMap(Double.init)
    return numbers.count == parts.count && !numbers.isEmpty ? numbers : nil
}

func parseListDef(_ raw: String) -> (name: String, items: [Double])? {
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    guard let m = trimmed.wholeMatch(of: #/([a-zA-Z]\w*)\s*=\s*\[([^\[\]]*)\]/#),
          let items = parseItems(String(m.2)) else { return nil }
    return (String(m.1).lowercased(), items)
}

private func parsePointList(_ inner: String) -> (xs: [Double], ys: [Double])? {
    let pair = #/\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)/#
    let matches = inner.matches(of: pair)
    let rest = inner.replacing(pair, with: "").filter { !$0.isWhitespace && $0 != "," }
    guard !matches.isEmpty, rest.isEmpty else { return nil }
    return (matches.compactMap { Double($0.1) }, matches.compactMap { Double($0.2) })
}

/// Whether `source` names `name` on its own. Not a word-boundary regex: `0.05shell` uses
/// shell, and a digit-to-letter step is no word boundary.
private func uses(_ source: String, _ name: String) -> Bool {
    var rest = source[...]
    while let hit = rest.range(of: name) {
        let before = hit.lowerBound == source.startIndex ? nil : source[source.index(before: hit.lowerBound)]
        let after = hit.upperBound == source.endIndex ? nil : source[hit.upperBound]
        // ASCII only, to match the web regex `(?<![A-Za-z_])name(?!\\w)` exactly
        let isPart = { (c: Character?) in c.map { $0.isASCII && ($0.isLetter || $0 == "_") } ?? false }
        if !isPart(before), !(isPart(after) || (after.map { $0.isASCII && $0.isNumber } ?? false)) { return true }
        rest = source[hit.upperBound...]
    }
    return false
}

/// The rewritten row, compiled once, and one binding per copy to draw.
/// `binds` is empty for a list definition and `[[:]]` for a row that uses no list.
func expandRow(_ raw: String, lists: [String: [Double]]) -> (source: String, binds: [[String: Double]]) {
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    if parseListDef(trimmed) != nil { return (trimmed, []) }
    var local: [String: [Double]] = [:]
    var counter = 0
    func nextName() -> String { defer { counter += 1 }; return "qlist\(counter)" }
    var source = trimmed
    if let whole = trimmed.wholeMatch(of: #/\[(.*)\]/#), let points = parsePointList(String(whole.1)) {
        let (xn, yn) = (nextName(), nextName())
        local[xn] = points.xs
        local[yn] = points.ys
        source = "(\(xn), \(yn))"
    } else {
        source = trimmed.replacing(#/\[([^\[\]]*)\]/#) { match in
            guard let items = parseItems(String(match.1)) else { return String(match.0) }
            let name = nextName()
            local[name] = items
            return name
        }
    }
    let all = lists.merging(local) { _, new in new }
    let lowered = source.lowercased()
    let used = all.keys.filter { uses(lowered, $0) }.sorted()
    guard !used.isEmpty else { return (source, [[:]]) }
    let count = used.map { all[$0]!.count }.min()!
    let binds = (0..<count).map { i in Dictionary(uniqueKeysWithValues: used.map { ($0, all[$0]![i]) }) }
    return (source, binds)
}
