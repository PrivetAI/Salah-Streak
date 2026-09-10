import SwiftUI

// MARK: - One prayer's card

/// Takes only value types. Handing this view the store and letting it read a field would
/// mean SwiftUI comparing a class reference that never changes identity, and the card
/// would keep its old mark on screen after a tap.
struct SLPrayerCard: View {
    let prayer: SLPrayer
    let displayName: String
    let state: SLPrayerState
    let startText: String
    let windowText: String
    let statusText: String
    let statusTint: Color
    let isActive: Bool
    let adjusted: Bool
    let unavailable: Bool
    let onMark: (SLPrayerState) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                prayer.glyph(size: 26, color: isActive ? SLTheme.clay : SLTheme.tealSoft, weight: 1.8)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(SLType.title(17))
                            .foregroundColor(SLTheme.ink)
                        if isActive {
                            SLPill(text: "Now", tint: SLTheme.clay, fill: SLTheme.claySoft)
                        }
                    }
                    Text(windowText)
                        .font(SLType.caption(11.5))
                        .foregroundColor(SLTheme.inkFaint)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(startText)
                        .font(SLType.mono(17))
                        .foregroundColor(unavailable ? SLTheme.inkFaint : SLTheme.teal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(statusText)
                        .font(SLType.caption(10.5))
                        .foregroundColor(statusTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            if adjusted {
                Text("High-latitude rule applied — the sun does not reach this angle here today.")
                    .font(SLType.caption(10.5))
                    .foregroundColor(SLTheme.goldDeep)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                ForEach(SLPrayerState.markable, id: \.rawValue) { option in
                    SLMarkButton(option: option,
                                 selected: option == state,
                                 action: { onMark(option) })
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                .fill(SLTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                .stroke(isActive ? SLTheme.clay.opacity(0.55) : SLTheme.hairline,
                        lineWidth: isActive ? 1.6 : 1)
        )
    }
}

/// One of the four marks. A plain button, never nested inside another button.
struct SLMarkButton: View {
    let option: SLPrayerState
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                SLStateMark(kind: option,
                            size: 17,
                            color: selected ? SLTheme.surface : option.colour)
                Text(option.shortTitle)
                    .font(SLType.label(10))
                    .foregroundColor(selected ? SLTheme.surface : SLTheme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? option.colour : SLTheme.canvasDeep)
            )
            // The label is a shape plus text over a fill; the explicit hit shape keeps
            // the whole tile tappable rather than only the glyph strokes.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
    }
}

// MARK: - The Today tab

struct SLTodayTab: View {
    @EnvironmentObject private var store: SLStore
    @State private var now = Date()
    @State private var route: Route? = nil

    private enum Route: Identifiable {
        case qada
        case streaks
        var id: Int { self == .qada ? 0 : 1 }
    }

    /// Twenty seconds is fine for a countdown printed to the minute, and it keeps the
    /// engine off the main thread's critical path.
    private let ticker = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            content
            if let route = route {
                Group {
                    switch route {
                    case .qada: SLQadaScreen(onBack: { closeRoute() })
                    case .streaks: SLStreakScreen(onBack: { closeRoute() })
                    }
                }
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .onReceive(ticker) { value in now = value }
    }

    private func closeRoute() {
        withAnimation(.easeOut(duration: 0.2)) { route = nil }
    }

    private func open(_ target: Route) {
        withAnimation(.easeOut(duration: 0.2)) { route = target }
    }

