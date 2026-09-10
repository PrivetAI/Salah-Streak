import SwiftUI

enum SLSettingsRoute: Identifiable {
    case city
    case method
    case highLatitude
    case offsets

    var id: Int {
        switch self {
        case .city: return 0
        case .method: return 1
        case .highLatitude: return 2
        case .offsets: return 3
        }
    }
}

struct SLSettingsTab: View {
    @EnvironmentObject private var store: SLStore
    @State private var route: SLSettingsRoute? = nil
    @State private var showPrivacy = false
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            content
            if let route = route {
                Group {
                    switch route {
                    case .city: SLCityPickerScreen(onBack: close)
                    case .method: SLMethodPickerScreen(onBack: close)
                    case .highLatitude: SLHighLatitudePickerScreen(onBack: close)
                    case .offsets: SLOffsetsScreen(onBack: close)
                    }
                }
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        // The Privacy Policy sheet loads the panel directly, with no launch check of its
        // own. It passes no tracker host, which is what stops it being remembered as the
        // address the next cold start resumes.
        .sheet(isPresented: $showPrivacy) {
            // Wrapped so there is a visible Done. The grabber alone does work, but this
            // is the one screen where a reviewer could believe they are stuck.
            NavigationView {
                SalahWebPanel(address: SalahLinks.sourceLink)
                    .edgesIgnoringSafeArea(.bottom)
                    .navigationBarTitle("Privacy Policy", displayMode: .inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showPrivacy = false }
                        }
                    }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) { route = nil }
    }

    private func open(_ target: SLSettingsRoute) {
        withAnimation(.easeOut(duration: 0.2)) { route = target }
    }

    private var content: some View {
        let settings = store.settings

        return VStack(spacing: 0) {
            SLHeader(title: "Settings",
                     subtitle: "Match the app to your mosque, then leave it alone")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    SLSectionTitle(text: "Place")
                    SLRowGroup {
                        SLNavRow(title: "City",
                                 value: store.city.name,
                                 detail: "\(store.city.country)  ·  \(store.city.coordinateLine)",
                                 action: { open(.city) })
                        SLDivider()
                        infoRow(title: "Time zone",
                                value: store.city.timeZoneID,
                                detail: "All times are worked out in this zone, not in your device's.")
                    }

                    SLSectionTitle(text: "Calculation")
                    SLRowGroup {
                        SLNavRow(title: "Method",
                                 value: settings.method.name,
                                 detail: settings.method.angleLine,
                                 action: { open(.method) })
                        SLDivider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Asr school")
                                .font(SLType.bodyMedium(15))
                                .foregroundColor(SLTheme.ink)
                            SLSegmented(options: SLAsrSchool.allCases.map { $0.title },
                                        selection: settings.asrSchool.rawValue,
                                        onSelect: { index in
                                            store.updateSettings { draft in
                                                draft.asrSchool = SLAsrSchool(rawValue: index) ?? .standard
                                            }
                                        })
                            Text(settings.asrSchool.explanation)
                                .font(SLType.caption(11.5))
                                .foregroundColor(SLTheme.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        SLDivider()
                        SLNavRow(title: "High-latitude rule",
                                 value: settings.highLatRule.shortTitle,
                                 detail: "Used where the sun never reaches the twilight angle.",
                                 action: { open(.highLatitude) })
                        SLDivider()
                        SLNavRow(title: "Per-prayer adjustments",
                                 value: offsetSummary,
                                 detail: "Shift any prayer by up to thirty minutes to match your mosque.",
                                 action: { open(.offsets) })
                    }

                    SLSectionTitle(text: "Display")
                    SLRowGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Clock")
                                .font(SLType.bodyMedium(15))
                                .foregroundColor(SLTheme.ink)
                            SLSegmented(options: SLClockStyle.allCases.map { $0.title },
                                        selection: settings.clockStyle.rawValue,
                                        onSelect: { index in
                                            store.updateSettings { draft in
                                                draft.clockStyle = SLClockStyle(rawValue: index) ?? .twelveHour
                                            }
                                        })
                        }
                        .padding(14)
                        SLDivider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week starts on")
                                .font(SLType.bodyMedium(15))
                                .foregroundColor(SLTheme.ink)
                            SLSegmented(options: SLWeekStart.allCases.map { $0.title },
                                        selection: settings.weekStart.rawValue,
                                        onSelect: { index in
                                            store.updateSettings { draft in
                                                draft.weekStart = SLWeekStart(rawValue: index) ?? .monday
                                            }
                                        })
                        }
                        .padding(14)
                        SLDivider()
                        SLSwitchRow(title: "Show the Hijri date",
                                    detail: "Umm al-Qura reckoning, as the system provides it. A local moon sighting may differ by a day.",
                                    isOn: settings.showHijri,
                                    action: { store.updateSettings { $0.showHijri.toggle() } })
                        SLDivider()
                        SLSwitchRow(title: "Track voluntary prayers",
                                    detail: "Shows the Witr, Tahajjud, Duha and sunnah toggles on the Today screen.",
                                    isOn: settings.trackNawafil,
                                    action: { store.updateSettings { $0.trackNawafil.toggle() } })
                    }

                    SLSectionTitle(text: "About")
                    SLRowGroup {
                        SLNavRow(title: "Privacy Policy",
                                 value: nil,
                                 detail: "Opens in a panel inside the app.",
                                 action: { showPrivacy = true })
                        SLDivider()
                        infoRow(title: "Version", value: "1.0", detail: "Salah Streak")
                        SLDivider()
                        infoRow(title: "Reminders",
                                value: "None",
                                detail: "This app sends no notifications of any kind and never asks for permission to.")
                    }

                    SLSectionTitle(text: "Data")
                    SLCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Everything you record lives in this app on this device. Resetting removes every mark, the make-up ledger and every setting, and cannot be undone.")
                                .font(SLType.body(13))
                                .foregroundColor(SLTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            if confirmReset {
                                VStack(spacing: 8) {
                                    Text("This will erase \(store.statistics().totalDaysLogged) recorded day\(store.statistics().totalDaysLogged == 1 ? "" : "s").")
                                        .font(SLType.label(12.5))
                                        .foregroundColor(SLTheme.stateMissed)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    HStack(spacing: 8) {
                                        SLPrimaryButton(title: "Erase everything", tint: SLTheme.stateMissed) {
                                            store.resetEverything()
                                            confirmReset = false
                                        }
                                        SLQuietButton(title: "Cancel") { confirmReset = false }
                                    }
                                }
                            } else {
                                SLQuietButton(title: "Reset all data", tint: SLTheme.stateMissed) {
                                    confirmReset = true
                                }
                            }
                        }
                    }

                    SLCalculationNote()
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

    private var offsetSummary: String {
        let active = SLPrayer.allCases.filter { store.offset(for: $0) != 0 }
        if active.isEmpty { return "None" }
        if active.count == 1, let only = active.first {
            let value = store.offset(for: only)
            return "\(only.name) \(value > 0 ? "+" : "")\(value) min"
        }
        return "\(active.count) set"
    }

    @ViewBuilder
    private func infoRow(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(SLType.bodyMedium(15))
                    .foregroundColor(SLTheme.ink)
                Spacer(minLength: 8)
                Text(value)
                    .font(SLType.body(13.5))
                    .foregroundColor(SLTheme.inkSoft)
                    .multilineTextAlignment(.trailing)
            }
            Text(detail)
                .font(SLType.caption(11))
                .foregroundColor(SLTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - City picker

struct SLCityPickerScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            SLHeader(title: "City",
                     subtitle: "\(SLCityTable.count) places. No location permission is ever requested.",
                     onBack: onBack)

            searchField
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .frame(maxWidth: SLMetric.readableWidth)
                .frame(maxWidth: .infinity)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {
                    if query.trimmingCharacters(in: .whitespaces).isEmpty {
                        ForEach(SLCityTable.grouped(), id: \.region.id) { section in
                            SLSectionTitle(text: section.region.title, trailing: "\(section.cities.count)")
                            SLRowGroup {
                                ForEach(section.cities) { city in
                                    cityRow(city)
                                    if city.id != section.cities.last?.id { SLDivider() }
                                }
                            }
                        }
                    } else {
                        let results = SLCityTable.search(query)
                        if results.isEmpty {
                            SLEmptyNote(title: "No match",
                                        message: "Nothing in the list matches \u{201C}\(query)\u{201D}. Try a country name, or the nearest larger city — a few tens of kilometres change the times by less than a minute.")
                        } else {
                            SLSectionTitle(text: "Results", trailing: "\(results.count)")
                            SLRowGroup {
                                ForEach(results) { city in
                                    cityRow(city)
                                    if city.id != results.last?.id { SLDivider() }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: SLMetric.readableWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(SLTheme.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: 10) {
            SLSearchGlyph()
                .stroke(SLTheme.inkFaint, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 17, height: 17)
            TextField("Search a city or country", text: $query)
                .font(SLType.body(15))
                .foregroundColor(SLTheme.ink)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .focused($searchFocused)
            if !query.isEmpty {
                Button(action: { query = ""; searchFocused = false }) {
                    SLCrossMark()
                        .stroke(SLTheme.inkFaint, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                        .frame(width: 15, height: 15)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(SLTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(searchFocused ? SLTheme.teal.opacity(0.5) : SLTheme.hairline, lineWidth: 1)
        )
        // The whole field is a tap target, not just the text run inside it.
        .contentShape(Rectangle())
        .onTapGesture { searchFocused = true }
    }

    @ViewBuilder
    private func cityRow(_ city: SLCity) -> some View {
        let selected = city.id == store.settings.cityID
        Button(action: {
            store.updateSettings { $0.cityID = city.id }
            searchFocused = false
            onBack()
        }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(SLType.bodyMedium(15))
                        .foregroundColor(SLTheme.ink)
                    Text("\(city.country)  ·  \(city.coordinateLine)")
                        .font(SLType.caption(11))
                        .foregroundColor(SLTheme.inkFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 8)
                if selected {
                    SLCheckMark()
                        .stroke(SLTheme.teal, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 17, height: 17)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? SLTheme.tealWash.opacity(0.55) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Method picker

struct SLMethodPickerScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    var body: some View {
        SLDetailScreen(title: "Calculation method",
                       subtitle: "The angles are shown so the choice is an informed one",
                       onBack: onBack) {

            SLCard(fill: SLTheme.surfaceAlt) {
                Text(SLAboutText.theAngles)
                    .font(SLType.body(13.5))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(SLMethodCatalogue.all) { method in
                    methodRow(method)
                }
            }

            SLEmptyNote(title: "Which one should I pick?",
                        message: "Whichever your local mosque uses. If you do not know, ask — and until you do, the Muslim World League angles are the most widely applicable default.")
        }
    }

    @ViewBuilder
    private func methodRow(_ method: SLMethod) -> some View {
        let selected = method.id == store.settings.methodID
        Button(action: {
            store.updateSettings { $0.methodID = method.id }
            onBack()
        }) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .center, spacing: 10) {
                    Text(method.name)
                        .font(SLType.title(16))
                        .foregroundColor(SLTheme.ink)
                    Spacer(minLength: 6)
                    if selected {
                        SLCheckMark()
                            .stroke(SLTheme.teal, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            .frame(width: 17, height: 17)
                    }
                }
                HStack(spacing: 8) {
                    SLPill(text: "Fajr \(method.fajrLabel)")
                    SLPill(text: "Isha \(method.ishaLabel)", tint: SLTheme.goldDeep, fill: SLTheme.gold.opacity(0.22))
                }
                Text(method.authority)
                    .font(SLType.caption(11.5))
                    .foregroundColor(SLTheme.teal)
                Text(method.summary)
                    .font(SLType.body(13))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Common in: \(method.region)")
                    .font(SLType.caption(11))
                    .foregroundColor(SLTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .fill(selected ? SLTheme.tealWash.opacity(0.55) : SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .stroke(selected ? SLTheme.teal.opacity(0.45) : SLTheme.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - High latitude picker

struct SLHighLatitudePickerScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    var body: some View {
        SLDetailScreen(title: "High-latitude rule",
                       subtitle: "What to do when the sun never reaches the angle",
                       onBack: onBack) {

            SLCard(fill: SLTheme.surfaceAlt) {
                Text(SLAboutText.highLatitude)
                    .font(SLType.body(13.5))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(SLHighLatRule.allCases, id: \.rawValue) { rule in
                    ruleRow(rule)
                }
            }

            SLEmptyNote(title: "Polar day and polar night",
                        message: "Where the sun does not rise or does not set at all, there is no night to divide and no rule can help. On those dates this app prints a dash next to Fajr and Isha and explains why, rather than showing a number it cannot stand behind. Communities at those latitudes generally follow the timetable of the nearest city where the twilight still occurs, or that of Makkah.")
        }
    }

    @ViewBuilder
    private func ruleRow(_ rule: SLHighLatRule) -> some View {
        let selected = rule == store.settings.highLatRule
        Button(action: {
            store.updateSettings { $0.highLatRule = rule }
            onBack()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(rule.title)
                        .font(SLType.title(16))
                        .foregroundColor(SLTheme.ink)
                    Spacer(minLength: 6)
                    if selected {
                        SLCheckMark()
                            .stroke(SLTheme.teal, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            .frame(width: 17, height: 17)
                    }
                }
                Text(rule.explanation)
                    .font(SLType.body(13))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .fill(selected ? SLTheme.tealWash.opacity(0.55) : SLTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLMetric.cardRadius, style: .continuous)
                    .stroke(selected ? SLTheme.teal.opacity(0.45) : SLTheme.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Per-prayer offsets

struct SLOffsetsScreen: View {
    @EnvironmentObject private var store: SLStore
    let onBack: () -> Void

    var body: some View {
        let zone = store.timeZoneID
        let schedule = store.schedule(for: store.recordDay(for: Date()))

        return SLDetailScreen(title: "Per-prayer adjustments",
                              subtitle: "Line the app up with your mosque, minute by minute",
                              onBack: onBack) {

            SLCard(fill: SLTheme.surfaceAlt) {
                Text("A mosque often adds a minute or two of caution, or follows a slightly different convention for one prayer. Rather than change the whole method, shift that one prayer here. The adjustment applies to every day, past and future, and the calculated times shown beside each row already include it.")
                    .font(SLType.body(13.5))
                    .foregroundColor(SLTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(SLPrayer.allCases) { prayer in
                    offsetRow(prayer, schedule: schedule, zone: zone)
                }
            }

            SLQuietButton(title: "Set every prayer back to zero") {
                for prayer in SLPrayer.allCases { store.setOffset(0, for: prayer) }
            }

            SLCalculationNote()
        }
    }

    @ViewBuilder
    private func offsetRow(_ prayer: SLPrayer, schedule: SLSchedule, zone: String) -> some View {
        let value = store.offset(for: prayer)
        HStack(spacing: 12) {
            prayer.glyph(size: 22, color: SLTheme.tealSoft, weight: 1.7)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.name)
                    .font(SLType.bodyMedium(15))
                    .foregroundColor(SLTheme.ink)
                Text("today: \(SLTimeFormat.clock(schedule.window(for: prayer).start, style: store.clockStyle, timeZoneID: zone))")
                    .font(SLType.caption(11))
                    .foregroundColor(SLTheme.inkFaint)
            }
            Spacer(minLength: 6)
            SLStepper(value: value,
                      range: -30...30,
                      format: { $0 > 0 ? "+\($0) min" : "\($0) min" },
                      onChange: { store.setOffset($0, for: prayer) })
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(SLTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(SLTheme.hairline, lineWidth: 1)
        )
    }
}
