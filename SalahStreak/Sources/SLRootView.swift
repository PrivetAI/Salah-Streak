import SwiftUI

/// The app's own shell. There is no `TabView` here on purpose: `.tabItem` renders only an
/// `Image` and a `Text`, so a custom `Shape` icon handed to it simply disappears. The bar
/// below is an `HStack` of ordinary buttons over a `switch`.
struct SLRootView: View {
    @EnvironmentObject private var store: SLStore
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .top) {
            SLTheme.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0: SLTodayTab()
                    case 1: SLCalendarTab()
                    case 2: SLStatsTab()
                    case 3: SLGuideTab()
                    default: SLSettingsTab()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                SLTabBar(selection: $tab)
            }

            // LAST sibling of the root stack, so a ScrollView bouncing past its top can
            // never draw over the clock. It takes no touches.
            SLStatusStrip()
        }
    }
}

struct SLTabBar: View {
    @Binding var selection: Int

    private struct Item {
        let title: String
        let index: Int
    }

    private let items: [Item] = [
        Item(title: "Today", index: 0),
        Item(title: "Calendar", index: 1),
        Item(title: "Stats", index: 2),
        Item(title: "Guide", index: 3),
        Item(title: "Settings", index: 4)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(SLTheme.hairline)
                .frame(height: 1)
            HStack(spacing: 0) {
                ForEach(items, id: \.index) { item in
                    button(item)
                }
            }
            .padding(.top, 7)
            .padding(.bottom, 3)
            .frame(maxWidth: SLMetric.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .background(SLTheme.surface.edgesIgnoringSafeArea(.bottom))
    }

    @ViewBuilder
    private func button(_ item: Item) -> some View {
        let active = selection == item.index
        let tint = active ? SLTheme.teal : SLTheme.inkFaint
        Button(action: { selection = item.index }) {
            VStack(spacing: 4) {
                glyph(for: item.index, tint: tint)
                    .frame(width: 23, height: 23)
                Text(item.title)
                    .font(SLType.label(10))
                    .foregroundColor(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            // A glyph-only label over a clear background has no hit area of its own.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
    }

    @ViewBuilder
    private func glyph(for index: Int, tint: Color) -> some View {
        let style = StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
        switch index {
        case 0: SLRugGlyph().stroke(tint, style: style)
        case 1: SLGridGlyph().stroke(tint, style: style)
        case 2: SLBarsGlyph().stroke(tint, style: style)
        case 3: SLBookGlyph().stroke(tint, style: style)
        default: SLSlidersGlyph().stroke(tint, style: style)
        }
    }
}
