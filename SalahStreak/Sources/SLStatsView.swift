import SwiftUI

struct SLStatsTab: View {
    @EnvironmentObject private var store: SLStore
    @State private var trendIndex = 0

    private let trendSpans = [30, 90, 365]
    private let trendWindows = [7, 14, 30]
    private let trendTitles = ["30 days", "90 days", "365 days"]

    var body: some View {
        let stats = store.statistics()
        let zone = store.timeZoneID

        return VStack(spacing: 0) {
            SLHeader(title: "Statistics",
                     subtitle: "Everything below is counted from what you have marked")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    if stats.markedTotal == 0 {
                        SLEmptyNote(title: "No marks yet",
                                    message: "Once you start marking prayers, this screen fills in: on-time and congregation rates, a heat map of the weeks, trend lines over thirty, ninety and three hundred and sixty-five days, and which prayer you hold best.")
                    }

                    overview(stats)

                    SLSectionTitle(text: "By prayer", trailing: "on time or in congregation")
                    SLCard {
                        VStack(spacing: 14) {
                            ForEach(SLPrayer.allCases) { prayer in
                                SLRateRow(title: prayer.name,
                                          rate: stats.punctualRate(prayer),
                                          sampleCount: stats.markedByPrayer[prayer.rawValue])
                            }
                        }
                    }

                    SLSectionTitle(text: "In congregation", trailing: "share of marked prayers")
                    SLCard {
                        VStack(spacing: 14) {
                            ForEach(SLPrayer.allCases) { prayer in
                                SLRateRow(title: prayer.name,
                                          rate: stats.congregationRate(prayer),
                                          sampleCount: stats.markedByPrayer[prayer.rawValue],
                                          tint: SLTheme.stateJamaah)
                            }
                        }
                    }

                    SLSectionTitle(text: "Weekly completion", trailing: "last 8 weeks")
                    SLCard {
                        weeklyChart(stats, zone: zone)
                    }

                    SLSectionTitle(text: "Trend")
                    SLCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SLSegmented(options: trendTitles,
                                        selection: trendIndex,
                                        onSelect: { trendIndex = $0 })
                            trendChart(stats, zone: zone)
                            Text("The line is the share of each day's five prayers that was recorded as performed, smoothed over \(trendWindows[safe: trendIndex] ?? 7) days. Days you never opened count as zero.")
                                .font(SLType.caption(11))
                                .foregroundColor(SLTheme.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SLSectionTitle(text: "The last six months", trailing: "one square a day")
                    SLCard {
                        VStack(alignment: .leading, spacing: 10) {
                            historyStrip(stats)
                            SLHeatLegend()
                        }
                    }

                    SLSectionTitle(text: "By day of the week")
                    SLCard {
                        weekdayChart(stats)
                    }

                    SLSectionTitle(text: "Notable")
                    notable(stats, zone: zone)

                    SLCalculationNote(compact: true)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .frame(maxWidth: SLMetric.readableWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(SLTheme.canvas.ignoresSafeArea())
    }

    // MARK: Overview

    @ViewBuilder
    private func overview(_ stats: SLStatistics) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SLStatTile(value: SLStatistics.percentText(stats.punctualRate),
                           caption: "On time overall")
                SLStatTile(value: SLStatistics.percentText(stats.congregationRate),
                           caption: "In congregation",
                           tint: SLTheme.stateJamaah)
            }
            HStack(spacing: 10) {
                SLStatTile(value: "\(stats.completeDays)", caption: "Complete days", tint: SLTheme.clay)
                SLStatTile(value: "\(stats.markedTotal)", caption: "Prayers marked")
                SLStatTile(value: "\(stats.missedTotal)", caption: "Marked missed", tint: SLTheme.stateMissed)
            }
        }
    }

    // MARK: Weekly

    @ViewBuilder
    private func weeklyChart(_ stats: SLStatistics, zone: String) -> some View {
        let weeks = stats.weeklySeries(weeks: 8, weekStart: store.settings.weekStart)
        if weeks.isEmpty {
            Text("Not enough history yet.")
                .font(SLType.body(13))
                .foregroundColor(SLTheme.inkFaint)
        } else {
            SLBarChart(values: weeks.map { $0.logged == 0 ? nil : $0.value },
                       labels: weeks.map { SLTimeFormat.shortDate($0.start, timeZoneID: zone) },
                       height: 118)
        }
    }

    // MARK: Trend

    @ViewBuilder
    private func trendChart(_ stats: SLStatistics, zone: String) -> some View {
        let span = trendSpans[safe: trendIndex] ?? 30
        let window = trendWindows[safe: trendIndex] ?? 7
        let series = stats.dailySeries(days: span)
        let smoothed = stats.smoothed(series, window: window)
        if let first = series.first, let last = series.last {
            SLTrendLine(values: smoothed,
                        height: 132,
                        leadingLabel: SLTimeFormat.shortDate(first.date, timeZoneID: zone),
                        trailingLabel: SLTimeFormat.shortDate(last.date, timeZoneID: zone))
        } else {
            Text("Not enough history yet.")
                .font(SLType.body(13))
                .foregroundColor(SLTheme.inkFaint)
        }
    }

    // MARK: Six-month strip

    /// Capped so the strip cannot grow past the fixed height of its own frame on a wide
    /// screen — an uncapped square would overflow downwards and smear over the legend.
    private static let stripCellCap: CGFloat = 13
    private static let stripSpacing: CGFloat = 2

