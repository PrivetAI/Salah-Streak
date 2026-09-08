import SwiftUI
import Combine

// MARK: - One day's record

/// Everything the user has told the app about a single day.
///
/// Both `Codable` conformances are written by hand. The synthesised `init(from:)` throws
/// the moment a key is absent, so adding one field in a later version would make every
/// stored day fail to decode and silently wipe a year of someone's history. Every field
/// here is read with `decodeIfPresent` and falls back to its default, from the first
/// version onwards — the cost is a few lines now instead of a support thread later.
struct SLDayRecord: Codable, Equatable {

    /// "yyyy-MM-dd" in the city's own zone.
    var key: String
    /// Five entries, indexed by `SLPrayer.rawValue`.
    var states: [Int]
    /// Eight entries, indexed by `SLNafl.rawValue`.
    var nawafil: [Bool]

    init(key: String) {
        self.key = key
        self.states = [Int](repeating: SLPrayerState.none.rawValue, count: SLPrayer.allCases.count)
        self.nawafil = [Bool](repeating: false, count: SLNafl.allCases.count)
    }

    enum CodingKeys: String, CodingKey {
        case key, states, nawafil
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        let storedKey = try? box.decodeIfPresent(String.self, forKey: .key)
        let storedStates = try? box.decodeIfPresent([Int].self, forKey: .states)
        let storedNawafil = try? box.decodeIfPresent([Bool].self, forKey: .nawafil)
        self.key = storedKey ?? ""
        let rawStates: [Int] = storedStates ?? []
        let rawNawafil: [Bool] = storedNawafil ?? []
        self.states = SLDayRecord.fit(rawStates,
                                      count: SLPrayer.allCases.count,
                                      fallback: SLPrayerState.none.rawValue)
        self.nawafil = SLDayRecord.fit(rawNawafil, count: SLNafl.allCases.count, fallback: false)
        // A stored state from a future version that this build does not know about is
        // read back as "not recorded" rather than crashing a chart on an unknown case.
        for i in 0..<self.states.count where SLPrayerState(rawValue: self.states[i]) == nil {
            self.states[i] = SLPrayerState.none.rawValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(key, forKey: .key)
        try box.encode(states, forKey: .states)
        try box.encode(nawafil, forKey: .nawafil)
    }

    /// Pads or trims a decoded array so an old save with fewer entries — or a newer one
    /// with more — can never index out of range.
    private static func fit<T>(_ raw: [T], count: Int, fallback: T) -> [T] {
        var out = [T](repeating: fallback, count: count)
        for i in 0..<min(count, raw.count) { out[i] = raw[i] }
        return out
    }

    func state(_ prayer: SLPrayer) -> SLPrayerState {
        let i = prayer.rawValue
        guard i >= 0, i < states.count else { return .none }
        return SLPrayerState(rawValue: states[i]) ?? .none
    }

    mutating func set(_ state: SLPrayerState, for prayer: SLPrayer) {
        let i = prayer.rawValue
        guard i >= 0, i < states.count else { return }
        states[i] = state.rawValue
    }

    func nafl(_ item: SLNafl) -> Bool {
        let i = item.rawValue
        guard i >= 0, i < nawafil.count else { return false }
        return nawafil[i]
    }

    mutating func setNafl(_ item: SLNafl, _ on: Bool) {
        let i = item.rawValue
        guard i >= 0, i < nawafil.count else { return }
        nawafil[i] = on
    }

    var markedCount: Int { SLPrayer.allCases.filter { state($0) != .none }.count }
    var performedCount: Int { SLPrayer.allCases.filter { state($0).isPerformed }.count }
    var punctualCount: Int { SLPrayer.allCases.filter { state($0).isPunctual }.count }
    var congregationCount: Int { SLPrayer.allCases.filter { state($0) == .congregation }.count }
    var missedCount: Int { SLPrayer.allCases.filter { state($0) == .missed }.count }
    var naflCount: Int { nawafil.filter { $0 }.count }
    var isEmpty: Bool { markedCount == 0 && naflCount == 0 }

