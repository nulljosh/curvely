// Equation rows + quick examples. Ported from EquationList.jsx / EquationRow.jsx.

import SwiftUI

struct EquationListView: View {
    @Binding var equations: [Equation]
    @State private var patternCategory = patternCategories[0]
    let onChange: () -> Void
    var playing: Set<String> = []
    var animated: [String: Double] = [:]
    var onTogglePlay: (String) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach($equations) { $equation in
                EquationRowView(
                    equation: $equation, onChange: onChange, onRemove: { remove(equation.id) },
                    playing: playing, animated: animated, onTogglePlay: onTogglePlay
                )
            }

            Button(action: add) {
                Label("Add equation", systemImage: "plus")
                    .font(Theme.font(15, .medium))
                    .foregroundStyle(Theme.accentText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.accent.opacity(0.22), in: Capsule())
                    .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            examples
        }
    }

    private var examples: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK EXAMPLES")
                .font(Theme.font(11, .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.secondary)

            FlowRow(spacing: 6) {
                ForEach(quickExamples, id: \.self) { example in
                    Button { append(example) } label: {
                        Text(example)
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.secondary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 32)
                            .background(Theme.fill, in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("PATTERNS")
                .font(Theme.font(11, .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.secondary)
                .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(patternCategories, id: \.self) { category in
                        let selected = category == patternCategory
                        Button { patternCategory = category } label: {
                            Text(category)
                                .font(Theme.font(13, .medium))
                                .foregroundStyle(selected ? Theme.accentText : Theme.secondary)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 32)
                                .background(selected ? Theme.accent.opacity(0.18) : .clear, in: Capsule())
                                .overlay(Capsule().strokeBorder(selected ? Theme.accent.opacity(0.45) : .clear, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }

            FlowRow(spacing: 6) {
                ForEach(patterns.filter { $0.category == patternCategory }, id: \.name) { pattern in
                    Button { pattern.rows.forEach(append) } label: {
                        Text(pattern.name)
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.secondary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 32)
                            .background(Theme.fill, in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Adds the \(pattern.name.lowercased()) rows to the graph")
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Mutations

    private func add() { append("") }

    private func append(_ source: String) {
        equations.append(Equation(source: source, colorIndex: nextColorIndex()))
        onChange()
    }

    private func remove(_ id: UUID) {
        equations.removeAll { $0.id == id }
        onChange()
    }

    /// Pick the lowest palette slot not already on screen, so a delete-then-add reuses
    /// the freed color instead of drifting through the palette.
    private func nextColorIndex() -> Int {
        let used = Set(equations.map(\.colorIndex))
        for index in 0..<Palette.curveHex.count where !used.contains(index) { return index }
        return equations.count
    }
}

struct EquationRowView: View {
    @Binding var equation: Equation
    let onChange: () -> Void
    let onRemove: () -> Void
    var playing: Set<String> = []
    var animated: [String: Double] = [:]
    var onTogglePlay: (String) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Button {
                    equation.hidden.toggle()
                    onChange()
                } label: {
                    Circle()
                        .fill(equation.hidden ? Color.clear : equation.color)
                        .overlay(Circle().strokeBorder(equation.color, lineWidth: 2))
                        .frame(width: 12, height: 12)
                        .frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(equation.hidden ? "Show on graph" : "Hide from graph")

                TextField("y =", text: binding)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    // textInputAutocapitalization is iOS-only; a Mac has no software
                    // keyboard to autocapitalize, so there is nothing to do there.
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.text)
                    .accessibilityLabel("Equation")

                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove equation")
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(Theme.fill, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))

            if let error = equation.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Theme.error)
                    .padding(.leading, 32)
            }

            if let slider = equation.compiled.slider {
                let isPlaying = playing.contains(slider.name)
                HStack(spacing: 10) {
                    Button { onTogglePlay(slider.name) } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(isPlaying ? Theme.accentText : Theme.text)
                            .frame(width: 32, height: 32)
                            .background(Theme.fill, in: Circle())
                            .overlay(Circle().strokeBorder(isPlaying ? Theme.accent : Theme.border, lineWidth: 1))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPlaying ? "Pause \(slider.name)" : "Play \(slider.name)")

                    // Dragging rewrites the row's own text, like Desmos, so the value persists
                    // with the equation. Playing animates a separate value and writes it once, on pause.
                    Slider(
                        value: Binding(
                            get: { animated[slider.name] ?? slider.value },
                            set: { value in
                                if isPlaying { onTogglePlay(slider.name) }
                                binding.wrappedValue = sliderSource(slider, value: value)
                            }
                        ),
                        in: slider.range
                    )
                    .tint(equation.color)
                    .accessibilityLabel("Value of \(slider.name)")
                }
                .padding(.leading, 22)
            }
        }
    }

    private var binding: Binding<String> {
        Binding(
            get: { equation.source },
            set: { equation.update(source: $0); onChange() }
        )
    }
}

/// Wraps its children onto as many lines as needed.
/// ponytail: SwiftUI has no built-in wrapping stack before iOS 16's Layout, and this is
/// the whole implementation — a Grid or LazyVGrid would force a fixed column count.
struct FlowRow: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = layout(subviews: subviews, in: width)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: width == .infinity ? rows.map(\.width).max() ?? 0 : width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in layout(subviews: subviews, in: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var height: CGFloat = 0
        var width: CGFloat = 0
    }

    private func layout(subviews: Subviews, in width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        var x: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !row.indices.isEmpty, x + size.width > width {
                rows.append(row)
                row = Row(indices: [], y: row.y + row.height + spacing, height: 0, width: 0)
                x = 0
            }
            row.indices.append(index)
            row.height = max(row.height, size.height)
            x += size.width + spacing
            row.width = x - spacing
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}