    private var content: some View {
        let recordDay = store.recordDay(for: now)
        let schedule = store.schedule(for: recordDay)
        let record = store.record(for: recordDay)
        let stats = store.statistics()
        let zone = store.timeZoneID
        let isFriday = SLTimeFormat.isFriday(recordDay, timeZoneID: zone)
        let civilToday = store.place.calendar().startOfDay(for: now)
        let loggingPreviousDay = recordDay < civilToday

        return VStack(spacing: 0) {
            SLHeader(title: "Today",
                     subtitle: headerSubtitle(recordDay: recordDay, zone: zone))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    heroCard(record: record, schedule: schedule, stats: stats)

                    if loggingPreviousDay {
                        SLEmptyNote(title: "Still on \(SLTimeFormat.mediumDate(recordDay, timeZoneID: zone))",
                                    message: "Isha's window runs until the next dawn, so anything you mark now is filed against yesterday. The day turns over at Fajr.")
                    }

                    SLCalculationNote(compact: true)

                    if let polarNote = schedule.polarNote {
                        SLEmptyNote(title: "Some times cannot be computed today",
                                    message: polarNote)
                    }

                    SLSectionTitle(text: "The five prayers",
                                   trailing: store.city.name)

                    VStack(spacing: 10) {
                        ForEach(SLPrayer.allCases) { prayer in
                            card(for: prayer, schedule: schedule, record: record,
                                 isFriday: isFriday, day: recordDay)
                        }
                    }

                    sunriseRow(schedule: schedule)

                    if store.settings.trackNawafil {
                        SLSectionTitle(text: "Voluntary prayers")
                        naflGrid(record: record, day: recordDay)
                    }

                    SLSectionTitle(text: "Make-up ledger")
                    SLRowGroup {
                        SLNavRow(title: "Qada ledger",
                                 value: store.qadaTotalOutstanding == 0 ? "Clear" : "\(store.qadaTotalOutstanding) owed",
                                 detail: "Every prayer you mark as missed is added here until you make it up.",
                                 action: { open(.qada) })
                        SLDivider()
                        SLNavRow(title: "Streaks in detail",
                                 value: "\(stats.currentStreak) day\(stats.currentStreak == 1 ? "" : "s")",
                                 detail: "Per-prayer runs and what counts as a complete day.",
                                 action: { open(.streaks) })
                    }

                    passageCard(day: recordDay, zone: zone)
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

    private func headerSubtitle(recordDay: Date, zone: String) -> String {
        var parts = [SLTimeFormat.longDate(recordDay, timeZoneID: zone)]
        if store.settings.showHijri {
            parts.append(SLHijri.text(for: recordDay, timeZoneID: zone))
        }
        return parts.joined(separator: "  ·  ")
    }

    // MARK: Hero

    @ViewBuilder
    private func heroCard(record: SLDayRecord, schedule: SLSchedule, stats: SLStatistics) -> some View {
        GeometryReader { proxy in
            let width = SLMetric.safeWidth(proxy.size.width)
            let compact = SLMetric.isCompact(width)
            let ringSize: CGFloat = compact ? 106 : 124

            HStack(alignment: .center, spacing: compact ? 12 : 18) {
                SLCompletionRing(record: record,
                                 diameter: ringSize,
                                 lineWidth: compact ? 11 : 13,
                                 centreTitle: "\(record.performedCount)/5",
                                 centreCaption: record.isComplete ? "complete" : "recorded")

                let upcoming = nextLine(schedule: schedule)
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(stats.currentStreak)")
                            .font(SLType.display(compact ? 26 : 32))
                            .foregroundColor(SLTheme.clay)
                        Text("day streak")
                            .font(SLType.caption(11))
                            .foregroundColor(SLTheme.inkFaint)
                    }
                    SLOrnamentRule(width: 88)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(upcoming.0)
                            .font(SLType.label(11))
                            .foregroundColor(SLTheme.inkFaint)
                        Text(upcoming.1)
                            .font(SLType.title(compact ? 15 : 17))
                            .foregroundColor(SLTheme.teal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(compact ? 12 : 16)
            // Fill the reader, not just the content's natural height: a GeometryReader
            // aligns its child top-leading, so a ~126 pt card inside the 166 pt floor
            // left about 40 pt of bare canvas showing under the hero.
            .frame(width: width, height: proxy.size.height, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .fill(SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .stroke(SLTheme.hairline, lineWidth: 1)
            )
        }
        // A fixed height keeps the flexible child from collapsing to nothing on a short
        // screen, which is what turns a hero block into a pile of overlapping text. The
        // widest case is the 124 pt ring plus 16 pt of padding either side; the rest is
        // slack so a wrapped label cannot push anything out of the card.
        .frame(height: 166)
    }

    private func nextLine(schedule: SLSchedule) -> (String, String) {
        guard let next = schedule.next(after: now) else {
            return ("Next prayer", "Not computable today")
        }
        let name = SLTimeFormat.isFriday(next.date, timeZoneID: store.timeZoneID)
            ? next.prayer.fridayName : next.prayer.name
        let clock = SLTimeFormat.clock(next.date, style: store.clockStyle, timeZoneID: store.timeZoneID)
        let remaining = SLTimeFormat.duration(next.date.timeIntervalSince(now))
        return ("Next  ·  in \(remaining)", "\(name) \(clock)")
    }

    // MARK: Prayer cards

    @ViewBuilder
    private func card(for prayer: SLPrayer, schedule: SLSchedule, record: SLDayRecord,
                      isFriday: Bool, day: Date) -> some View {
        let window = schedule.window(for: prayer)
        let zone = store.timeZoneID
        let state = record.state(prayer)
        let active = window.contains(now)
        let name = (isFriday && prayer == .dhuhr) ? prayer.fridayName : prayer.name

        SLPrayerCard(
            prayer: prayer,
            displayName: name,
            state: state,
            startText: SLTimeFormat.clock(window.start, style: store.clockStyle, timeZoneID: zone),
            windowText: windowText(window, schedule: schedule, zone: zone),
            statusText: statusText(window),
            statusTint: active ? SLTheme.clay : SLTheme.inkFaint,
            isActive: active,
            adjusted: window.adjusted,
            unavailable: window.start == nil,
            onMark: { option in store.mark(option, prayer: prayer, on: day) }
        )
    }

    private func windowText(_ window: SLWindow, schedule: SLSchedule, zone: String) -> String {
        guard window.start != nil else {
            return schedule.absenceReason(for: window.prayer)
        }
        guard let end = window.end else { return "Window open" }
        let endText = SLTimeFormat.clock(end, style: store.clockStyle, timeZoneID: zone)
        return "\(window.prayer.transliteration)  ·  until \(endText)"
    }

    private func statusText(_ window: SLWindow) -> String {
        guard let start = window.start else { return "—" }
        if now < start {
            return "in \(SLTimeFormat.duration(start.timeIntervalSince(now)))"
        }
        if let end = window.end, now < end {
            return "\(SLTimeFormat.duration(end.timeIntervalSince(now))) left"
        }
        return "window closed"
    }

    @ViewBuilder
    private func sunriseRow(schedule: SLSchedule) -> some View {
        HStack(spacing: 10) {
            SLSunriseGlyph()
                .stroke(SLTheme.goldDeep, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 20, height: 20)
            Text("Sunrise")
                .font(SLType.bodyMedium(13.5))
                .foregroundColor(SLTheme.inkSoft)
            Spacer(minLength: 8)
            Text(SLTimeFormat.clock(schedule.sunrise, style: store.clockStyle, timeZoneID: store.timeZoneID))
                .font(SLType.mono(14))
                .foregroundColor(SLTheme.inkSoft)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(SLTheme.surfaceAlt)
        )
    }

    // MARK: Voluntary prayers

    @ViewBuilder
    private func naflGrid(record: SLDayRecord, day: Date) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(stride(from: 0, to: SLNafl.allCases.count, by: 2)), id: \.self) { index in
                HStack(spacing: 8) {
                    naflChip(SLNafl.allCases[index], record: record, day: day)
                    if index + 1 < SLNafl.allCases.count {
                        naflChip(SLNafl.allCases[index + 1], record: record, day: day)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func naflChip(_ item: SLNafl, record: SLDayRecord, day: Date) -> some View {
        let on = record.nafl(item)
        Button(action: { store.toggleNafl(item, on: day) }) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(on ? SLTheme.stateJamaah : SLTheme.canvasDeep)
                        .frame(width: 20, height: 20)
                    if on {
                        SLCheckMark()
                            .stroke(SLTheme.surface, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 14, height: 14)
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(SLType.bodyMedium(12.5))
                        .foregroundColor(SLTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(item.subtitle)
                        .font(SLType.caption(9.5))
                        .foregroundColor(SLTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(on ? SLTheme.stateJamaah.opacity(0.5) : SLTheme.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Passage

    @ViewBuilder
    private func passageCard(day: Date, zone: String) -> some View {
        let passage = SLPassageLibrary.daily(for: day, timeZoneID: zone)
        SLCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Passage for today".uppercased())
                    .font(SLType.label(10))
                    .tracking(1.3)
                    .foregroundColor(SLTheme.inkFaint)
                Text(passage.text)
                    .font(SLType.quote(15.5))
                    .foregroundColor(SLTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text(passage.citation)
                        .font(SLType.label(11))
                        .foregroundColor(SLTheme.teal)
                    Spacer(minLength: 4)
                    Text("Pickthall, 1930")
                        .font(SLType.caption(10))
                        .foregroundColor(SLTheme.inkFaint)
                }
            }
        }
    }
}
