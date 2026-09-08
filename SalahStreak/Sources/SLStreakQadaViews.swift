import SwiftUI

/// Shared scaffold for every pushed screen: opaque ground, a header with a back control,
/// and a scrolling readable column. There is no `NavigationView` in this app, so nothing
/// here can be dismissed by a parent's `presentationMode` and then look dead.
struct SLDetailScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let onBack: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            SLHeader(title: title, subtitle: subtitle, onBack: onBack)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 32)
                .frame(maxWidth: SLMetric.readableWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(SLTheme.canvas.ignoresSafeArea())
    }
}

// MARK: - Qada ledger

struct SLQadaScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    var body: some View {
        SLDetailScreen(title: "Qada ledger",
                       subtitle: "Prayers marked missed, and what you have made up",
                       onBack: onBack) {

            SLCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(store.qadaTotalOutstanding)")
                            .font(SLType.display(34))
                            .foregroundColor(store.qadaTotalOutstanding == 0 ? SLTheme.stateJamaah : SLTheme.clay)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.qadaTotalOutstanding == 1 ? "prayer outstanding" : "prayers outstanding")
                                .font(SLType.bodyMedium(14))
                                .foregroundColor(SLTheme.ink)
                            Text("\(store.qadaTotalPaid) made up so far")
                                .font(SLType.caption(12))
                                .foregroundColor(SLTheme.inkFaint)
                        }
                        Spacer(minLength: 0)
                    }
                    Text("A prayer enters this ledger the moment you mark it missed, and leaves it when you record that you have made it up. Nothing here is deleted from your history: the missed mark stays on the day it belongs to.")
                        .font(SLType.body(13))
                        .foregroundColor(SLTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SLSectionTitle(text: "By prayer")

            VStack(spacing: 10) {
                ForEach(SLPrayer.allCases) { prayer in
                    qadaRow(prayer)
                }
            }

            SLEmptyNote(title: "On making up a prayer",
                        message: "This ledger is a counter you keep yourself. It has no view on whether a particular prayer must be made up, or in what order — that is a question for someone qualified to answer it, not for an app.")
        }
    }

    @ViewBuilder
    private func qadaRow(_ prayer: SLPrayer) -> some View {
        let outstanding = store.qadaOutstanding(prayer)
        let missed = store.qadaMissedTotal(prayer)
        let paid = store.qadaPaidCount(prayer)

        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                prayer.glyph(size: 22, color: SLTheme.tealSoft, weight: 1.7)
                    .frame(width: 24, height: 24)
                Text(prayer.name)
                    .font(SLType.title(16))
                    .foregroundColor(SLTheme.ink)
                Spacer(minLength: 6)
                Text("\(outstanding)")
                    .font(SLType.display(21))
                    .foregroundColor(outstanding == 0 ? SLTheme.stateJamaah : SLTheme.clay)
            }

            Text("\(missed) marked missed  ·  \(paid) made up")
                .font(SLType.caption(11.5))
                .foregroundColor(SLTheme.inkFaint)

            HStack(spacing: 8) {
                Button(action: { store.payQada(prayer) }) {
                    Text("Make up one")
                        .font(SLType.label(12.5))
                        .foregroundColor(outstanding > 0 ? SLTheme.surface : SLTheme.inkFaint)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(outstanding > 0 ? SLTheme.teal : SLTheme.canvasDeep)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(outstanding == 0)

                Button(action: { store.undoQada(prayer) }) {
                    Text("Undo")
                        .font(SLType.label(12.5))
                        .foregroundColor(paid > 0 ? SLTheme.teal : SLTheme.inkFaint)
                        .padding(.vertical, 9)
                        .frame(width: 84)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(paid > 0 ? SLTheme.teal.opacity(0.4) : SLTheme.hairline, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(paid == 0)
            }
        }
        .padding(14)
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

// MARK: - Streaks

struct SLStreakScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    var body: some View {
        let stats = store.statistics()

        return SLDetailScreen(title: "Streaks",
                              subtitle: "What counts, and where you stand",
                              onBack: onBack) {

            SLCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What a complete day means")
                        .font(SLType.title(16))
                        .foregroundColor(SLTheme.ink)
                    Text("A day is complete when all five obligatory prayers carry a mark of in congregation, on time or late. A day with a missed prayer is not complete, and neither is a day with a prayer left unmarked.")
                        .font(SLType.body(13.5))
                        .foregroundColor(SLTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    SLOrnamentRule(width: 140)
                    Text("Today does not break a streak while it is still running. The streak is measured back from the most recent day that has ended, so an unfinished day costs you nothing until it is over.")
                        .font(SLType.body(13.5))
                        .foregroundColor(SLTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                SLStatTile(value: "\(stats.currentStreak)", caption: "Current streak, complete days", tint: SLTheme.clay)
                SLStatTile(value: "\(stats.longestStreak)", caption: "Longest streak on record")
                SLStatTile(value: "\(stats.completeDays)", caption: "Complete days in total")
            }

            SLSectionTitle(text: "Per-prayer runs",
                           trailing: "consecutive days performed")

            SLRowGroup {
                ForEach(SLPrayer.allCases) { prayer in
                    streakRow(prayer, stats: stats)
                    if prayer != SLPrayer.allCases.last { SLDivider() }
                }
            }

            SLSectionTitle(text: "Fajr in congregation")

            SLCard {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(stats.fajrCongregationStreak)")
                            .font(SLType.display(30))
                            .foregroundColor(SLTheme.stateJamaah)
                        Text("current run")
                            .font(SLType.caption(11))
                            .foregroundColor(SLTheme.inkFaint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(stats.fajrCongregationBest)")
                            .font(SLType.display(30))
                            .foregroundColor(SLTheme.teal)
                        Text("best run")
                            .font(SLType.caption(11))
                            .foregroundColor(SLTheme.inkFaint)
                    }
                    Spacer(minLength: 0)
                }
            }

            if !store.hasAnyHistory {
                SLEmptyNote(title: "Nothing recorded yet",
                            message: "Mark a prayer on the Today screen and the counts here start filling in. Past days can be corrected from the Calendar at any time.")
            }
        }
    }

    @ViewBuilder
    private func streakRow(_ prayer: SLPrayer, stats: SLStatistics) -> some View {
        HStack(spacing: 12) {
            prayer.glyph(size: 20, color: SLTheme.tealSoft, weight: 1.7)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.name)
                    .font(SLType.bodyMedium(14.5))
                    .foregroundColor(SLTheme.ink)
                Text("best \(stats.prayerLongestStreak[prayer.rawValue])")
                    .font(SLType.caption(11))
                    .foregroundColor(SLTheme.inkFaint)
            }
            Spacer(minLength: 8)
            Text("\(stats.prayerCurrentStreak[prayer.rawValue])")
                .font(SLType.mono(17))
                .foregroundColor(stats.prayerCurrentStreak[prayer.rawValue] > 0 ? SLTheme.teal : SLTheme.inkFaint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
