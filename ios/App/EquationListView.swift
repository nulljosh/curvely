// Equation rows + quick examples. Ported from EquationList.jsx / EquationRow.jsx.

import SwiftUI

struct EquationListView: View {
    @Binding var equations: [Equation]
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach($equations) { $equation in
                EquationRowView(equation: $equation, onChange: onChange) {
                    remove(equation.id)
                }
            }

            Button(action: add) {
                Label("Add equation", systemImage: "plus")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            examples
        }
    }

    private var examples: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK EXAMPLES")
                .font(.caption2)
                .tracking(1.2)
                .foregroundStyle(Theme.secondary)

            FlowRow(spacing: 6) {
                ForEach(quickExamples, id: \.self) { example in
                    Button { append(example) } label: {
                        Text(example)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Circle()
                    .fill(equation.color)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)

                TextField("y =", text: binding)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    // textInputAutocapitalization is iOS-only; a Mac has no software
                    // keyboard to autocapitalize, so there is nothing to do there.
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let error = equation.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Theme.error)
                    .padding(.leading, 32)
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
