import Foundation

/// One logged day, resolved to a real date so the streak walks can step by calendar day.
struct SLDayEntry: Identifiable {
    let key: String
    let date: Date
    let record: SLDayRecord
    var id: String { key }
}

/// Every number the app displays is computed here, once, from the record set. Nothing
/// downstream recounts anything on its own, so the streak on the Today screen and the
/// streak in the statistics can never disagree.
struct SLStatistics {

    let timeZoneID: String
    let referenceDay: Date
    let entries: [SLDayEntry]

    let totalDaysLogged: Int
    let completeDays: Int
    /// Days on which all five were recorded as prayed in congregation.
    let fullCongregationDays: Int
    /// Fridays on which the midday prayer — Jumu'ah — was recorded in congregation.
    let jumuahCongregationDays: Int

    let markedTotal: Int
    let performedTotal: Int
    let punctualTotal: Int
    let congregationTotal: Int
    let missedTotal: Int

    let markedByPrayer: [Int]
    let performedByPrayer: [Int]
    let punctualByPrayer: [Int]
    let congregationByPrayer: [Int]
    let missedByPrayer: [Int]

    let currentStreak: Int
    let longestStreak: Int
    let prayerCurrentStreak: [Int]
    let prayerLongestStreak: [Int]
    let fajrCongregationStreak: Int
    let fajrCongregationBest: Int

    /// Punctual rate by weekday, indexed 0 = Sunday … 6 = Saturday. `nil` where nothing
    /// has been logged on that weekday yet.
    let weekdayRates: [Double?]
    let weekdayLogged: [Int]

    let naflTotals: [Int]

    /// The calculated Fajr clock time on the earliest and latest mornings the user has
    /// actually logged a Fajr. These are computed times, not observed ones — the app
    /// never records the minute a prayer was performed.
    let earliestFajr: (day: Date, minutes: Double)?
    let latestFajr: (day: Date, minutes: Double)?

    private let calendar: Calendar
    private let byKey: [String: SLDayRecord]