    @ViewBuilder
    private func historyStrip(_ stats: SLStatistics) -> some View {
        let weekCount = 26
        let cal = store.place.calendar()
        let weekStart = store.settings.weekStart
        let thisWeek = stats.startOfWeek(containing: stats.referenceDay, weekStart: weekStart)

        GeometryReader { proxy in
            let width = SLMetric.safeWidth(proxy.size.width)
            let spacing = SLStatsTab.stripSpacing
            let cell = min(SLStatsTab.stripCellCap,
                           max(4, (width - spacing * CGFloat(weekCount - 1)) / CGFloat(weekCount)))
            HStack(spacing: spacing) {
                ForEach(0..<weekCount, id: \.self) { weekOffset in
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { dayOffset in
                            let date = thisWeek.flatMap {
                                cal.date(byAdding: .day,
                                         value: -7 * (weekCount - 1 - weekOffset) + dayOffset,
                                         to: $0)
                            }
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(colour(for: date, stats: stats))
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            .frame(width: width, alignment: .leading)
        }
        .frame(height: 7 * SLStatsTab.stripCellCap + 6 * SLStatsTab.stripSpacing)
    }

    private func colour(for date: Date?, stats: SLStatistics) -> Color {
        guard let date = date else { return Color.clear }
        if stats.isFuture(date) { return SLTheme.surfaceAlt }
        return SLTheme.heat(stats.record(on: date)?.ringFraction ?? 0)
    }

    // MARK: Weekday

    @ViewBuilder
    private func weekdayChart(_ stats: SLStatistics) -> some View {
        let order = (0..<7).map { ($0 + store.settings.weekStart.calendarWeekday - 1) % 7 }
        VStack(alignment: .leading, spacing: 10) {
            SLBarChart(values: order.map { stats.weekdayRates[$0] },
                       labels: store.settings.weekStart.dayInitials,
                       height: 100,
                       highlightLast: false)
            if let best = stats.bestWeekday {
                Text("Your strongest day is \(SLStatsTab.weekdayName(best)), by the share of prayers marked on time or in congregation.")
                    .font(SLType.caption(11.5))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("A best day appears once there is enough logged for the comparison to mean anything.")
                    .font(SLType.caption(11.5))
                    .foregroundColor(SLTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    static func weekdayName(_ calendarWeekday: Int) -> String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let index = max(0, min(6, calendarWeekday - 1))
        return names[index]
    }

    // MARK: Notable

    @ViewBuilder
    private func notable(_ stats: SLStatistics, zone: String) -> some View {
        SLRowGroup {
            notableRow(title: "Strongest prayer",
                       value: stats.strongestPrayer.map { "\($0.name)  ·  \(SLStatistics.percentText(stats.punctualRate($0)))" } ?? "Not enough logged",
                       detail: "Highest share marked on time or in congregation.")
            SLDivider()
            notableRow(title: "Weakest prayer",
                       value: stats.weakestPrayer.map { "\($0.name)  ·  \(SLStatistics.percentText(stats.punctualRate($0)))" } ?? "Not enough logged",
                       detail: "The one worth putting attention on next.")
            SLDivider()
            notableRow(title: "Earliest Fajr logged",
                       value: fajrText(stats.earliestFajr, zone: zone),
                       detail: "The calculated dawn on the earliest morning you recorded a Fajr.")
            SLDivider()
            notableRow(title: "Latest Fajr logged",
                       value: fajrText(stats.latestFajr, zone: zone),
                       detail: "The calculated dawn on the latest such morning.")
            SLDivider()
            notableRow(title: "Days recorded",
                       value: "\(stats.totalDaysLogged)",
                       detail: "Days carrying at least one mark.")
            SLDivider()
            notableRow(title: "Milestones unlocked",
                       value: "\(SLMilestoneLibrary.unlockedCount(stats: stats, qadaPaid: store.qadaTotalPaid)) of \(SLMilestoneLibrary.count)",
                       detail: "The full list lives in the Guide tab.")
        }
    }

    private func fajrText(_ value: (day: Date, minutes: Double)?, zone: String) -> String {
        guard let value = value else { return "—" }
        let hour = Int(value.minutes / 60) % 24
        let minute = Int(value.minutes.truncatingRemainder(dividingBy: 60))
        let clock: String
        switch store.clockStyle {
        case .twentyFourHour:
            clock = String(format: "%02d:%02d", hour, max(0, minute))
        case .twelveHour:
            var h = hour % 12
            if h == 0 { h = 12 }
            clock = String(format: "%d:%02d %@", h, max(0, minute), hour < 12 ? "AM" : "PM")
        }
        return "\(clock)  ·  \(SLTimeFormat.shortDate(value.day, timeZoneID: zone))"
    }

    @ViewBuilder
    private func notableRow(title: String, value: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(SLType.bodyMedium(14))
                    .foregroundColor(SLTheme.ink)
                Text(detail)
                    .font(SLType.caption(11))
                    .foregroundColor(SLTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(value)
                .font(SLType.bodyMedium(13))
                .foregroundColor(SLTheme.teal)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

extension Array {
    /// Bounds-checked subscript. Used wherever an index comes from a segmented control or
    /// a stored preference that a future build could widen.
    subscript(safe index: Int) -> Element? {
        (index >= 0 && index < count) ? self[index] : nil
    }
}
