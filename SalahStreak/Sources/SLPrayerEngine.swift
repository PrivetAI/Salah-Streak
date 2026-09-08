import Foundation

// MARK: - Degree trigonometry
//
// The whole engine works in degrees, because every published prayer-time parameter is
// stated in degrees. Wrapping the conversion here keeps the formulas below readable and
// keeps the radian/degree mistakes in one place where they can be checked.

enum SLTrig {
    static let deg = Double.pi / 180.0

    @inline(__always) static func sn(_ d: Double) -> Double { sin(d * deg) }
    @inline(__always) static func cs(_ d: Double) -> Double { cos(d * deg) }
    @inline(__always) static func tn(_ d: Double) -> Double { tan(d * deg) }
    @inline(__always) static func asn(_ x: Double) -> Double { asin(clamp(x)) / deg }
    @inline(__always) static func acs(_ x: Double) -> Double { acos(clamp(x)) / deg }
    @inline(__always) static func atn(_ x: Double) -> Double { atan(x) / deg }

    @inline(__always) static func clamp(_ x: Double) -> Double {
        guard x.isFinite else { return 0 }
        return Swift.max(-1.0, Swift.min(1.0, x))
    }

    /// Wrap a value into [0, limit).
    static func wrap(_ value: Double, _ limit: Double) -> Double {
        guard value.isFinite, limit > 0 else { return 0 }
        var v = value.truncatingRemainder(dividingBy: limit)
        if v < 0 { v += limit }
        return v
    }
}

// MARK: - Solar position
//
// The apparent position of the sun, following the NOAA solar-position formulation
// (Meeus, *Astronomical Algorithms*, low-precision series). Declination is good to about
// a hundredth of a degree over the years this app will be used, which is far finer than
// the minute-level resolution any prayer timetable is printed at.

struct SLSunPosition {
    /// Declination of the sun, in degrees.
    let declination: Double
    /// Equation of time — apparent solar time minus mean solar time — in minutes.
    let equationOfTime: Double
}

enum SLSolar {

    /// Julian day number for a civil date at 00:00 universal time.
    static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = year
        var m = month
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(Double(y) / 100.0)
        let b = 2.0 - a + floor(a / 4.0)
        return floor(365.25 * (Double(y) + 4716.0))
             + floor(30.6001 * (Double(m) + 1.0))
             + Double(day) + b - 1524.5
    }

    /// `jd` is a Julian day, possibly fractional. Fractional days matter: the declination
    /// moves by up to 0.4 degrees across a single day near the equinoxes, which is worth
    /// several minutes at the Fajr and Isha angles.
    static func position(julian jd: Double) -> SLSunPosition {
        let t = (jd - 2451545.0) / 36525.0                                  // Julian centuries

        // Geometric mean longitude and mean anomaly of the sun.
        let meanLongitude = SLTrig.wrap(280.46646 + t * (36000.76983 + t * 0.0003032), 360)
        let meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        // Equation of the centre, then the true and apparent longitudes.
        let centre = SLTrig.sn(meanAnomaly) * (1.914602 - t * (0.004817 + 0.000014 * t))
                   + SLTrig.sn(2 * meanAnomaly) * (0.019993 - 0.000101 * t)
                   + SLTrig.sn(3 * meanAnomaly) * 0.000289
        let trueLongitude = meanLongitude + centre
        let omega = 125.04 - 1934.136 * t                                   // lunar node
        let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * SLTrig.sn(omega)

        // Obliquity of the ecliptic, with the nutation correction.
        let meanObliquity = 23.0 + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
        let obliquity = meanObliquity + 0.00256 * SLTrig.cs(omega)

        let declination = SLTrig.asn(SLTrig.sn(obliquity) * SLTrig.sn(apparentLongitude))

        // Equation of time, in minutes.
        let y = pow(SLTrig.tn(obliquity / 2.0), 2)
        let radians = y * SLTrig.sn(2 * meanLongitude)
                    - 2.0 * eccentricity * SLTrig.sn(meanAnomaly)
                    + 4.0 * eccentricity * y * SLTrig.sn(meanAnomaly) * SLTrig.cs(2 * meanLongitude)
                    - 0.5 * y * y * SLTrig.sn(4 * meanLongitude)
                    - 1.25 * eccentricity * eccentricity * SLTrig.sn(2 * meanAnomaly)
        let equationOfTime = 4.0 * (radians / SLTrig.deg)

        return SLSunPosition(declination: declination, equationOfTime: equationOfTime)
    }

    /// Half the length of the day, in degrees of hour angle, for a given solar altitude.
    /// `nil` when the sun never reaches that altitude on that date at that latitude —
    /// which is exactly the polar case the interface must report honestly.
    static func hourAngle(altitude: Double, latitude: Double, declination: Double) -> Double? {
        let denominator = SLTrig.cs(latitude) * SLTrig.cs(declination)
        guard abs(denominator) > 1e-9 else { return nil }
        let ratio = (SLTrig.sn(altitude) - SLTrig.sn(latitude) * SLTrig.sn(declination)) / denominator
        guard ratio >= -1.0, ratio <= 1.0 else { return nil }
        return SLTrig.acs(ratio)
    }

    /// The altitude of the sun at the moment an upright object's shadow has grown by
    /// `factor` further object lengths beyond the shadow it casts at local noon.
    static func asrAltitude(factor: Double, latitude: Double, declination: Double) -> Double? {
        let zenithAtNoon = abs(latitude - declination)
        guard zenithAtNoon < 89.9 else { return nil }
        let cotangent = factor + SLTrig.tn(zenithAtNoon)
        guard cotangent > 0 else { return nil }
        return SLTrig.atn(1.0 / cotangent)
    }

    /// Apparent sunrise and sunset are taken with the sun's upper limb on the horizon:
    /// half a solar diameter plus mean atmospheric refraction.
    static let horizonAltitude: Double = -0.833
}