    /// THE definition of a complete day, used by every streak in the app and printed in
    /// plain words on the Today screen and in Settings so it is never a mystery.
    var isComplete: Bool { performedCount == SLPrayer.allCases.count }

    /// Fraction of the completion ring this day fills.
    var ringFraction: Double {
        let total = Double(SLPrayer.allCases.count)
        guard total > 0 else { return 0 }
        let sum = SLPrayer.allCases.reduce(0.0) { $0 + state($1).ringWeight }
        return max(0, min(1, sum / total))
    }
}

// MARK: - Settings

struct SLSettings: Codable, Equatable {
    var methodID: Int = 0
    var asrSchoolRaw: Int = SLAsrSchool.standard.rawValue
    var highLatRuleRaw: Int = SLHighLatRule.middleOfNight.rawValue
    var cityID: Int = 0
    var offsets: [Int] = [0, 0, 0, 0, 0]
    var clockStyleRaw: Int = SLClockStyle.twelveHour.rawValue
    var weekStartRaw: Int = SLWeekStart.monday.rawValue
    var showHijri: Bool = true
    var trackNawafil: Bool = true

    init() {}

    enum CodingKeys: String, CodingKey {
        case methodID, asrSchoolRaw, highLatRuleRaw, cityID, offsets
        case clockStyleRaw, weekStartRaw, showHijri, trackNawafil
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        func int(_ k: CodingKeys, _ fallback: Int) -> Int {
            let stored = try? box.decodeIfPresent(Int.self, forKey: k)
            return stored ?? fallback
        }
        func flag(_ k: CodingKeys, _ fallback: Bool) -> Bool {
            let stored = try? box.decodeIfPresent(Bool.self, forKey: k)
            return stored ?? fallback
        }
        methodID = int(.methodID, 0)
        asrSchoolRaw = int(.asrSchoolRaw, SLAsrSchool.standard.rawValue)
        highLatRuleRaw = int(.highLatRuleRaw, SLHighLatRule.middleOfNight.rawValue)
        cityID = int(.cityID, 0)
        let storedOffsets = try? box.decodeIfPresent([Int].self, forKey: .offsets)
        offsets = SLEngineConfig.clampOffsets(storedOffsets ?? [])
        clockStyleRaw = int(.clockStyleRaw, SLClockStyle.twelveHour.rawValue)
        weekStartRaw = int(.weekStartRaw, SLWeekStart.monday.rawValue)
        showHijri = flag(.showHijri, true)
        trackNawafil = flag(.trackNawafil, true)
    }

    var asrSchool: SLAsrSchool {
        get { SLAsrSchool(rawValue: asrSchoolRaw) ?? .standard }
        set { asrSchoolRaw = newValue.rawValue }
    }
    var highLatRule: SLHighLatRule {
        get { SLHighLatRule(rawValue: highLatRuleRaw) ?? .middleOfNight }
        set { highLatRuleRaw = newValue.rawValue }
    }
    var clockStyle: SLClockStyle {
        get { SLClockStyle(rawValue: clockStyleRaw) ?? .twelveHour }
        set { clockStyleRaw = newValue.rawValue }
    }
    var weekStart: SLWeekStart {
        get { SLWeekStart(rawValue: weekStartRaw) ?? .monday }
        set { weekStartRaw = newValue.rawValue }
    }

    var city: SLCity { SLCityTable.city(id: cityID) }
    var place: SLPlace { city.place }
    var method: SLMethod { SLMethodCatalogue.method(id: methodID) }

    var engineConfig: SLEngineConfig {
        SLEngineConfig(methodID: methodID,
                       asrSchool: asrSchool,
                       highLatRule: highLatRule,
                       offsets: SLEngineConfig.clampOffsets(offsets))
    }
}

// MARK: - The store

@MainActor
final class SLStore: ObservableObject {

    @Published private(set) var settings: SLSettings
    @Published private(set) var records: [String: SLDayRecord]
    /// Make-ups already performed, indexed by `SLPrayer.rawValue`. Never negative.
    @Published private(set) var qadaPaid: [Int]
    /// Bumped whenever anything that feeds a statistic changes, so derived views recompute.
    @Published private(set) var revision: Int = 0