    init(records: [String: SLDayRecord],
         timeZoneID: String,
         place: SLPlace,
         config: SLEngineConfig,
         weekStart: SLWeekStart) {

        self.timeZoneID = timeZoneID
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = SLZone.resolve(timeZoneID)
        self.calendar = cal
        self.byKey = records

        let today = SLPrayerEngine.recordDay(for: Date(), place: place, config: config)
        // Held as a local as well: the nested walks below run while `self` is still being
        // initialised, and a struct's initialiser may not read its own stored properties
        // from a local function.
        let refDay = cal.startOfDay(for: today)
        self.referenceDay = refDay

        // Resolve every stored key back to a date. A key that cannot be parsed — which
        // should not happen, but a corrupted defaults plist is not impossible — is
        // dropped rather than allowed to poison the ordering.
        var resolved: [SLDayEntry] = []
        resolved.reserveCapacity(records.count)
        for (key, record) in records {
            guard !record.isEmpty, let date = SLStatistics.parse(key: key, calendar: cal) else { continue }
            resolved.append(SLDayEntry(key: key, date: date, record: record))
        }
        resolved.sort { $0.date < $1.date }
        self.entries = resolved

        let prayerCount = SLPrayer.allCases.count
        var marked = [Int](repeating: 0, count: prayerCount)
        var performed = [Int](repeating: 0, count: prayerCount)
        var punctual = [Int](repeating: 0, count: prayerCount)
        var congregation = [Int](repeating: 0, count: prayerCount)
        var missed = [Int](repeating: 0, count: prayerCount)
        var nafl = [Int](repeating: 0, count: SLNafl.allCases.count)

        var weekdayPunctual = [Int](repeating: 0, count: 7)
        var weekdayMarked = [Int](repeating: 0, count: 7)
        var weekdayDays = [Int](repeating: 0, count: 7)

        var complete = 0
        var fullCongregation = 0
        var jumuah = 0

        for entry in resolved {
            if entry.record.isComplete { complete += 1 }
            if entry.record.congregationCount == prayerCount { fullCongregation += 1 }
            let weekdayIndex = max(0, min(6, (cal.component(.weekday, from: entry.date)) - 1))
            // 6 is Friday in `Calendar`'s Sunday-first numbering.
            if weekdayIndex == 5 && entry.record.state(.dhuhr) == .congregation { jumuah += 1 }
            weekdayDays[weekdayIndex] += 1

            for prayer in SLPrayer.allCases {
                let state = entry.record.state(prayer)
                let i = prayer.rawValue
                guard state != .none else { continue }
                marked[i] += 1
                weekdayMarked[weekdayIndex] += 1
                if state.isPerformed { performed[i] += 1 }
                if state.isPunctual {
                    punctual[i] += 1
                    weekdayPunctual[weekdayIndex] += 1
                }
                if state == .congregation { congregation[i] += 1 }
                if state == .missed { missed[i] += 1 }
            }
            for item in SLNafl.allCases where entry.record.nafl(item) {
                nafl[item.rawValue] += 1
            }
        }

        self.markedByPrayer = marked
        self.performedByPrayer = performed
        self.punctualByPrayer = punctual
        self.congregationByPrayer = congregation
        self.missedByPrayer = missed
        self.naflTotals = nafl

        self.markedTotal = marked.reduce(0, +)
        self.performedTotal = performed.reduce(0, +)
        self.punctualTotal = punctual.reduce(0, +)
        self.congregationTotal = congregation.reduce(0, +)
        self.missedTotal = missed.reduce(0, +)
        self.totalDaysLogged = resolved.count
        self.completeDays = complete
        self.fullCongregationDays = fullCongregation
        self.jumuahCongregationDays = jumuah

        self.weekdayLogged = weekdayDays
        self.weekdayRates = (0..<7).map { index in
            weekdayMarked[index] > 0 ? Double(weekdayPunctual[index]) / Double(weekdayMarked[index]) : nil
        }

        // MARK: Streaks
        //
        // The run is measured backwards from the reference day. Today is allowed to be
        // incomplete without breaking anything: the day is not over, so the walk simply
        // starts at yesterday instead. Only a day that has ENDED can break a streak.

        let lookup = records
        func recordFor(_ date: Date) -> SLDayRecord? {
            lookup[SLTimeFormat.dayKey(date, timeZoneID: timeZoneID)]
        }

        func walkBack(from start: Date, while predicate: (SLDayRecord) -> Bool) -> Int {
            var count = 0
            var cursor = start
            // A hard bound: nobody has a fifty-year streak in a tracker installed last week,
            // and it guarantees the loop terminates whatever the calendar does.
            for _ in 0..<20000 {
                guard let record = recordFor(cursor), predicate(record) else { break }
                count += 1
                guard let previous = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = previous
            }
            return count
        }

        func currentRun(_ predicate: (SLDayRecord) -> Bool) -> Int {
            if let todayRecord = recordFor(refDay), predicate(todayRecord) {
                return walkBack(from: refDay, while: predicate)
            }
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: refDay) else { return 0 }
            return walkBack(from: yesterday, while: predicate)
        }

        /// Longest run anywhere in the history. Works off the sorted entry list and only
        /// counts a day as continuing a run when it is exactly one calendar day later.
        func longestRun(_ predicate: (SLDayRecord) -> Bool) -> Int {
            var best = 0
            var run = 0
            var previousDate: Date? = nil
            for entry in resolved {
                guard predicate(entry.record) else {
                    run = 0
                    previousDate = entry.date
                    continue
                }
                if let previous = previousDate,
                   let expected = cal.date(byAdding: .day, value: 1, to: previous),
                   cal.isDate(expected, inSameDayAs: entry.date) {
                    run += 1
                } else {
                    run = 1
                }
                best = max(best, run)
                previousDate = entry.date
            }
            return best
        }