// MARK: - Time zones
//
// Resolving an IANA identifier is not free, and the engine asks for one on every
// computed day, so the answers are memoised. A city whose identifier is missing from the
// device's tz database falls back to the device zone rather than to GMT: being an hour
// out is recoverable, being on the wrong continent is not.

enum SLZone {
    private static var cache: [String: TimeZone] = [:]
    private static let lock = NSLock()

    static func resolve(_ identifier: String) -> TimeZone {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[identifier] { return cached }
        let zone = TimeZone(identifier: identifier) ?? TimeZone.current
        cache[identifier] = zone
        return zone
    }
}

// MARK: - A place

struct SLPlace: Equatable {
    var latitude: Double
    var longitude: Double
    var timeZoneID: String

    var timeZone: TimeZone { SLZone.resolve(timeZoneID) }

    func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }

    /// Offset from UTC in minutes, taken at the given instant so a DST change is respected.
    func utcOffsetMinutes(at date: Date) -> Double {
        Double(timeZone.secondsFromGMT(for: date)) / 60.0
    }
}

// MARK: - Engine configuration

struct SLEngineConfig: Equatable {
    var methodID: Int = 0
    var asrSchool: SLAsrSchool = .standard
    var highLatRule: SLHighLatRule = .middleOfNight
    /// Manual corrections in minutes, indexed by `SLPrayer.rawValue`. Clamped to ±30.
    var offsets: [Int] = [0, 0, 0, 0, 0]

    var method: SLMethod { SLMethodCatalogue.method(id: methodID) }

    func offset(_ prayer: SLPrayer) -> Double {
        let i = prayer.rawValue
        guard i >= 0, i < offsets.count else { return 0 }
        return Double(max(-30, min(30, offsets[i])))
    }

    static func clampOffsets(_ raw: [Int]) -> [Int] {
        var out = [Int](repeating: 0, count: SLPrayer.allCases.count)
        for i in 0..<out.count where i < raw.count { out[i] = max(-30, min(30, raw[i])) }
        return out
    }
}

// MARK: - One computed day

struct SLDayTimes {
    /// Local midnight of the civil day these times belong to, in the place's own zone.
    let dayStart: Date
    let timeZoneID: String
    /// Minutes from local midnight, indexed by `SLPrayer.rawValue`. `nil` means the event
    /// has no solution today and must be shown as a dash, never as an invented time.
    let minutes: [Double?]
    let sunriseMinutes: Double?
    let solarNoonMinutes: Double
    /// True where a high-latitude rule supplied the value instead of the sun itself.
    let adjusted: [Bool]
    /// The sun does not set at all today.
    let polarDay: Bool
    /// The sun does not rise at all today.
    let polarNight: Bool
    let declination: Double
    let equationOfTime: Double