    private let settingsKey = "salahstreak.settings.v1"
    private let recordsKey  = "salahstreak.records.v1"
    private let qadaKey     = "salahstreak.qada.v1"

    private let defaults = UserDefaults.standard
    private var statsCache: SLStatistics?
    private var statsCacheRevision: Int = -1
    private var statsCacheStamp: Date = .distantPast
    /// Long enough that a view body redrawing many times a second costs nothing, short
    /// enough that the streak notices the day turning over shortly after Fajr.
    private let statsMaxAge: TimeInterval = 30

    init() {
        let decoder = JSONDecoder()

        if let data = defaults.data(forKey: settingsKey),
           let stored = try? decoder.decode(SLSettings.self, from: data) {
            settings = stored
        } else {
            settings = SLSettings()
        }

        if let data = defaults.data(forKey: recordsKey),
           let stored = try? decoder.decode([String: SLDayRecord].self, from: data) {
            records = stored
        } else {
            records = [:]
        }

        if let stored = defaults.array(forKey: qadaKey) as? [Int] {
            var padded = [Int](repeating: 0, count: SLPrayer.allCases.count)
            for i in 0..<padded.count where i < stored.count { padded[i] = max(0, stored[i]) }
            qadaPaid = padded
        } else {
            qadaPaid = [Int](repeating: 0, count: SLPrayer.allCases.count)
        }
    }

    // MARK: Derived configuration

    var place: SLPlace { settings.place }
    var city: SLCity { settings.city }
    var timeZoneID: String { settings.city.timeZoneID }
    var engineConfig: SLEngineConfig { settings.engineConfig }
    var clockStyle: SLClockStyle { settings.clockStyle }

    func schedule(for day: Date) -> SLSchedule {
        SLPrayerEngine.schedule(for: day, place: place, config: engineConfig)
    }

    func recordDay(for now: Date) -> Date {
        SLPrayerEngine.recordDay(for: now, place: place, config: engineConfig)
    }

    func key(for day: Date) -> String {
        SLTimeFormat.dayKey(day, timeZoneID: timeZoneID)
    }

    // MARK: Reading records

    func record(for day: Date) -> SLDayRecord {
        records[key(for: day)] ?? SLDayRecord(key: key(for: day))
    }

    func record(forKey key: String) -> SLDayRecord {
        records[key] ?? SLDayRecord(key: key)
    }

    var hasAnyHistory: Bool { records.values.contains { !$0.isEmpty } }

    // MARK: Writing records

    /// Tapping the mark a prayer already carries clears it, which is the only way back to
    /// "not recorded" without a second control.
    func mark(_ state: SLPrayerState, prayer: SLPrayer, on day: Date) {
        let dayKey = key(for: day)
        var entry = records[dayKey] ?? SLDayRecord(key: dayKey)
        entry.key = dayKey
        entry.set(entry.state(prayer) == state ? .none : state, for: prayer)
        commit(entry, key: dayKey)
    }

    func toggleNafl(_ item: SLNafl, on day: Date) {
        let dayKey = key(for: day)
        var entry = records[dayKey] ?? SLDayRecord(key: dayKey)
        entry.key = dayKey
        entry.setNafl(item, !entry.nafl(item))
        commit(entry, key: dayKey)
    }

    func clearDay(_ day: Date) {
        let dayKey = key(for: day)
        records.removeValue(forKey: dayKey)
        bump()
        persistRecords()
    }

    private func commit(_ entry: SLDayRecord, key dayKey: String) {
        if entry.isEmpty {
            records.removeValue(forKey: dayKey)
        } else {
            records[dayKey] = entry
        }
        bump()
        persistRecords()
    }

    // MARK: Qada ledger

    /// Outstanding make-ups for one prayer: everything marked missed, less what has been
    /// made up. Clamped at zero so deleting a missed mark after paying it cannot go
    /// negative.
    func qadaOutstanding(_ prayer: SLPrayer) -> Int {
        max(0, qadaMissedTotal(prayer) - qadaPaidCount(prayer))
    }

