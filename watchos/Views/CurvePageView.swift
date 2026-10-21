// One page of the vertical TabView: the equation as a label over its plot.

import SwiftUI

struct CurvePageView: View {
    let curve: PresetCurve

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(curve.color).frame(width: 8, height: 8)
                Text("y = \(curve.source)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.top, 4)

            PlotView(curve: curve)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 6)
        .background(Theme.graphBackground)
    }
}