    func minutes(for prayer: SLPrayer) -> Double? {
        let i = prayer.rawValue
        guard i >= 0, i < minutes.count else { return nil }
        return minutes[i]
    }

    func wasAdjusted(_ prayer: SLPrayer) -> Bool {
        let i = prayer.rawValue
        guard i >= 0, i < adjusted.count else { return false }
        return adjusted[i]
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = SLZone.resolve(timeZoneID)
        return cal
    }

    /// Builds an absolute instant from "minutes past local midnight".
    ///
    /// The arithmetic goes through `DateComponents`, never through
    /// `dayStart + minutes * 60`. On the two days a year a zone changes its offset those
    /// two are not the same answer: adding seconds keeps the elapsed time and shifts the
    /// wall clock by an hour, which is how a timetable ends up claiming Fajr at 06:12 on
    /// the morning the clocks went forward. Resolving components in the zone gives the
    /// wall-clock time the mosque down the road is actually using, and a component that
    /// overflows the day (Isha after midnight, or a negative Fajr at high latitude) is
    /// normalised into the neighbouring day by `Calendar` itself.
    func date(fromMinutes m: Double) -> Date? {
        guard m.isFinite else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: dayStart)
        comps.hour = 0
        comps.minute = Int(m.rounded())
        comps.second = 0
        return calendar.date(from: comps)
    }

    func date(for prayer: SLPrayer) -> Date? {
        guard let m = minutes(for: prayer) else { return nil }
        return date(fromMinutes: m)
    }

    var sunriseDate: Date? {
        guard let m = sunriseMinutes else { return nil }
        return date(fromMinutes: m)
    }

    /// Every prayer that has a time today, in order, as absolute instants.
    var resolved: [(prayer: SLPrayer, date: Date)] {
        SLPrayer.allCases.compactMap { p in
            guard let d = date(for: p) else { return nil }
            return (prayer: p, date: d)
        }
    }
}

// MARK: - The engine

enum SLPrayerEngine {