    func qadaMissedTotal(_ prayer: SLPrayer) -> Int {
        statistics().missedByPrayer[prayer.rawValue]
    }

    func qadaPaidCount(_ prayer: SLPrayer) -> Int {
        let i = prayer.rawValue
        guard i >= 0, i < qadaPaid.count else { return 0 }
        return qadaPaid[i]
    }

    var qadaTotalOutstanding: Int {
        SLPrayer.allCases.reduce(0) { $0 + qadaOutstanding($1) }
    }

    var qadaTotalPaid: Int { qadaPaid.reduce(0, +) }

    func payQada(_ prayer: SLPrayer) {
        guard qadaOutstanding(prayer) > 0 else { return }
        let i = prayer.rawValue
        guard i >= 0, i < qadaPaid.count else { return }
        qadaPaid[i] += 1
        defaults.set(qadaPaid, forKey: qadaKey)
        bump()
    }

    func undoQada(_ prayer: SLPrayer) {
        let i = prayer.rawValue
        guard i >= 0, i < qadaPaid.count, qadaPaid[i] > 0 else { return }
        qadaPaid[i] -= 1
        defaults.set(qadaPaid, forKey: qadaKey)
        bump()
    }

    // MARK: Settings

    /// One funnel for every settings change. Nothing here reads a `@Published` property
    /// back inside its own `willSet` — that observer sees the value it is replacing, and
    /// a settings screen wired that way applies each change one tap late.
    func updateSettings(_ transform: (inout SLSettings) -> Void) {
        var draft = settings
        transform(&draft)
        draft.offsets = SLEngineConfig.clampOffsets(draft.offsets)
        if draft.methodID < 0 || draft.methodID >= SLMethodCatalogue.count { draft.methodID = 0 }
        if draft.cityID < 0 || draft.cityID >= SLCityTable.count { draft.cityID = 0 }
        guard draft != settings else { return }
        settings = draft
        bump()
        persistSettings()
    }

    func setOffset(_ minutes: Int, for prayer: SLPrayer) {
        updateSettings { draft in
            var next = draft.offsets
            while next.count < SLPrayer.allCases.count { next.append(0) }
            next[prayer.rawValue] = max(-30, min(30, minutes))
            draft.offsets = next
        }
    }

    func offset(for prayer: SLPrayer) -> Int {
        let i = prayer.rawValue
        guard i >= 0, i < settings.offsets.count else { return 0 }
        return settings.offsets[i]
    }

    // MARK: Reset

    func resetEverything() {
        records = [:]
        qadaPaid = [Int](repeating: 0, count: SLPrayer.allCases.count)
        settings = SLSettings()
        defaults.removeObject(forKey: recordsKey)
        defaults.removeObject(forKey: qadaKey)
        defaults.removeObject(forKey: settingsKey)
        bump()
    }

    // MARK: Persistence

    /// Records and settings are written the moment they change — the app has no other
    /// save point, and a tracker that loses today's marks when the process is killed from
    /// the switcher is worthless. `scenePhase` is used only for the panel's cookie
    /// mirror, and only on the way OUT of the foreground.
    private func persistRecords() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: recordsKey)
    }

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    func flush() {
        persistRecords()
        persistSettings()
        defaults.set(qadaPaid, forKey: qadaKey)
    }

    private func bump() {
        revision &+= 1
        statsCache = nil
    }

    // MARK: Statistics

    /// Recomputed only when something actually changed. Every screen that shows a number
    /// goes through here, so the whole app agrees on one set of totals.
    func statistics() -> SLStatistics {
        let now = Date()
        if let cached = statsCache,
           statsCacheRevision == revision,
           now.timeIntervalSince(statsCacheStamp) < statsMaxAge {
            return cached
        }
        let computed = SLStatistics(records: records,
                                    timeZoneID: timeZoneID,
                                    place: place,
                                    config: engineConfig,
                                    weekStart: settings.weekStart)
        statsCache = computed
        statsCacheRevision = revision
        statsCacheStamp = now
        return computed
    }
}
