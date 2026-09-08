import SwiftUI

struct SLCalendarTab: View {
    @EnvironmentObject private var store: SLStore
    @State private var monthAnchor: Date? = nil
    @State private var selectedDay: Date? = nil

    var body: some View {
        ZStack {
            content
            if let day = selectedDay {
                SLDayEditorScreen(day: day, onBack: { close() })
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) { selectedDay = nil }
    }

    private var calendar: Calendar { store.place.calendar() }

    private var anchor: Date {
        monthAnchor ?? store.recordDay(for: Date())
    }

    private var content: some View {
        let stats = store.statistics()
        let zone = store.timeZoneID
        let rows = stats.monthGrid(monthContaining: anchor, weekStart: store.settings.weekStart)
        let summary = monthSummary(rows: rows, stats: stats)

        return VStack(spacing: 0) {
            SLHeader(title: "Calendar",
                     subtitle: "Open any past day to correct it")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    monthBar(zone: zone)

                    SLCard(padding: 14) {
                        VStack(spacing: 12) {
                            SLHeatGrid(rows: rows,
                                       weekInitials: store.settings.weekStart.dayInitials,
                                       fractionFor: { date in stats.record(on: date)?.ringFraction },
                                       isToday: { stats.isToday($0) },
                                       isFuture: { stats.isFuture($0) },
                                       dayNumber: { calendar.component(.day, from: $0) },
                                       onSelect: { date in
                                           withAnimation(.easeOut(duration: 0.2)) { selectedDay = date }
                                       })
                            SLHeatLegend()
                        }
                    }

                    SLSectionTitle(text: "This month")

                    HStack(spacing: 10) {
                        SLStatTile(value: "\(summary.complete)", caption: "Complete days")
                        SLStatTile(value: "\(summary.logged)", caption: "Days with a mark")
                        SLStatTile(value: SLStatistics.percentText(summary.punctualRate),
                                   caption: "On time this month",
                                   tint: SLTheme.clay)
                    }

                    if summary.logged == 0 {
                        SLEmptyNote(title: "Nothing recorded in this month",
                                    message: "Tap any day that is not in the future to open it and fill it in. Days you have not opened stay blank rather than counting as missed.")
                    }

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

    // MARK: Month bar

    @ViewBuilder
    private func monthBar(zone: String) -> some View {
        let canGoForward = !isCurrentMonth
        HStack(spacing: 10) {
            Button(action: { step(-1) }) {
                SLChevronIcon(direction: .left, size: 15, color: SLTheme.teal, weight: 2.2)
                    .frame(width: 40, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(SLTheme.surface)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(SLTimeFormat.monthTitle(anchor, timeZoneID: zone))
                .font(SLType.title(18))
                .foregroundColor(SLTheme.ink)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Button(action: { if canGoForward { step(1) } }) {
                SLChevronIcon(direction: .right, size: 15,
                              color: canGoForward ? SLTheme.teal : SLTheme.stateBlank, weight: 2.2)
                    .frame(width: 40, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(SLTheme.surface)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }

    private var isCurrentMonth: Bool {
        let today = store.recordDay(for: Date())
        return calendar.isDate(anchor, equalTo: today, toGranularity: .month)
    }

    private func step(_ months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: anchor) else { return }
        monthAnchor = next
    }

    // MARK: Summary

    private func monthSummary(rows: [[Date?]], stats: SLStatistics) -> (complete: Int, logged: Int, punctualRate: Double?) {
        var complete = 0
        var logged = 0
        var punctual = 0
        var marked = 0
        for row in rows {
            for case let date? in row {
                guard !stats.isFuture(date), let record = stats.record(on: date) else { continue }
                logged += 1
                if record.isComplete { complete += 1 }
                punctual += record.punctualCount
                marked += record.markedCount
            }
        }
        let rate: Double? = marked > 0 ? Double(punctual) / Double(marked) : nil
        return (complete, logged, rate)
    }
}

// MARK: - Back-fill editor for one day

struct SLDayEditorScreen: View {
    @EnvironmentObject private var store: SLStore
    let day: Date
    let onBack: () -> Void
    @State private var showClearConfirm = false

    var body: some View {
        let zone = store.timeZoneID
        let schedule = store.schedule(for: day)
        let record = store.record(for: day)
        let isFriday = SLTimeFormat.isFriday(day, timeZoneID: zone)

        return SLDetailScreen(title: SLTimeFormat.mediumDate(day, timeZoneID: zone),
                              subtitle: store.settings.showHijri
                                  ? SLHijri.text(for: day, timeZoneID: zone)
                                  : store.city.displayName,
                              onBack: onBack) {

            HStack(alignment: .center, spacing: 16) {
                SLCompletionRing(record: record,
                                 diameter: 96,
                                 lineWidth: 10,
                                 centreTitle: "\(record.performedCount)/5",
                                 centreCaption: record.isComplete ? "complete" : "recorded")
                VStack(alignment: .leading, spacing: 5) {
                    Text(record.isComplete ? "Complete day" : "Not complete")
                        .font(SLType.title(16))
                        .foregroundColor(record.isComplete ? SLTheme.stateJamaah : SLTheme.inkSoft)
                    Text("\(record.congregationCount) in congregation  ·  \(record.punctualCount) on time  ·  \(record.missedCount) missed")
                        .font(SLType.caption(11.5))
                        .foregroundColor(SLTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    if record.naflCount > 0 {
                        Text("\(record.naflCount) voluntary prayer\(record.naflCount == 1 ? "" : "s")")
                            .font(SLType.caption(11.5))
                            .foregroundColor(SLTheme.inkFaint)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .fill(SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .stroke(SLTheme.hairline, lineWidth: 1)
            )

            if let polarNote = schedule.polarNote {
                SLEmptyNote(title: "Some times cannot be computed on this date",
                            message: polarNote)
            }

            SLSectionTitle(text: "The five prayers",
                           trailing: "times calculated for this date")

            VStack(spacing: 10) {
                ForEach(SLPrayer.allCases) { prayer in
                    let window = schedule.window(for: prayer)
                    SLPrayerCard(
                        prayer: prayer,
                        displayName: (isFriday && prayer == .dhuhr) ? prayer.fridayName : prayer.name,
                        state: record.state(prayer),
                        startText: SLTimeFormat.clock(window.start, style: store.clockStyle, timeZoneID: zone),
                        windowText: window.start == nil
                            ? schedule.absenceReason(for: prayer)
                            : "\(prayer.transliteration)  ·  until \(SLTimeFormat.clock(window.end, style: store.clockStyle, timeZoneID: zone))",
                        statusText: "",
                        statusTint: SLTheme.inkFaint,
                        isActive: false,
                        adjusted: window.adjusted,
                        unavailable: window.start == nil,
                        onMark: { option in store.mark(option, prayer: prayer, on: day) }
                    )
                }
            }

            if store.settings.trackNawafil {
                SLSectionTitle(text: "Voluntary prayers")
                VStack(spacing: 8) {
                    ForEach(SLNafl.allCases) { item in
                        naflRow(item, record: record)
                    }
                }
            }

            SLSectionTitle(text: "Corrections")
            SLCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tapping a mark that is already set clears it. Clearing the whole day removes it from your history entirely, as though it had never been opened.")
                        .font(SLType.body(13))
                        .foregroundColor(SLTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    if showClearConfirm {
                        HStack(spacing: 8) {
                            SLPrimaryButton(title: "Yes, clear this day", tint: SLTheme.stateMissed) {
                                store.clearDay(day)
                                showClearConfirm = false
                            }
                            SLQuietButton(title: "Cancel") { showClearConfirm = false }
                        }
                    } else {
                        SLQuietButton(title: "Clear this day", tint: SLTheme.stateMissed) {
                            showClearConfirm = true
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func naflRow(_ item: SLNafl, record: SLDayRecord) -> some View {
        let on = record.nafl(item)
        Button(action: { store.toggleNafl(item, on: day) }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(on ? SLTheme.stateJamaah : SLTheme.canvasDeep)
                        .frame(width: 22, height: 22)
                    if on {
                        SLCheckMark()
                            .stroke(SLTheme.surface, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 15, height: 15)
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(SLType.bodyMedium(14))
                        .foregroundColor(SLTheme.ink)
                    Text(item.subtitle)
                        .font(SLType.caption(11))
                        .foregroundColor(SLTheme.inkFaint)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(on ? SLTheme.stateJamaah.opacity(0.5) : SLTheme.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