    /// Computes the five prayer times, plus sunrise, for one civil day at one place.
    static func times(on date: Date, place: SLPlace, config: SLEngineConfig) -> SLDayTimes {
        let cal = place.calendar()
        let dayStart = cal.startOfDay(for: date)
        let parts = cal.dateComponents([.year, .month, .day], from: dayStart)
        let year = parts.year ?? 2000
        let month = parts.month ?? 1
        let day = parts.day ?? 1

        // The zone offset is read at local noon, which is never inside a transition gap.
        let noonInstant = dayStart.addingTimeInterval(12 * 3600)
        let offsetMinutes = place.utcOffsetMinutes(at: noonInstant)

        let latitude = max(-89.5, min(89.5, place.latitude))
        let longitude = place.longitude
        let jdMidnightUTC = SLSolar.julianDay(year: year, month: month, day: day)

        // `event` converts a candidate local clock time into the Julian day at which the
        // sun's position should be evaluated, so each event is solved at its own instant
        // rather than all of them at local noon.
        func position(atLocalMinutes m: Double) -> SLSunPosition {
            let utcFractionOfDay = (m - offsetMinutes) / 1440.0
            return SLSolar.position(julian: jdMidnightUTC + utcFractionOfDay)
        }

        // Solar noon: 720 minutes of mean time, corrected for the longitude offset from
        // the zone meridian and for the equation of time. Two passes converge to well
        // under a second.
        var noonMinutes = 720.0 - 4.0 * longitude - position(atLocalMinutes: 720).equationOfTime + offsetMinutes
        for _ in 0..<2 {
            let p = position(atLocalMinutes: noonMinutes)
            noonMinutes = 720.0 - 4.0 * longitude - p.equationOfTime + offsetMinutes
        }
        let noonPosition = position(atLocalMinutes: noonMinutes)

        /// Solves for the moment the sun sits at `altitude`, on the morning or evening
        /// side of noon. Two refinement passes; `nil` when there is no solution.
        func solve(altitude: Double, morning: Bool, seed: Double) -> Double? {
            var guess = seed
            var answer: Double? = nil
            for _ in 0..<3 {
                let p = position(atLocalMinutes: guess)
                guard let ha = SLSolar.hourAngle(altitude: altitude,
                                                 latitude: latitude,
                                                 declination: p.declination) else { return nil }
                let candidate = morning ? noonMinutes - 4.0 * ha : noonMinutes + 4.0 * ha
                guess = candidate
                answer = candidate
            }
            return answer
        }

        let method = config.method
        // The only two constants added anywhere in this engine: Dhuhr is taken one minute
        // after true transit and Maghrib one minute after apparent sunset, which is the
        // ordinary safety margin printed timetables use.
        let noonMargin = 1.0
        let maghribMargin = 1.0

        let sunriseRaw = solve(altitude: SLSolar.horizonAltitude, morning: true, seed: noonMinutes - 360)
        let sunsetRaw = solve(altitude: SLSolar.horizonAltitude, morning: false, seed: noonMinutes + 360)

        // Polar classification. When there is no sunrise and no sunset, the sign of
        // (latitude x declination) says which side of the year we are on.
        let noSunEvents = (sunriseRaw == nil && sunsetRaw == nil)
        let polarDay = noSunEvents && (latitude * noonPosition.declination > 0)
        let polarNight = noSunEvents && !polarDay

        var fajrRaw = solve(altitude: -method.fajrAngle, morning: true, seed: noonMinutes - 420)
        var ishaRaw: Double?
        switch method.ishaRule {
        case .depression(let angle):
            ishaRaw = solve(altitude: -angle, morning: false, seed: noonMinutes + 420)
        case .interval(let normal, let ramadan):
            let interval = SLHijri.isRamadan(on: dayStart, timeZoneID: place.timeZoneID) ? ramadan : normal
            // Measured from the Maghrib the app actually prints, which carries the same
            // one-minute margin as every printed timetable. Measuring from bare sunset
            // instead would make the published "ninety minutes after Maghrib" come out as
            // eighty-nine on screen.
            ishaRaw = sunsetRaw.map { $0 + maghribMargin + interval }
        }

        var asrRaw: Double? = nil
        if let asrAltitude = SLSolar.asrAltitude(factor: config.asrSchool.shadowFactor,
                                                 latitude: latitude,
                                                 declination: noonPosition.declination) {
            asrRaw = solve(altitude: asrAltitude, morning: false, seed: noonMinutes + 180)
        }

        var adjusted = [Bool](repeating: false, count: SLPrayer.allCases.count)

        // High-latitude fallbacks. They divide the NIGHT, so they are only meaningful when
        // there is a night to divide: on a true polar day or polar night there is no
        // sunset-to-sunrise interval and the honest answer is no answer at all.
        if let sunrise = sunriseRaw, let sunset = sunsetRaw, config.highLatRule != .none {
            let nightLength = (sunrise + 1440.0) - sunset      // sunset today to sunrise tomorrow
            if nightLength.isFinite, nightLength > 0, nightLength < 1440 {
                let fajrPortion = portion(of: nightLength, angle: method.fajrAngle, rule: config.highLatRule)
                if fajrRaw == nil || (sunrise - (fajrRaw ?? 0)) > fajrPortion {
                    fajrRaw = sunrise - fajrPortion
                    adjusted[SLPrayer.fajr.rawValue] = true
                }
                if case .depression(let ishaAngle) = method.ishaRule {
                    let ishaPortion = portion(of: nightLength, angle: ishaAngle, rule: config.highLatRule)
                    if ishaRaw == nil || ((ishaRaw ?? 0) - sunset) > ishaPortion {
                        ishaRaw = sunset + ishaPortion
                        adjusted[SLPrayer.isha.rawValue] = true
                    }
                }
            }
        }

        var values: [Double?] = [
            fajrRaw,
            noonMinutes + noonMargin,
            asrRaw,
            sunsetRaw.map { $0 + maghribMargin },
            ishaRaw
        ]

        for p in SLPrayer.allCases {
            let i = p.rawValue
            if let v = values[i] { values[i] = v + config.offset(p) }
        }

        return SLDayTimes(dayStart: dayStart,
                          timeZoneID: place.timeZoneID,
                          minutes: values,
                          sunriseMinutes: sunriseRaw,
                          solarNoonMinutes: noonMinutes,
                          adjusted: adjusted,
                          polarDay: polarDay,
                          polarNight: polarNight,
                          declination: noonPosition.declination,
                          equationOfTime: noonPosition.equationOfTime)
    }

