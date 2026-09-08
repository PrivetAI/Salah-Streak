import SwiftUI

// MARK: - Completion ring

/// Five arcs, one per prayer, drawn in the state colour each currently carries. Nothing
/// is animated on a timer; the ring only redraws when a mark changes.
struct SLCompletionRing: View {
    let record: SLDayRecord
    var diameter: CGFloat = 132
    var lineWidth: CGFloat = 13
    var centreTitle: String
    var centreCaption: String

    private let gap: Double = 4.0        // degrees between segments

    var body: some View {
        ZStack {
            Canvas { context, size in
                let side = min(size.width, size.height)
                let inset = lineWidth / 2 + 1
                let box = CGRect(x: (size.width - side) / 2 + inset,
                                 y: (size.height - side) / 2 + inset,
                                 width: max(1, side - inset * 2),
                                 height: max(1, side - inset * 2))
                let centre = CGPoint(x: box.midX, y: box.midY)
                let radius = box.width / 2
                let count = Double(SLPrayer.allCases.count)
                let slice = 360.0 / count

                for prayer in SLPrayer.allCases {
                    let state = record.state(prayer)
                    let startAngle = -90.0 + Double(prayer.rawValue) * slice + gap / 2
                    let endAngle = startAngle + slice - gap
                    var arc = Path()
                    arc.addArc(center: centre,
                               radius: radius,
                               startAngle: .degrees(startAngle),
                               endAngle: .degrees(endAngle),
                               clockwise: false)
                    let colour = state == .none ? SLTheme.stateBlank : state.colour
                    context.stroke(arc,
                                   with: .color(colour),
                                   style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                }
            }
            .frame(width: diameter, height: diameter)

            VStack(spacing: 2) {
                Text(centreTitle)
                    .font(SLType.display(min(30, diameter * 0.24)))
                    .foregroundColor(SLTheme.teal)
                Text(centreCaption)
                    .font(SLType.caption(min(12, diameter * 0.095)))
                    .foregroundColor(SLTheme.inkFaint)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, lineWidth)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(record.performedCount) of \(SLPrayer.allCases.count) prayers recorded as performed")
    }
}

// MARK: - Simple bar

struct SLProgressBar: View {
    let value: Double
    var height: CGFloat = 8
    var tint: Color = SLTheme.teal
    var track: Color = SLTheme.canvasDeep

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width)
            let filled = width * max(0, min(1, value.isFinite ? value : 0))
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: filled)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Header

/// The top bar for every screen. There is no `NavigationView` chrome anywhere in this
/// app, so the back affordance is built here and the bar never draws over the clock.
struct SLHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let onBack = onBack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        SLChevronIcon(direction: .left, size: 15, color: SLTheme.teal, weight: 2.2)
                        Text("Back")
                            .font(SLType.bodyMedium(14))
                            .foregroundColor(SLTheme.teal)
                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SLType.title(onBack == nil ? 24 : 19))
                    .foregroundColor(SLTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(SLType.caption(12))
                        .foregroundColor(SLTheme.inkFaint)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 4)
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: SLMetric.readableWidth)
        .frame(maxWidth: .infinity)
    }
}

extension SLHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, onBack: onBack, trailing: { EmptyView() })
    }
}

// MARK: - Rows

/// A tappable settings row. The whole row is one button; nothing is nested inside it,
/// because a `Button` inside another `Button`'s label never fires.
struct SLNavRow: View {
    let title: String
    var value: String? = nil
    var detail: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SLType.bodyMedium(15))
                        .foregroundColor(SLTheme.ink)
                        .multilineTextAlignment(.leading)
                    if let detail = detail {
                        Text(detail)
                            .font(SLType.caption(12))
                            .foregroundColor(SLTheme.inkFaint)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                if let value = value {
                    Text(value)
                        .font(SLType.body(14))
                        .foregroundColor(SLTheme.inkSoft)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
                SLChevronIcon(direction: .right, size: 13)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A custom switch. No system `Toggle` chrome anywhere.
struct SLSwitchRow: View {
    let title: String
    var detail: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SLType.bodyMedium(15))
                        .foregroundColor(SLTheme.ink)
                        .multilineTextAlignment(.leading)
                    if let detail = detail {
                        Text(detail)
                            .font(SLType.caption(12))
                            .foregroundColor(SLTheme.inkFaint)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                SLSwitchTrack(isOn: isOn)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SLSwitchTrack: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? SLTheme.teal : SLTheme.hairline)
                .frame(width: 46, height: 28)
            Circle()
                .fill(SLTheme.surface)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
                .padding(.horizontal, 3)
        }
        .frame(width: 46, height: 28)
        .animation(.easeOut(duration: 0.15), value: isOn)
    }
}

