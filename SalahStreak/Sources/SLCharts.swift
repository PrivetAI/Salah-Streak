import SwiftUI

// Every chart in this app is drawn by hand with `Path` and `Canvas`. The Charts
// framework is iOS 16 and the deployment target here is 15.6, so none of it is available
// — and drawing them directly is what keeps the whole app on one visual language.
//
// All of them take an empty data set without dividing by zero and without drawing an
// axis with no scale on it.

// MARK: - Vertical bars

struct SLBarChart: View {
    /// Values are 0…1. A `nil` value means "nothing logged", drawn as an empty slot.
    let values: [Double?]
    let labels: [String]
    var height: CGFloat = 120
    var tint: Color = SLTheme.teal
    var highlightLast: Bool = true

    var body: some View {
        VStack(spacing: 6) {
            Canvas { context, size in
                let count = values.count
                guard count > 0, size.width > 1, size.height > 1 else { return }

                // Grid lines at 0, 50 and 100 per cent.
                var grid = Path()
                for fraction in [0.0, 0.5, 1.0] {
                    let y = size.height - size.height * fraction
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(SLTheme.hairline),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                let slot = size.width / CGFloat(count)
                let barWidth = max(3, min(slot * 0.62, 26))
                for index in 0..<count {
                    let centreX = slot * (CGFloat(index) + 0.5)
                    let raw = values[index] ?? 0
                    let clamped = max(0, min(1, raw.isFinite ? raw : 0))
                    let barHeight = max(values[index] == nil ? 0 : 2, size.height * CGFloat(clamped))
                    let rect = CGRect(x: centreX - barWidth / 2,
                                      y: size.height - barHeight,
                                      width: barWidth,
                                      height: barHeight)
                    let isLast = highlightLast && index == count - 1
                    if values[index] == nil {
                        var empty = Path()
                        empty.addRoundedRect(in: CGRect(x: rect.minX, y: size.height - 3,
                                                        width: barWidth, height: 3),
                                             cornerSize: CGSize(width: 1.5, height: 1.5))
                        context.fill(empty, with: .color(SLTheme.stateBlank))
                    } else {
                        var bar = Path()
                        bar.addRoundedRect(in: rect,
                                           cornerSize: CGSize(width: min(4, barWidth / 2),
                                                              height: min(4, barWidth / 2)))
                        context.fill(bar, with: .color(isLast ? SLTheme.gold : tint))
                    }
                }
            }
            .frame(height: height)

            HStack(spacing: 0) {
                ForEach(labels.indices, id: \.self) { index in
                    Text(labels[index])
                        .font(SLType.caption(9.5))
                        .foregroundColor(SLTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Trend line

struct SLTrendLine: View {
    /// Smoothed values, 0…1, oldest first.
    let values: [Double]
    var height: CGFloat = 130
    var tint: Color = SLTheme.teal
    var fill: Color = SLTheme.tealWash
    var leadingLabel: String = ""
    var trailingLabel: String = ""

    var body: some View {
        VStack(spacing: 6) {
            Canvas { context, size in
                guard size.width > 1, size.height > 1 else { return }

                var grid = Path()
                for fraction in [0.0, 0.25, 0.5, 0.75, 1.0] {
                    let y = size.height - size.height * fraction
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(SLTheme.hairline),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                guard values.count >= 2 else {
                    // One point or none is not a trend. Say nothing rather than draw a
                    // line through a single value.
                    return
                }

                let step = size.width / CGFloat(values.count - 1)
                func point(_ index: Int) -> CGPoint {
                    let value = max(0, min(1, values[index].isFinite ? values[index] : 0))
                    return CGPoint(x: step * CGFloat(index),
                                   y: size.height - size.height * CGFloat(value))
                }

                var area = Path()
                area.move(to: CGPoint(x: 0, y: size.height))
                for index in 0..<values.count { area.addLine(to: point(index)) }
                area.addLine(to: CGPoint(x: size.width, y: size.height))
                area.closeSubpath()
                context.fill(area, with: .color(fill))

                var line = Path()
                line.move(to: point(0))
                for index in 1..<values.count { line.addLine(to: point(index)) }
                context.stroke(line, with: .color(tint),
                               style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                let last = point(values.count - 1)
                var dot = Path()
                dot.addEllipse(in: CGRect(x: last.x - 4, y: last.y - 4, width: 8, height: 8))
                context.fill(dot, with: .color(SLTheme.gold))
                context.stroke(dot, with: .color(tint), lineWidth: 1.5)
            }
            .frame(height: height)

            HStack {
                Text(leadingLabel)
                Spacer()
                Text(trailingLabel)
            }
            .font(SLType.caption(10))
            .foregroundColor(SLTheme.inkFaint)
        }
    }
}

// MARK: - Horizontal rate bars

struct SLRateRow: View {
    let title: String
    let rate: Double?
    let sampleCount: Int
    var tint: Color = SLTheme.teal

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(SLType.bodyMedium(14))
                    .foregroundColor(SLTheme.ink)
                Spacer(minLength: 8)
                Text(SLStatistics.percentText(rate))
                    .font(SLType.mono(14))
                    .foregroundColor(rate == nil ? SLTheme.inkFaint : tint)
                Text(sampleCount == 1 ? "1 mark" : "\(sampleCount) marks")
                    .font(SLType.caption(10.5))
                    .foregroundColor(SLTheme.inkFaint)
            }
            SLProgressBar(value: rate ?? 0, height: 7, tint: tint)
        }
    }
}

// MARK: - Month heat grid

/// The calendar heatmap. Cells are square, laid out from the available width, and a day
/// outside the month is a blank — never a zero-valued cell, which would read as a day the
/// user failed rather than a day that does not exist.
struct SLHeatGrid: View {
    let rows: [[Date?]]
    let weekInitials: [String]
    let fractionFor: (Date) -> Double?
    let isToday: (Date) -> Bool
    let isFuture: (Date) -> Bool
    let dayNumber: (Date) -> Int
    let onSelect: (Date) -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(weekInitials.indices, id: \.self) { index in
                    Text(weekInitials[index])
                        .font(SLType.label(10))
                        .foregroundColor(SLTheme.inkFaint)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(rows[rowIndex].indices, id: \.self) { columnIndex in
                        cell(rows[rowIndex][columnIndex])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ date: Date?) -> some View {
        if let date = date {
            let future = isFuture(date)
            let fraction = future ? nil : fractionFor(date)
            Button(action: { if !future { onSelect(date) } }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(future ? SLTheme.surfaceAlt : SLTheme.heat(fraction ?? 0))
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isToday(date) ? SLTheme.clay : SLTheme.hairline,
                                lineWidth: isToday(date) ? 2 : 1)
                    Text("\(dayNumber(date))")
                        .font(SLType.caption(11))
                        .foregroundColor(labelColour(fraction: fraction, future: future))
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(future)
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }

    private func labelColour(fraction: Double?, future: Bool) -> Color {
        if future { return SLTheme.stateBlank }
        guard let fraction = fraction else { return SLTheme.inkFaint }
        return fraction > 0.55 ? SLTheme.surface : SLTheme.inkSoft
    }
}

/// The legend under the heat grid. Five swatches from nothing logged to a full day.
struct SLHeatLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("None")
                .font(SLType.caption(10))
                .foregroundColor(SLTheme.inkFaint)
            ForEach(0..<5, id: \.self) { step in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(SLTheme.heat(Double(step) / 4.0))
                    .frame(width: 16, height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(SLTheme.hairline, lineWidth: 0.7)
                    )
            }
            Text("All five")
                .font(SLType.caption(10))
                .foregroundColor(SLTheme.inkFaint)
            Spacer(minLength: 0)
        }
    }
}