        self.currentStreak = currentRun { $0.isComplete }
        self.longestStreak = longestRun { $0.isComplete }

        var prayerCurrent = [Int](repeating: 0, count: prayerCount)
        var prayerLongest = [Int](repeating: 0, count: prayerCount)
        for prayer in SLPrayer.allCases {
            prayerCurrent[prayer.rawValue] = currentRun { $0.state(prayer).isPerformed }
            prayerLongest[prayer.rawValue] = longestRun { $0.state(prayer).isPerformed }
        }
        self.prayerCurrentStreak = prayerCurrent
        self.prayerLongestStreak = prayerLongest

        self.fajrCongregationStreak = currentRun { $0.state(.fajr) == .congregation }
        self.fajrCongregationBest = longestRun { $0.state(.fajr) == .congregation }

        // MARK: Earliest and latest Fajr
        //
        // Bounded to the last two years of logged days so a long history cannot turn a
        // statistics screen into a stall. Each day costs one engine pass.
        var earliest: (day: Date, minutes: Double)? = nil
        var latest: (day: Date, minutes: Double)? = nil
        let horizon = cal.date(byAdding: .day, value: -730, to: refDay) ?? refDay
        for entry in resolved where entry.date >= horizon {
            guard entry.record.state(.fajr).isPerformed else { continue }
            let times = SLPrayerEngine.times(on: entry.date, place: place, config: config)
            guard let minutes = times.minutes(for: .fajr), minutes.isFinite else { continue }
            if earliest == nil || minutes < earliest!.minutes { earliest = (entry.date, minutes) }
            if latest == nil || minutes > latest!.minutes { latest = (entry.date, minutes) }
        }
        self.earliestFajr = earliest
        self.latestFajr = latest
    }

    // MARK: - Key parsing

    static func parse(key: String, calendar: Calendar) -> Date? {
        let bits = key.split(separator: "-")
        guard bits.count == 3,
              let year = Int(bits[0]), let month = Int(bits[1]), let day = Int(bits[2]),
              month >= 1, month <= 12, day >= 1, day <= 31 else { return nil }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12          // midday, so no DST gap can swallow the date
        guard let noon = calendar.date(from: comps) else { return nil }
        return calendar.startOfDay(for: noon)
    }

    // MARK: - Rates

    private func ratio(_ numerator: Int, _ denominator: Int) -> Double? {
        denominator > 0 ? Double(numerator) / Double(denominator) : nil
    }

    var punctualRate: Double? { ratio(punctualTotal, markedTotal) }
    var congregationRate: Double? { ratio(congregationTotal, markedTotal) }
    var performedRate: Double? { ratio(performedTotal, markedTotal) }

    func punctualRate(_ prayer: SLPrayer) -> Double? {
        ratio(punctualByPrayer[prayer.rawValue], markedByPrayer[prayer.rawValue])
    }

    func congregationRate(_ prayer: SLPrayer) -> Double? {
        ratio(congregationByPrayer[prayer.rawValue], markedByPrayer[prayer.rawValue])
    }

    func performedRate(_ prayer: SLPrayer) -> Double? {
        ratio(performedByPrayer[prayer.rawValue], markedByPrayer[prayer.rawValue])
    }

    /// Strongest and weakest are only offered once there is enough logged for the answer
    /// to mean anything; below that the screen says so instead of naming a winner.
    var hasEnoughForRanking: Bool { markedTotal >= 25 }

    var strongestPrayer: SLPrayer? {
        guard hasEnoughForRanking else { return nil }
        return SLPrayer.allCases
            .filter { markedByPrayer[$0.rawValue] >= 3 }
            .max { (punctualRate($0) ?? 0) < (punctualRate($1) ?? 0) }
    }

    var weakestPrayer: SLPrayer? {
        guard hasEnoughForRanking else { return nil }
        return SLPrayer.allCases
            .filter { markedByPrayer[$0.rawValue] >= 3 }
            .min { (punctualRate($0) ?? 1) < (punctualRate($1) ?? 1) }
    }

    /// Weekday with the highest punctual rate, as a `Calendar` weekday number (1 = Sunday).
    var bestWeekday: Int? {
        guard hasEnoughForRanking else { return nil }
        var bestIndex: Int? = nil
        var bestValue = -1.0
        for index in 0..<7 {
            guard weekdayLogged[index] >= 2, let rate = weekdayRates[index] else { continue }
            if rate > bestValue { bestValue = rate; bestIndex = index }
        }
        return bestIndex.map { $0 + 1 }
    }

    // MARK: - Series for the charts

    /// Ring fraction for each of the last `days` days, oldest first. Days with nothing
    /// logged contribute zero, which is the honest reading: nothing was recorded.
    func dailySeries(days: Int) -> [(date: Date, value: Double)] {
        let span = max(1, min(days, 400))
        var out: [(Date, Double)] = []
        out.reserveCapacity(span)
        for step in stride(from: span - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -step, to: referenceDay) else { continue }
            let record = byKey[SLTimeFormat.dayKey(date, timeZoneID: timeZoneID)]
            out.append((date, record?.ringFraction ?? 0))
        }
        return out.map { (date: $0.0, value: $0.1) }
    }

    /// A moving average over `window` days, so a 365 day line reads as a trend and not as
    /// noise. The first entries average over however many days exist so far.
    func smoothed(_ series: [(date: Date, value: Double)], window: Int) -> [Double] {
        guard !series.isEmpty else { return [] }
        let w = max(1, min(window, series.count))
        var out: [Double] = []
        out.reserveCapacity(series.count)
        var runningSum = 0.0
        for index in 0..<series.count {
            runningSum += series[index].value
            if index >= w { runningSum -= series[index - w].value }
            let divisor = Double(min(index + 1, w))
            out.append(divisor > 0 ? runningSum / divisor : 0)
        }
        return out
    }

    /// Completion by week, most recent week last. `label` is the week's first date.
    func weeklySeries(weeks: Int, weekStart: SLWeekStart) -> [(start: Date, value: Double, logged: Int)] {
        let count = max(1, min(weeks, 26))
        guard let thisWeekStart = startOfWeek(containing: referenceDay, weekStart: weekStart) else { return [] }
        var out: [(Date, Double, Int)] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .day, value: -7 * offset, to: thisWeekStart) else { continue }
            var sum = 0.0
            var logged = 0
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
                if date > referenceDay { continue }
                if let record = byKey[SLTimeFormat.dayKey(date, timeZoneID: timeZoneID)] {
                    sum += record.ringFraction
                    logged += 1
                }
            }
            out.append((start, sum / 7.0, logged))
        }
        return out.map { (start: $0.0, value: $0.1, logged: $0.2) }
    }

    func startOfWeek(containing date: Date, weekStart: SLWeekStart) -> Date? {
        let weekday = calendar.component(.weekday, from: date)
        let delta = (weekday - weekStart.calendarWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -delta, to: calendar.startOfDay(for: date))
    }

    /// The rows of a month grid, padded so the first column is the chosen first weekday.
    /// A `nil` entry is a blank cell, never a zero-valued one.
    func monthGrid(monthContaining date: Date, weekStart: SLWeekStart) -> [[Date?]] {
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let first = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: first) else { return [] }
        let leading = (calendar.component(.weekday, from: first) - weekStart.calendarWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            guard let dayDate = calendar.date(byAdding: .day, value: day - 1, to: first) else { continue }
            cells.append(dayDate)
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }
    }

    func record(on date: Date) -> SLDayRecord? {
        byKey[SLTimeFormat.dayKey(date, timeZoneID: timeZoneID)]
    }

    func isFuture(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) > referenceDay
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: referenceDay)
    }

    // MARK: - Text helpers

    static func percentText(_ value: Double?) -> String {
        guard let value = value, value.isFinite else { return "—" }
        return "\(Int((value * 100).rounded()))%"
    }
}