struct SLDivider: View {
    var body: some View {
        Rectangle()
            .fill(SLTheme.hairline)
            .frame(height: 1)
            .padding(.leading, 14)
    }
}

/// Groups rows into one card with dividers between them.
struct SLRowGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) { content() }
            .background(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .fill(SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .stroke(SLTheme.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Segmented control

struct SLSegmented: View {
    let options: [String]
    let selection: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: { onSelect(index) }) {
                    Text(options[index])
                        .font(SLType.label(13))
                        .foregroundColor(index == selection ? SLTheme.surface : SLTheme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(index == selection ? SLTheme.teal : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SLTheme.canvasDeep)
        )
    }
}

// MARK: - Stepper

/// A minus / value / plus control built from two ordinary buttons. Deliberately not a
/// system `Stepper`, and deliberately not inside a scroll-sensitive gesture: each tap is
/// a discrete press with no press-duration reading.
struct SLStepper: View {
    let value: Int
    let range: ClosedRange<Int>
    let format: (Int) -> String
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            stepButton(delta: -1, enabled: value > range.lowerBound) {
                SLMinusMark()
                    .stroke(value > range.lowerBound ? SLTheme.teal : SLTheme.stateBlank,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 18, height: 18)
            }
            Text(format(value))
                .font(SLType.mono(15))
                .foregroundColor(SLTheme.ink)
                .frame(minWidth: 64)
                .lineLimit(1)
            stepButton(delta: 1, enabled: value < range.upperBound) {
                SLPlusMark()
                    .stroke(value < range.upperBound ? SLTheme.teal : SLTheme.stateBlank,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SLTheme.canvasDeep)
        )
    }

    @ViewBuilder
    private func stepButton<Icon: View>(delta: Int, enabled: Bool, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: {
            guard enabled else { return }
            let next = min(range.upperBound, max(range.lowerBound, value + delta))
            if next != value { onChange(next) }
        }) {
            icon()
                .frame(width: 40, height: 32)
                // A shape-only label has no fill and therefore no hit area of its own.
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Buttons

struct SLPrimaryButton: View {
    let title: String
    var tint: Color = SLTheme.teal
    var textColour: Color = SLTheme.surface
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SLType.label(15))
                .foregroundColor(textColour)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous).fill(tint)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SLQuietButton: View {
    let title: String
    var tint: Color = SLTheme.teal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SLType.label(14))
                .foregroundColor(tint)
                .padding(.vertical, 11)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.4), lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small pieces

struct SLPill: View {
    let text: String
    var tint: Color = SLTheme.teal
    var fill: Color = SLTheme.tealWash

    var body: some View {
        Text(text)
            .font(SLType.label(11))
            .foregroundColor(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(fill))
    }
}

struct SLStatTile: View {
    let value: String
    let caption: String
    var tint: Color = SLTheme.teal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(SLType.display(24))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(SLType.caption(11))
                .foregroundColor(SLTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(SLTheme.surfaceAlt)
        )
    }
}

/// The standing disclaimer. It appears on every screen that shows a computed time,
/// because a calculated timetable is a guide and the mosque is the authority.
struct SLCalculationNote: View {
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .stroke(SLTheme.goldDeep, lineWidth: 1.4)
                .frame(width: 14, height: 14)
                .overlay(
                    Rectangle()
                        .fill(SLTheme.goldDeep)
                        .frame(width: 1.4, height: 6)
                        .offset(y: 1)
                )
            Text(compact
                 ? "These are calculated times. Follow your local mosque."
                 : "Every time on this screen is calculated from the sun's position for the city and method you chose. It is a guide, not an authority. Where it differs from your local mosque, follow your local mosque.")
                .font(SLType.caption(11.5))
                .foregroundColor(SLTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SLTheme.gold.opacity(0.16))
        )
    }
}

/// Shown wherever a list would otherwise be blank.
struct SLEmptyNote: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SLType.title(16))
                .foregroundColor(SLTheme.ink)
            Text(message)
                .font(SLType.body(13.5))
                .foregroundColor(SLTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                .fill(SLTheme.surfaceAlt)
        )
    }
}