    private static func portion(of nightLength: Double, angle: Double, rule: SLHighLatRule) -> Double {
        switch rule {
        case .none, .middleOfNight: return nightLength / 2.0
        case .seventhOfNight: return nightLength / 7.0
        case .angleBased: return nightLength * (angle / 60.0)
        }
    }
}

// MARK: - A day resolved to absolute instants, with its neighbours

/// Everything a screen needs about one prayer on one day: when it starts, when its window
/// closes, and whether it could be computed at all.
struct SLWindow: Identifiable {
    let prayer: SLPrayer
    let start: Date?
    /// The next boundary. Isha's end is the FOLLOWING day's Fajr, which is why the
    /// schedule always computes the neighbouring days as well.
    let end: Date?
    let adjusted: Bool

    var id: Int { prayer.rawValue }
    var isComputed: Bool { start != nil }

    func contains(_ date: Date) -> Bool {
        guard let s = start else { return false }
        guard let e = end else { return date >= s }
        return date >= s && date < e
    }

    func elapsedFraction(at date: Date) -> Double {
        guard let s = start, let e = end else { return 0 }
        let span = e.timeIntervalSince(s)
        guard span > 0 else { return 0 }
        return max(0, min(1, date.timeIntervalSince(s) / span))
    }
}

struct SLSchedule {
    let place: SLPlace
    let config: SLEngineConfig
    /// The civil day the windows below belong to.
    let dayStart: Date
    let today: SLDayTimes
    let tomorrow: SLDayTimes
    let yesterday: SLDayTimes
    let windows: [SLWindow]

    func window(for prayer: SLPrayer) -> SLWindow {
        windows.first { $0.prayer == prayer }
            ?? SLWindow(prayer: prayer, start: nil, end: nil, adjusted: false)
    }

    var sunrise: Date? { today.sunriseDate }
    var hasPolarGap: Bool { today.polarDay || today.polarNight || windows.contains { !$0.isComputed } }

    /// Why a prayer has no computed time, in words rather than as a bare dash.
    func absenceReason(for prayer: SLPrayer) -> String {
        if today.polarDay {
            return "The sun does not set here on this date, so there is no time to compute."
        }
        if today.polarNight {
            return "The sun does not rise here on this date, so there is no time to compute."
        }
        return "The sun does not fall to this twilight angle here on this date."
    }

    /// The banner shown above the cards whenever the day has a gap in it.
    var polarNote: String? {
        if today.polarDay {
            return "The sun does not set in \(placeNameHint) on this date. Sunrise, Maghrib and any time that depends on twilight cannot be computed, and are shown as a dash rather than as a guess. Communities at this latitude generally follow the timetable of the nearest city where the twilight still occurs, or that of Makkah."
        }
        if today.polarNight {
            return "The sun does not rise in \(placeNameHint) on this date. Sunrise and Maghrib cannot be computed and are shown as a dash. Communities at this latitude generally follow the timetable of the nearest city where the sun still rises, or that of Makkah."
        }
        if windows.contains(where: { !$0.isComputed }) {
            return "On this date the sun does not fall far enough below the horizon here for every twilight angle to be reached. The prayers that cannot be computed show a dash. Choosing a high-latitude rule in Settings fills them in from a division of the night instead."
        }
        return nil
    }

    private var placeNameHint: String {
        String(format: "this location (%.1f\u{00B0} latitude)", place.latitude)
    }

    /// The prayer whose window `now` currently sits inside, if any.
    func active(at now: Date) -> SLPrayer? {
        windows.first { $0.contains(now) }?.prayer
    }

