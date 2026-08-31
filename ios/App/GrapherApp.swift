import SwiftUI

@main
struct CurvelyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // ponytail: 900x450 was the AppKit default, too cramped to graph in.
        #if os(macOS)
        .defaultSize(width: 1280, height: 800)
        #endif
    }
}
