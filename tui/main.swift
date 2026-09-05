import Foundation
import SwiftTUI

// ponytail: the graphing math is mathjs, AST-fenced server-side on purpose (see
// functions/api/[[route]].js) — it must not be duplicated in Swift. `curvely-tui`
// hits the same /api/sample the web canvas uses and renders the sampled points
// as a plain-text plot.

struct Point: Decodable { let x: Double; let y: Double }
struct SampleResult: Decodable { let points: [Point]; let range: Range; let undefinedCount: Int }
struct Range: Decodable { let min: Double; let max: Double }

let args = CommandLine.arguments.dropFirst()
guard let expr = args.first else {
    print("usage: curvely-tui <expr> [from] [to]")
    exit(1)
}
let from = args.count > 1 ? Double(Array(args)[1]) ?? -10 : -10
let to = args.count > 2 ? Double(Array(args)[2]) ?? 10 : 10

func fetchSample() async -> SampleResult? {
    guard let url = URL(string: "https://curvely.heyitsmejosh.com/api/sample") else { return nil }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "content-type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["expr": expr, "from": from, "to": to, "samples": 21])
    guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
    return try? JSONDecoder().decode(SampleResult.self, from: data)
}

func sparkline(_ result: SampleResult) -> String {
    let ramp = Array(" .:-=+*#%@")
    let span = max(result.range.max - result.range.min, 0.0001)
    return result.points.map { p in
        p.y.isNaN ? " " : String(ramp[min(ramp.count - 1, Int((p.y - result.range.min) / span * Double(ramp.count - 1)))])
    }.joined()
}

struct GraphCard: View {
    let expr: String
    let result: SampleResult?

    var body: some View {
        VStack(alignment: .leading) {
            Text("y = \(expr)").bold()
            if let result {
                Text(sparkline(result))
                Text("range \(result.range.min) … \(result.range.max)")
            } else {
                Text("Could not evaluate — check curvely.heyitsmejosh.com/api/syntax")
            }
        }
        .padding()
        .border()
    }
}

let semaphore = DispatchSemaphore(value: 0)
var result: SampleResult?
Task {
    result = await fetchSample()
    semaphore.signal()
}
semaphore.wait()

Application(rootView: GraphCard(expr: expr, result: result)).start()
