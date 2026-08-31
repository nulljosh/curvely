import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var equations: [Equation] = defaultEquations
    @State private var transform = GraphTransform()
    @State private var exportedImage: ExportedGraph?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Theme.border)
            content
        }
        .background(Theme.graphBackground)
        .preferredColorScheme(.dark)
        .onAppear(perform: restore)
        .sheet(item: $exportedImage) { export in
            ExportSheet(export: export)
        }
    }

    // MARK: - Layout

    /// iPad gets the web app's side-by-side layout; iPhone stacks, since a 320pt-wide
    /// sidebar next to a plot is unusable.
    ///
    /// This branches on the size class rather than `ViewThatFits`. `ViewThatFits` measures
    /// each branch at its *ideal* size, and `graph` is a `GeometryReader`, which has no
    /// intrinsic width — it reports SwiftUI's 10pt default against an unspecified proposal.
    /// That made the side-by-side branch measure ~331pt (10 + divider + 320 sidebar), which
    /// "fits" every iPhone from the 375pt SE up, so iPhones took the HStack and the plot was
    /// left with whatever the 320pt sidebar didn't eat — about 69pt. That is the squashed
    /// graph. The size class is the actual signal for "is this a phone", so ask it directly.
    @ViewBuilder
    private var content: some View {
        if horizontalSizeClass == .compact {
            // The graph is the point of the app, so it takes the screen and the
            // equation list gets a proportional slice of what is left. A fixed
            // 300pt sidebar cap left the plot cramped on shorter iPhones.
            VStack(spacing: 0) {
                graph
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                Divider().overlay(Theme.border)
                sidebar.containerRelativeFrame(.vertical) { height, _ in height * 0.34 }
            }
        } else {
            HStack(spacing: 0) {
                graph.frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider().overlay(Theme.border)
                sidebar.frame(width: 320)
            }
        }
    }

    private var graph: some View {
        GraphView(equations: equations, transform: $transform)
            .overlay(alignment: .bottomTrailing) { zoomCluster }
    }

    private var sidebar: some View {
        ScrollView {
            EquationListView(equations: $equations, onChange: persist)
                .padding(16)
        }
        .background(Theme.graphBackground)
    }

    private var header: some View {
        HStack(spacing: 10) {
            // ponytail: the Mac window titlebar already says Curvely; a second one is duplicate chrome.
            #if !os(macOS)
            Text("Curvely")
                .font(.headline)
                .foregroundStyle(Theme.text)
            #endif

            Spacer()

            Button(action: exportGraph) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Theme.text)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Export graph as an image")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var zoomCluster: some View {
        VStack(spacing: 8) {
            Text("\(transform.zoomPercent)%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.secondary)

            zoomButton("plus", label: "Zoom in") { zoom(by: 1.3) }
            zoomButton("minus", label: "Zoom out") { zoom(by: 1 / 1.3) }
            zoomButton("house", label: "Reset view") { transform = GraphTransform() }
        }
        .padding(10)
        .background(Theme.panel.opacity(0.9))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(16)
    }

    private func zoomButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundStyle(Theme.text)
                .frame(width: 28, height: 28)
                // ponytail: .plain hit-tests the drawn glyph, so thin symbols like
                // "minus" were only clickable on the bar itself.
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Actions

    private func zoom(by factor: Double) {
        // Buttons zoom about the middle of the plot, matching the web app's zoomBy().
        let size = CGSize(width: 1, height: 1)
        transform.zoom(by: factor, about: CGPoint(x: 0.5, y: 0.5), in: size)
    }

    /// ponytail: ImageRenderer over the same GraphView — one source of truth for what a
    /// curve looks like, rather than a second drawing path just for export.
    private func exportGraph() {
        let snapshot = GraphView(equations: equations, transform: .constant(transform))
            .frame(width: 1200, height: 900)
        let renderer = ImageRenderer(content: snapshot)
        renderer.scale = 2
        // cgImage, not uiImage: UIImage does not exist on macOS and NSImage does not exist
        // on iOS, so CoreGraphics is the one type both destinations share.
        guard let cgImage = renderer.cgImage, let png = pngData(from: cgImage) else { return }
        exportedImage = ExportedGraph(image: Image(decorative: cgImage, scale: 2), png: png)
    }

    private func restore() {
        guard let saved = Store.load() else { return }
        equations = saved
    }

    private func persist() {
        Store.save(equations)
    }
}

struct ExportedGraph: Identifiable, Transferable {
    let id = UUID()
    /// On-screen preview only.
    let image: Image
    /// What actually gets shared. Sharing the `Image` instead would hand the receiver an
    /// unnamed image and give us nothing testable; PNG bytes with a filename arrive as a
    /// real file in Mail, Messages, Finder and every other share target.
    let png: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.png }
            .suggestedFileName("curvely-graph.png")
    }
}

/// ponytail: replaced a `UIViewControllerRepresentable` over `UIActivityViewController`,
/// which is iOS-only. `ShareLink` is the native share affordance on both destinations and
/// needs no representable at all.
struct ExportSheet: View {
    let export: ExportedGraph
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            export.image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 600)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            ShareLink(item: export, preview: SharePreview("Graph", image: export.image)) {
                Label("Share graph", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)

            Button("Done") { dismiss() }
        }
        .padding(24)
        .frame(minWidth: 360, minHeight: 320)
    }
}