    /// The next prayer to begin, looking into tomorrow when today is spent.
    func next(after now: Date) -> (prayer: SLPrayer, date: Date)? {
        var candidates: [(SLPrayer, Date)] = today.resolved.map { ($0.prayer, $0.date) }
        candidates.append(contentsOf: tomorrow.resolved.map { ($0.prayer, $0.date) })
        return candidates.sorted { $0.1 < $1.1 }.first { $0.1 > now }.map { (prayer: $0.0, date: $0.1) }
    }
}

extension SLPrayerEngine {

    /// Builds a day's windows, with the neighbouring days computed so Isha can close on
    /// the following Fajr and so a time just after midnight resolves to the right day.
    static func schedule(for day: Date, place: SLPlace, config: SLEngineConfig) -> SLSchedule {
        let cal = place.calendar()
        let dayStart = cal.startOfDay(for: day)
        let previousDay = cal.date(byAdding: .day, value: -1, to: dayStart) ?? dayStart.addingTimeInterval(-86400)
        let nextDay = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86400)

        let today = times(on: dayStart, place: place, config: config)
        let tomorrow = times(on: nextDay, place: place, config: config)
        let yesterday = times(on: previousDay, place: place, config: config)

        // Absolute instants, then a monotonic pass. The pass exists for the two days a
        // year a zone shifts: a wall-clock time inside a spring-forward gap does not
        // exist, `Calendar` resolves it to the first valid instant after the gap, and two
        // prayers can land on the same minute. Nudging the later one keeps every window
        // at least a minute long so no screen ever shows a window that ends before it
        // begins, and no progress bar divides by zero.
        var starts: [Date?] = SLPrayer.allCases.map { today.date(for: $0) }
        for i in 1..<starts.count {
            guard let previous = starts[i - 1], let current = starts[i] else { continue }
            if current <= previous { starts[i] = previous.addingTimeInterval(60) }
        }

        // Isha's window closes on tomorrow's Fajr, so it legitimately crosses midnight.
        let tomorrowFajr = tomorrow.date(for: .fajr)
            ?? tomorrow.sunriseDate
            ?? cal.date(byAdding: .day, value: 1, to: dayStart)

        var windows: [SLWindow] = []
        for prayer in SLPrayer.allCases {
            let i = prayer.rawValue
            let start = starts[i]
            let end: Date?
            switch prayer {
            case .fajr:
                // Fajr closes at sunrise, not at Dhuhr.
                end = today.sunriseDate ?? starts[SLPrayer.dhuhr.rawValue]
            case .isha:
                end = tomorrowFajr
            default:
                end = starts[i + 1]
            }
            // Never hand a window whose end precedes its start to the interface.
            let safeEnd: Date? = {
                guard let s = start, let e = end else { return end }
                return e > s ? e : s.addingTimeInterval(60)
            }()
            windows.append(SLWindow(prayer: prayer,
                                    start: start,
                                    end: safeEnd,
                                    adjusted: today.wasAdjusted(prayer)))
        }

        return SLSchedule(place: place,
                          config: config,
                          dayStart: dayStart,
                          today: today,
                          tomorrow: tomorrow,
                          yesterday: yesterday,
                          windows: windows)
    }

    /// Which record day `now` belongs to.
    ///
    /// The logging day turns over at Fajr, not at midnight. Isha's window runs until the
    /// following dawn, so a prayer marked at 00:40 belongs to the day that has just ended
    /// on the clock — otherwise a late Isha would be filed against a day that has not
    /// started yet and both days would read as broken.
    static func recordDay(for now: Date, place: SLPlace, config: SLEngineConfig) -> Date {
        let cal = place.calendar()
        let civilDay = cal.startOfDay(for: now)
        let todayTimes = times(on: civilDay, place: place, config: config)
        let dawn = todayTimes.date(for: .fajr) ?? todayTimes.sunriseDate
        if let dawn = dawn, now < dawn {
            return cal.date(byAdding: .day, value: -1, to: civilDay) ?? civilDay
        }
        return civilDay
    }
}

// MARK: - Hijri date

enum SLHijri {

    private static func calendar(_ timeZoneID: String) -> Calendar {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.timeZone = SLZone.resolve(timeZoneID)
        return cal
    }

    static let monthNames = ["Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
                             "Jumada al-Ula", "Jumada al-Akhirah", "Rajab", "Sha'ban",
                             "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]

    /// Day, month index (1-12) and year in the Umm al-Qura reckoning.
    static func components(for date: Date, timeZoneID: String) -> (day: Int, month: Int, year: Int) {
        let parts = calendar(timeZoneID).dateComponents([.day, .month, .year], from: date)
        return (parts.day ?? 1, parts.month ?? 1, parts.year ?? 1447)
    }

    static func text(for date: Date, timeZoneID: String) -> String {
        let c = components(for: date, timeZoneID: timeZoneID)
        let name = (c.month >= 1 && c.month <= 12) ? monthNames[c.month - 1] : "—"
        return "\(c.day) \(name) \(c.year) AH"
    }

    static func isRamadan(on date: Date, timeZoneID: String) -> Bool {
        components(for: date, timeZoneID: timeZoneID).month == 9
    }
}

// MARK: - Formatting

enum SLTimeFormat {

    /// Formats an absolute instant in the place's own zone, never the device's.
    static func clock(_ date: Date?, style: SLClockStyle, timeZoneID: String) -> String {
        guard let date = date else { return "—" }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = SLZone.resolve(timeZoneID)
        let parts = cal.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        switch style {
        case .twentyFourHour:
            return String(format: "%02d:%02d", hour, minute)
        case .twelveHour:
            let suffix = hour < 12 ? "AM" : "PM"
            var h = hour % 12
            if h == 0 { h = 12 }
            return String(format: "%d:%02d %@", h, minute, suffix)
        }
    }

    /// "2h 14m" / "38m" / "in a moment". Never negative.
    static func duration(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "under a minute"
    }

    private static let monthNames = ["January", "February", "March", "April", "May", "June",
                                     "July", "August", "September", "October", "November", "December"]
    private static let monthShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private static let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday",
                                       "Thursday", "Friday", "Saturday"]
    private static let weekdayShort = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private static func parts(_ date: Date, _ timeZoneID: String) -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = SLZone.resolve(timeZoneID)
        return cal.dateComponents([.year, .month, .day, .weekday], from: date)
    }

    /// Names are held as literal English tables rather than pulled from a `DateFormatter`:
    /// the app ships in English (US) only, and a formatter would otherwise follow whatever
    /// language the device is set to and mix two languages on one screen.
    static func longDate(_ date: Date, timeZoneID: String) -> String {
        let c = parts(date, timeZoneID)
        let weekday = weekdayNames[max(0, min(6, (c.weekday ?? 1) - 1))]
        let month = monthNames[max(0, min(11, (c.month ?? 1) - 1))]
        return "\(weekday), \(c.day ?? 1) \(month) \(c.year ?? 2000)"
    }

    static func mediumDate(_ date: Date, timeZoneID: String) -> String {
        let c = parts(date, timeZoneID)
        let weekday = weekdayShort[max(0, min(6, (c.weekday ?? 1) - 1))]
        let month = monthShort[max(0, min(11, (c.month ?? 1) - 1))]
        return "\(weekday) \(c.day ?? 1) \(month) \(c.year ?? 2000)"
    }

    static func shortDate(_ date: Date, timeZoneID: String) -> String {
        let c = parts(date, timeZoneID)
        let month = monthShort[max(0, min(11, (c.month ?? 1) - 1))]
        return "\(c.day ?? 1) \(month)"
    }

    static func monthTitle(_ date: Date, timeZoneID: String) -> String {
        let c = parts(date, timeZoneID)
        let month = monthNames[max(0, min(11, (c.month ?? 1) - 1))]
        return "\(month) \(c.year ?? 2000)"
    }

    /// Stable key for a record day: the civil date in the place's zone. Built from
    /// components so it stays cheap enough to call once per cell of a year-long chart.
    static func dayKey(_ date: Date, timeZoneID: String) -> String {
        let c = parts(date, timeZoneID)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    /// 1 = Sunday, matching `Calendar`.
    static func weekday(_ date: Date, timeZoneID: String) -> Int {
        parts(date, timeZoneID).weekday ?? 1
    }

    static func isFriday(_ date: Date, timeZoneID: String) -> Bool {
        weekday(date, timeZoneID: timeZoneID) == 6
    }
}
